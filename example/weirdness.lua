
local mod = { }

local totalN = 0
function mod.root()
	totalN = 0
	mod.sectionA()
	mod.sectionB()
	mod.sectionC()
	print()
end

function mod.sectionA()
	mod.layer(400)
end

function mod.sectionB()
	mod.layer(100)
end

function mod.sectionC()
	mod.layer(150)
end

function mod.layer(n)
	for _ = 1, n do
		mod.rainingFunction()
	end
end

local function populate(n)
	local t = { }
	for i = totalN + 1, totalN + n do
		t[#t+1] = i
	end
	totalN = totalN + n
	return t
end

function mod.rainingFunction()
	for _, value in ipairs(populate(10)) do
		io.write(string.format("\r%6.2f %%", 100 * value/6500))
	end
end

return mod
