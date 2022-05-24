
local t = { }

function t.c()
	print(debug.traceback())
end

local function b()
	t.c()
end

local function a()
	b()
end

a()