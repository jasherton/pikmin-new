function EFFECT:Init(data)
	local pos = data:GetOrigin();
	pos = (pos + Vector(0, 0, 20));
	local em = ParticleEmitter(pos);
	for i = 1, 32 do
		local part = em:Add("particles/smokey", pos);
		local size = math.Rand(2, 4);
		if (part) then
			local vec = (VectorRand() * (8 + (i * math.random(5, 6))));
			local clamp = math.Clamp(vec.z, -5, 5);
			part:SetColor(175, 25, 175, 255);
			part:SetVelocity(Vector(vec.x, vec.y, clamp));
			part:SetDieTime(math.Rand(12, 14));
			part:SetLifeTime(0);
			part:SetStartSize(size * 5);
			part:SetEndSize((size * 12));
			part:SetStartAlpha(math.random(140, 200));
			part:SetEndAlpha(0);
			part:SetBounce(1);
			part:SetCollide(true);
			part:SetGravity(Vector(0, 0, .5));
			part:SetAirResistance((7.5 + (i * (i * .2))));
			part:SetAngleVelocity(Angle(math.Rand(-0.8, 0.8), math.Rand(-0.8, 0.8), math.Rand(-0.8, 0.8)));
			part:SetLighting(false);
		end
	end
	em:Finish();
end

function EFFECT:Think()
end


function EFFECT:Render()
end
