

---@class lfsampler.formatters
local formatters = { }

---@param stacktrace lfsampler.Stacktrace
function formatters.granularityFunc(stacktrace)
	local hash = { }
	for i = 1, #stacktrace do
		hash[i] = stacktrace[i].file.."-"..stacktrace[i].func
	end
	return table.concat(hash, ";")
end

---@param stacktrace lfsampler.Stacktrace
function formatters.granularityLine(stacktrace)
	local hash = { }
	for i = 1, #stacktrace do
		hash[i] = stacktrace[i].file..":"..stacktrace[i].line.."-"..stacktrace[i].func
	end
	return table.concat(hash, ";")
end

function formatters.sortBySampleCount(a, b)
	return a.sampleCount > b.sampleCount
end

local sep_size = 20 + 3 + 20 + 3 + 8 + 3 + 11 + 3 + 7 + 1
local seperator = ("-"):rep(sep_size)
local seperatorEq = ("="):rep(sep_size)
local report_fmt = [[
LFSample Profiler Report
]]..seperatorEq..[[


On CPU:
%s
%s
%s

]]..seperatorEq..[[


Overall:
%s
%s
%s
%s
%s
]]

local report_header = ("%20s | %20s | %8s | %11s | %7s"):format("File", "Func", "Usage", "Duration", "Samples")
local report_line = "%20s | %20s | %6.2f %% | %8d ms | %d"
local report_line_last = "%20s | %20s | 100.00 %% | %9.3f s | %d"

---@param results lfsampler.ProfilerResults
function formatters.formatReport(results)
	local function hashSingle(loc)
		return loc.file..loc.func
	end

	local cpu = results:accumulate(function (st)
		return hashSingle(st[#st])
	end)

	local cpu_body = { }
	table.sort(cpu.probes, formatters.sortBySampleCount)
	for _, probe in ipairs(cpu.probes) do
		local loc = probe.stacktrace[#probe.stacktrace]
		cpu_body[#cpu_body+1] = report_line:format(loc.file, loc.func, 100 * probe.sampleCount / cpu.totalSamples, probe.sampleCount * results.actualRate, probe.sampleCount)
	end
	cpu_body[#cpu_body+1] = seperator
	cpu_body[#cpu_body+1] = report_line_last:format("on cpu", "*", cpu.totalSamples * results.actualRate / 1000, cpu.totalSamples)

	local overallAcc = results:accumulate(formatters.granularityFunc)

	local overallResults = { }
	local totalOverall = 0

	for _, probe in ipairs(overallAcc.probes) do
		for _, loc in ipairs(probe.stacktrace) do
			local hash = hashSingle(loc)
			overallResults[hash] = overallResults[hash] or { sampleCount = 0, location = loc }
			overallResults[hash].sampleCount = overallResults[hash].sampleCount + probe.sampleCount
			totalOverall = totalOverall + probe.sampleCount
		end
	end

	local overallResultsArray = {}
	for _, probe in pairs(overallResults) do
		overallResultsArray[#overallResultsArray+1] = probe
	end

	table.sort(overallResultsArray, formatters.sortBySampleCount)

	local overall_body = { }

	for _, probe in ipairs(overallResultsArray) do
		local loc = probe.location
		overall_body[#overall_body+1] = report_line:format(loc.file, loc.func, 100 * probe.sampleCount / totalOverall, probe.sampleCount * results.actualRate, probe.sampleCount)
	end

	return report_fmt:format(
		report_header,
		seperator,
		table.concat(cpu_body, "\n"),
		report_header,
		seperator,
		table.concat(overall_body, "\n"),
		seperator,
		report_line_last:format("all", "any", results.duration, results.totalSamples)
	)
end

--- Formats results according to [FlameGraph](https://github.com/brendangregg/FlameGraph/blob/master/flamegraph.pl)
--- Format: `<file>(:<line>)?-<func>;... <samples>\n...`
---@param results lfsampler.ProfilerResults
---@param type "graph" | "chart"
---@param granularityFormatter fun(stacktrace: lfsampler.Stacktrace)
---@return string
function formatters.flamegraph(results, type, granularityFormatter)
	local accumulated = type == "graph" and results:accumulate(granularityFormatter) or results:squash(granularityFormatter)

	local samples = { }

	for _, probe in ipairs(accumulated.probes) do
		samples[#samples+1] = granularityFormatter(probe.stacktrace).." "..probe.sampleCount
	end

	return table.concat(samples, "\n")
end

local line_fmt_tracked = "%6.2f %% | %s"
local line_fmt_untracked = "         | %s"

--- Returns completly annotated source code foreach module
---@param results lfsampler.ProfilerResults
---@return table<string, string> @ { [path]: annotations }
function formatters.annotateSource(results)
	local files = { }

	local function exists(path)
		local file = io.open(path)
		if file then
			file:close()
			return true
		end
		return false
	end

	local function get_lines(path)
		if files[path] ~= nil then
			return files[path]
		end

		if exists(path) then
			local lines = { }


			for line in io.lines(path) do
				lines[#lines+1] = {
					text = line,
					tracked = 0
				}
			end

			files[path] = lines
			return lines
		end
	end

	for _, probe in ipairs(results.probes) do
		for _, location in ipairs(probe.stacktrace) do
			local lines = get_lines(location.file)

			if lines then
				lines[location.line].tracked = lines[location.line].tracked + probe.sampleCount
			end
		end
	end

	local result = { }

	for path, lines in pairs(files) do
		local formatted = { }

		for _, line in ipairs(lines) do
			if line.tracked > 0 then
				formatted[#formatted+1] = line_fmt_tracked:format(100 * line.tracked / results.totalSamples, line.text)
			else
				formatted[#formatted+1] = line_fmt_untracked:format(line.text)
			end
		end

		result[path] = table.concat(formatted, "\n")
	end

	return result
end

return formatters
