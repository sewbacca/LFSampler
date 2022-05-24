
---@class lfsampler.ProfilerResults
local ProfilerResults = { }
ProfilerResults.__index = ProfilerResults

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

function ProfilerResults:new()
	---@class lfsampler.ProfilerResults
	local this = setmetatable({}, self)

	---@type lfsampler.Probe[]
	this.probes = { }
	--- Total sample count
	this.totalSamples = 0
	--- Accumulated duration
	this.duration = 0

	return this
end

--- Adds a stacktrace n times
---@param stacktrace lfsampler.Stacktrace
---@param samples integer
function ProfilerResults:_addStacktrace(stacktrace, samples)
	---@class lfsampler.Location
	---@field file string
	---@field line number
	---@field func string

	---@class lfsampler.Probe
	---@field stacktrace lfsampler.Stacktrace
	---@field sampleCount integer

	---@alias lfsampler.Stacktrace lfsampler.Location[]

	local last = self.probes[#self.probes]

	if last and stronghash(last.stacktrace) == stronghash(stacktrace) then
		self.probes[#self.probes].sampleCount = last.sampleCount + samples
	else
		self.probes[#self.probes+1] = {
			stacktrace = stacktrace,
			sampleCount = samples
		}
	end

	self.totalSamples = self.totalSamples + samples
end

function ProfilerResults:_calcRate()
	--- Rate in millisecond per sample
	self.actualRate = 1000 * self.duration / self.totalSamples
end

--- Accumulates all stacktraces collapsed by given hash function
---@param hash fun(stacktrace: lfsampler.Stacktrace)
---@return lfsampler.AccumulatedResults
function ProfilerResults:accumulate(hash)
	hash = hash or stronghash

	local acc = { }

	---@class lfsampler.AccumulatedResults
	local results = {
		---@type lfsampler.AccumulatedProbe[]
		probes = { },
		totalSamples = 0
	}
	for _, probe in ipairs(self.probes) do
		local h = hash(probe.stacktrace)
		if h then
			---@class lfsampler.AccumulatedProbe
			---@field stacktrace lfsampler.Stacktrace
			local accsample = acc[h]
			if not accsample then
				accsample = {
					stacktrace = probe.stacktrace,
					sampleCount = 0,
					callCount = 0
				}
				results.probes[#results.probes+1] = accsample
				acc[h] = accsample
			end
			accsample.sampleCount = accsample.sampleCount + probe.sampleCount
			results.totalSamples = results.totalSamples + probe.sampleCount
			accsample.callCount = accsample.callCount + 1
		end
	end

	return results
end

--- Same as accumulate, but keeps order.
---@param hash fun(stacktrace: lfsampler.Stacktrace)
---@return lfsampler.AccumulatedResults
function ProfilerResults:squash(hash)
	hash = hash or stronghash

	---@class lfsampler.SquashedOrderedResults
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
					sampleCount = 0
				}
				results.probes[#results.probes+1] = accsample
			end
			accsample.sampleCount = accsample.sampleCount + probe.sampleCount
			results.totalSamples = results.totalSamples + probe.sampleCount
		end
	end

	return results
end

return ProfilerResults
