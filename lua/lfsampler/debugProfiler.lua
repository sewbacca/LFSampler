
local ProfilerResults = require "lfsampler.ProfilerResults"

--- #internal
---@class lfsampler.profiler
local debugprofiler = { }

local clock = os and os.clock or function() return 0 end
local sethook = debug.sethook
local getinfo = debug.getinfo

if jit then
	require "table.new"
	require "table.clear"
end

---@diagnostic disable-next-line: undefined-field
local new = table.new
---@diagnostic disable-next-line: undefined-field
local clear = table.clear or function (t)
	for i = #t, 1, -1 do
		t[i] = nil
	end
end

local samples = { }
local duration = 0
local count = 15

local starttime = 0

local function prof_cb()
	local trace = new and new(16, 0) or { }
	samples[#samples+1] = trace

	local depth = 2
	repeat
		local info = getinfo(depth, "Snl")
		trace[#trace+1] = info
		depth = depth + 1
	until not info
end

function debugprofiler.setup(n)
	count = n or count
end

function debugprofiler.start()
	starttime = clock()
	debugprofiler.running = true
	sethook(prof_cb, "", count)
end

function debugprofiler.finish()
	sethook()
	debugprofiler.running = false
	duration = duration + (clock() - starttime)
end

---@return lfsampler.ProfilerResults
function debugprofiler.getResults()
	local results = ProfilerResults:new()
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
		results:_addStacktrace(trace, 1)
	end

	results.duration = duration
	results:_calcRate()

	return results
end

function debugprofiler.discard()
	clear(samples)
	duration = 0
end

return debugprofiler
