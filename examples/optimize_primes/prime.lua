
local prime = { }

function prime.is_prime_v1(n)
	for i = 2, n - 1 do
		if n / i % 1 == 0 then
			return false
		end
	end

	return true
end

local function gcd(a, b)
	a, b = a > b and a or b, b < a and b or a
	if b == 0 then
		return a;
	else
		return gcd(b, (a % b))
	end
end

function prime.is_prime_v2(n)
	for i = 2, n - 1 do
		if gcd(i, n) ~= 1 then
			return false
		end
	end

	return true
end

return prime
