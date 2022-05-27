
local ProfilerResults = require "lfsampler.ProfilerResults"

---@class lfsampler.profiler
local jitprofiler = { }

local jp = require "jit.profile"
local vmdef   = require "jit.vmdef"

require "table.clear"

local clear = table.clear
local clock = os and os.clock or function() return 0 end
local dumpstack, ffnames, tonumber = jp.dumpstack, vmdef.ffnames, tonumber
local start, stop = jp.start, jp.stop

local fmt = "li10"

local starttime = 0
local duration = 0

local probes = { }

local function get_c_name(n)
	return ffnames[tonumber(n)]
end

local function prof_cb(thread, samples, _)
	probes[#probes+1] = dumpstack(thread, "pl|f;", -100)
	probes[#probes+1] = samples
end

function jitprofiler.start()
	jitprofiler.running = true
	starttime = clock()
	start(fmt, prof_cb)
end

function jitprofiler.setup(n)
	fmt = n and "li"..math.floor(tonumber(n) + 0.5) or fmt
end

function jitprofiler.finish()
	stop()
	jitprofiler.running = false
	duration = duration + clock() - starttime
end

---@return lfsampler.ProfilerResults
function jitprofiler.getResults()
	local results = ProfilerResults:new()

	for i = 1, #probes, 2 do
		local stacktrace_encoded = probes[i]
		local samples = probes[i + 1]

		local stacktrace = { }
		for location in stacktrace_encoded:gmatch "[^;]+" do
			local mod, func = location:match "^([^|]+)|(.+)$"
			local file, line = mod:match "^(.+):([^:]+)$"
			if not file then
				file, line = mod:gsub("%[builtin#(%d+)%]", get_c_name), -1
			else
				line = tonumber(line) or -1
			end

			func = func:gsub("%[builtin#(%d+)%]", get_c_name)

			stacktrace[#stacktrace+1] = {
				file = file,
				line = tonumber(line),
				func = func,
				raw = location
			}
		end
		results:_addStacktrace(stacktrace, samples)
	end

	results.duration = duration
	results:_calcRate()

	return results
end

function jitprofiler.discard()
	clear(probes)
end

return jitprofiler
