
local mod = { }

local totalN = 0
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
		print(value)
	end
end

function mod.layer(n)
	for _ = 1, n do
		mod.rainingFunction()
	end
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

function mod.root()
	mod.sectionA()
	mod.sectionB()
	mod.sectionC()
end

return mod
