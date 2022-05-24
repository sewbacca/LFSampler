
local serialization = require "lightserialization"

package.path = "../../lua/?.lua;../../lua/?/init.lua;"..package.path

local lfsampler = require "lfsampler"
local formatters = require "lfsampler.formatters"
local prime = require "prime"

local function writeFile(path, data)
	local file = io.open(path, "w")
	if not file then
		error("Couldn't open file", 2)
		return
	end
	file:write(data)
	file:close()
end

local function perf(name, func)
	lfsampler.start()
	func()
	lfsampler.stop()
	local traces = lfsampler.popStacktraces()
	-- print(serialization.serialize(traces))
	writeFile("graph-"..name.."-line.cap", formatters.flamegraph(traces, "graph", "line"))
	writeFile("graph-"..name.."-func.cap", formatters.flamegraph(traces, "graph", "func"))
	writeFile("chart-"..name.."-line.cap", formatters.flamegraph(traces, "chart", "line"))
	writeFile("chart-"..name.."-func.cap", formatters.flamegraph(traces, "chart", "func"))
end

local function run_for(func, n)
	local results = { }
	for i = 1, n do
		results[i] = func(i)
	end
	return results
end

local n = tonumber((...)) or 2000

if pcall(lfsampler.setProfiler, "jit") then
	perf("is_prime-jit", function ()
		print(run_for(prime.is_prime_v1, n))
		print(run_for(prime.is_prime_v2, n))
	end)
end
-- lfsampler.setProfiler "debug"
-- perf("is_prime-debug", function ()
-- 	run_for(prime.is_prime_v1, n)
-- 	run_for(prime.is_prime_v2, n)
-- end)
