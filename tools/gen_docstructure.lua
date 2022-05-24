
package.path = package.path..";../lua/?.lua;../lua/?/init.lua;lua/?.lua;lua/?/init.lua"

local lfsampler = require "lfsampler"
local ProfilerResults = require "lfsampler.ProfilerResults"
local formatters = require "lfsampler.formatters"

local res = { }
local function formatDoc(name, t)
	local acc = { }
	for k in pairs(t) do
		acc[#acc+1] = ("%s.%s():"):format(name, k)
	end
	table.sort(acc)
	for _, val in ipairs(acc) do
		res[#res+1] = val
	end
end

formatDoc("lfsampler", lfsampler)
formatDoc("formatters", formatters)
formatDoc("ProfilerResults", ProfilerResults)

print(table.concat(res, "\n"))
