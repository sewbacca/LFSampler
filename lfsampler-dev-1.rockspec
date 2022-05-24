package = "lfsampler"
version = "dev-1"
source = {
   url = "https://github.com/sewbacca/LFSampler"
}
description = {
   detailed = "LFSampler is a sample profiler, for `Lua 5.1-5.4` or `LuaJIT`.\nIt uses the jit profiler, if available, or the debug library.",
   homepage = "https://github.com/sewbacca/LFSampler",
   license = "MIT: https://github.com/sewbacca/LFSampler/blob/main/LICENSE"
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
