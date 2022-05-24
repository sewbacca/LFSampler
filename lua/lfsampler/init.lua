
---@alias lfsampler.ProfilerType "jit" | "debug" | "dummy"

local debugprofiler, jitprofiler

if debug then
	debugprofiler = require "lfsampler.debugProfiler"
end if jit and jit.version_num >= 20100 then
	jitprofiler = require "lfsampler.jitProfiler"
end

local dummy = function() end
local dummyprofiler = setmetatable({}, { __index = function (_, k)
	if k == "running" then
		return false
	end
	return dummy
end})

local profiler = jitprofiler or debugprofiler or dummyprofiler

---@class lfsampler
local m = { }

--- Sets profiling type
---@param profiler_type lfsampler.ProfilerType
function m.setProfiler(profiler_type, n)
	if profiler.running then
		profiler.finish()
		profiler.discard()
	end

	profiler = nil
	if profiler_type == "jit" then
		profiler = jitprofiler
	elseif profiler_type == "debug" then
		profiler = debugprofiler
	elseif profiler_type == "dummy" then
		profiler = dummyprofiler
	end

	if not profiler then
		profiler = dummyprofiler
		error(profiler_type.." profiler couldn't be loaded", 2)
		return
	end

	profiler.setup(n)
end

--- Retrieves current selected profiler
---@return lfsampler.ProfilerType
function m.currentProfiler()
	return profiler == jitprofiler and "jit" or profiler == debugprofiler and "debug" or "dummy"
end

--- Checks whether an profiler is available
---@return boolean
function m.anyAvailable()
	return not not (jitprofiler or debugprofiler)
end

--- Returns wether or not jit is available
---@return boolean
function m.isJitAvailable()
	return not not jitprofiler
end

--- Starts the session
function m.start()
	profiler.start()
end

--- Stops the session
function m.stop()
	profiler.finish()
end

--- Returns current results
function m.getResults()
	return profiler.getResults()
end

--- Discards current results. If they are not discarded, any subsequent sessions, will accumulate
function m.discard()
	profiler.discard()
end

--- Returns results and then discards them. Use this if you want to have seperate session results.
function m.popResults()
	local traces = m.getResults()
	m.discard()
	return traces
end

function m.isRunning()
	return profiler.running
end

return m
