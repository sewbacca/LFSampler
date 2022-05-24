

---@class lfsampler.formatters
local formatters = { }

---@param stacktrace lfsampler.Stacktrace
local function granularityFunc(stacktrace)
	local hash = { }
	for i = 1, #stacktrace do
		hash[i] = stacktrace[i].file.."-"..stacktrace[i].func
	end
	return table.concat(hash, ";")
end

---@param stacktrace lfsampler.Stacktrace
local function granularityLine(stacktrace)
	local hash = { }
	for i = 1, #stacktrace do
		hash[i] = stacktrace[i].file..":"..stacktrace[i].line.."-"..stacktrace[i].func
	end
	return table.concat(hash, ";")
end


--- Formats stacktraces according to
---@param stacktraces lfsampler.Stacktraces
---@param type "graph" | "chart"
---@param granularity "func" | "line"
---@return string
function formatters.flamegraph(stacktraces, type, granularity)
	local formatStacktrace = granularity == "func" and granularityFunc or granularityLine
	local accumulated = type == "graph" and stacktraces:accumulate(formatStacktrace) or stacktraces:squash(formatStacktrace)

	local results = { }

	for _, probe in ipairs(accumulated.probes) do
		results[#results+1] = formatStacktrace(probe.stacktrace).." "..probe.samples
	end

	return table.concat(results, "\n")
end

--- Returns completly annotated source code foreach module
---@param stacktraces lfsampler.Stacktraces
---@param path string? @ defaults to package.path
---@return table<string, string> @ { [module]: annotations }
function formatters.annotate(stacktraces, path)

end

return formatters
