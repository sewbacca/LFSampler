
---@diagnostic disable: redefined-local

---@class lfsampler.Stacktraces
local Stacktraces = { } do
	Stacktraces.__index = Stacktraces

	--- Creates a unique hash for a given position
	---@param stacktrace lfsampler.Stacktrace
	---@return string
	local function stronghash(stacktrace)
		local result = { }
		for i, location in ipairs(stacktrace) do
			result[i] = location.file..location.line..location.func
		end
		return table.concat(result, "")
	end

	function Stacktraces:new()
		---@class lfsampler.Stacktraces
		local self = setmetatable({}, self)

		---@type lfsampler.Probe[]
		self.probes = { }
		self.totalSamples = 0

		return self
	end

	--- Adds a stacktrace n times
	---@param stacktrace lfsampler.Stacktrace
	---@param samples integer
	function Stacktraces:_addStacktrace(stacktrace, samples)
		---@class lfsampler.Location
		---@field file string
		---@field line number
		---@field func string

		---@class lfsampler.Probe
		---@field stacktrace lfsampler.Stacktrace
		---@field samples integer

		---@alias lfsampler.Stacktrace lfsampler.Location[]

		local last = self.probes[#self.probes]

		if last and stronghash(last.stacktrace) == stronghash(stacktrace) then
			self.probes[#self.probes].samples = last.samples + samples
		else
			self.probes[#self.probes+1] = {
				stacktrace = stacktrace,
				samples = samples
			}
		end

		self.totalSamples = self.totalSamples + samples
	end

	function Stacktraces:accumulate(hash)
		hash = hash or stronghash

		local acc = { }

		---@class lfsampler.Results
		local results = {
			probes = { },
			totalSamples = 0
		}
		for _, probe in ipairs(self.probes) do
			local h = hash(probe.stacktrace)
			if h then
				local accsample = acc[h]
				if not accsample then
					accsample = {
						stacktrace = probe.stacktrace,
						samples = 0
					}
					results.probes[#results.probes+1] = accsample
					acc[h] = accsample
				end
				accsample.samples = accsample.samples + probe.samples
				results.totalSamples = results.totalSamples + probe.samples
			end
		end

		return results
	end

	function Stacktraces:squash(hash)
		hash = hash or stronghash

		---@class lfsampler.Results
		local results = {
			---@type lfsampler.Probe[]
			probes = { },
			totalSamples = 0
		}

		for _, probe in ipairs(self.probes) do
			local h = hash(probe.stacktrace)
			if h then
				local accsample = results.probes[#results.probes]
				if not accsample or hash(accsample.stacktrace) ~= hash(probe.stacktrace) then
					accsample = {
						stacktrace = probe.stacktrace,
						samples = 0
					}
					results.probes[#results.probes+1] = accsample
				end
				accsample.samples = accsample.samples + probe.samples
				results.totalSamples = results.totalSamples + probe.samples
			end
		end

		return results
	end
end

---@type lfsampler.profiler
local profiler


local function clear(t)
	for i = #t, 1, -1 do
		t[i] = nil
	end
end

local new = table.new

if jit then
	require "table.clear"
	require "table.new"

	clear = table.clear
	new = table.new
end

---@class lfsampler.profiler
local debugprofiler, jitprofiler
if debug then
	debugprofiler = { usesjit = false }

	local sethook = debug.sethook
	local getinfo = debug.getinfo

	local samples = { }

	local function prof_cb()
		local trace = new and new(5, 0) or { }
		samples[#samples+1] = trace

		local depth = 2
		repeat
			local info = getinfo(depth, "Snl")
			trace[#trace+1] = info
			depth = depth + 1
		until not info
	end

	function debugprofiler.start()
		sethook(prof_cb, "", 50)
	end

	function debugprofiler.finish()
		sethook()
	end

	---@return lfsampler.Stacktraces
	function debugprofiler.getStacktraces()
		local stacktraces = Stacktraces:new()
		for i, traceback in ipairs(samples) do
			local trace = { }
			for i = #traceback, 1, -1 do
				local location = traceback[i]
				local name = location.name

				if not name then
					name = "[C]"
				else
					name = ("<%s:%d>"):format(name, location.linedefined)
				end
				trace[#trace+1] = {
					file = location.source:sub(2),
					line = location.currentline,
					func = name,
					raw = location
				}
			end
			stacktraces:_addStacktrace(trace, 1)
		end

		return stacktraces
	end

	function debugprofiler.discard()
		clear(samples)
	end
end if jit and jit.version_num >= 20100 then
	jitprofiler = { usesjit = true }

	local jp = require "jit.profile"
	local vmdef   = require "jit.vmdef"

	local dumpstack, ffnames, tonumber, gsub = jp.dumpstack, vmdef.ffnames, tonumber, string.gsub
	local start, stop = jp.start, jp.stop

	local probes = { }

	local function get_c_name(n)
		return ffnames[tonumber(n)]
	end

	local function prof_cb(thread, samples, _)
		probes[#probes+1] = dumpstack(thread, "pl-f;", -100)
		probes[#probes+1] = samples
	end

	function jitprofiler.start()
		jitprofiler.running = true
		start("li10", prof_cb)
	end

	function jitprofiler.finish()
		stop()
		jitprofiler.running = false
	end

	---@return lfsampler.Stacktraces
	function jitprofiler.getStacktraces()
		local stacktraces = Stacktraces:new()

		print(#probes)
		for i = 1, #probes, 2 do
			local stacktrace_encoded = probes[i]
			local samples = probes[i + 1]

			local stacktrace = { }
			for location in stacktrace_encoded:gmatch "[^;]+" do
				local file, line, func = location:match("^([^:]+):(%d+)-(.*)$")
				file = file or location:match("^[^-]+")
				line = line or -1
				func = func or location:match("[^-]+$")

				func = func:gsub("%[builtin#(%d+)%]", get_c_name)

				stacktrace[#stacktrace+1] = {
					file = file,
					line = tonumber(line),
					func = func,
					raw = location
				}
			end
			stacktraces:_addStacktrace(stacktrace, samples)
		end

		return stacktraces
	end

	function jitprofiler.discard()
		clear(probes)
	end

	profiler = jitprofiler
else
	profiler = debugprofiler
end


---@class lfsampler
local m = { }

--- Sets profiling type
---@param profiler_type "jit" | "debug"
function m.setProfiler(profiler_type)
	if profiler.running then
		profiler.finish()
		profiler.discard()
	end

	if profiler_type == "jit" then
		if not jitprofiler then
			error("Jit profiler couldn't be loaded")
		end
		profiler = jitprofiler
	else
		profiler = debugprofiler
	end
end

function m.getProfilerType()
	return profiler == jitprofiler and "jit" or debugprofiler and "debug" or nil
end

function m.anyProfilerLoaded()
	return not not (jitprofiler or debugprofiler)
end

function m.isJitAvailable()
	return not not jitprofiler
end

function m.start()
	profiler.start()
end

function m.stop()
	profiler.finish()
end

function m.getStacktraces()
	return profiler.getStacktraces()
end

function m.discard()
	profiler.discard()
end

function m.popStacktraces()
	local traces = m.getStacktraces()
	m.discard()
	return traces
end

function m.isRunning()
	return profiler.running
end

return m
