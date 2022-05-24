# LFSampler

LFSampler is a sample profiler, for `Lua 5.1-5.4` or `LuaJIT`.
It uses the jit profiler, if available, or the debug library.

# Demo

## Flamegraphs

How it works:

```lua

local lfsampler = require "lfsampler"
local formatter = require "lfsampler.formatter"

lfsampler.start()
-- Some code
lfsampler.finish()

local file = io.open("output.cap", "w")
file:write(formatter.flamegraph(lfsampler.popResults()))
file:close()

```

Now use Flamegraph, to generate the svg:
```
flamegraph output.cap > output.svg
```
Flamegraphs are awesome, I highly recommend checking out this video.

## Source annotations

How it works:

```lua

local lfsampler = require "lfsampler"
local formatter = require "lfsampler.formatter"

lfsampler.start()
-- Some code
lfsampler.finish()

local sources = formatter.annotateSource(lfsampler.popResults())
for name, data in pairs(sources) do
	local file = io.open(name:gsub("%.lua", ".tlua"):gsub("/", "."):gsub(), "w")
	file:write(data)
	file:close()
end

```

# Getting started

## Installing

Either install via:
```
luarocks install lfsampler
```
or drop the `lfsampler` folder into your `package.path`.

## Running sampler

It is as simple as that:

```lua

local lfsampler = require "lfsampler"
local formatter = require "lfsampler.formatter"

lfsampler.start()
-- Some code
lfsampler.finish()

local file = io.open("output.cap", "w")
file:write(formatter.formatReport(formatter.generateReport(lfsampler.popResults())))
file:close()

```

# Manual