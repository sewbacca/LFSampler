package = "luaflamegraph"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   detailed = "Lua Flamegraph uses either the debug library, or, if possible, the luajit sampler, to generate samples, readable by [FlameGraph](https://github.com/brendangregg/FlameGraph).",
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      ["lfsampler.debugProfiler"] = "lua/lfsampler/debugProfiler.lua",
      ["lfsampler.formatters"] = "lua/lfsampler/formatters.lua",
      ["lfsampler.init"] = "lua/lfsampler/init.lua",
      ["lfsampler.jitProfiler"] = "lua/lfsampler/jitProfiler.lua",
      ["lfsampler.ProfilerResults"] = "lua/lfsampler/ProfilerResults.lua",
   }
}
