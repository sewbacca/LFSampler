
package.path = "../lua/?.lua;../lua/?/init.lua;"..package.path

local mod = require "weirdness"
local lfsampler= require "lfsampler"
local formatters = require "lfsampler.formatters"

lfsampler.setProfiler("debug", 7)
lfsampler.start()
mod.root()
lfsampler.stop()

local results = lfsampler.popResults()

print(formatters.formatReport(results))

do
	local file = io.open("output.cap", "w")
	if file then
		file:write(formatters.flamegraph(results, "graph", formatters.granularityFunc))
		file:close()
	end
end

for name, data in pairs(formatters.annotateSource(results)) do
	local file = io.open("annotated/"..name:gsub("%.lua", ".tlua"):gsub("/", "."), "w")
	if file then
		file:write(data)
		file:close()
	end
end
