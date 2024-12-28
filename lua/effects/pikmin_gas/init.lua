function EFFECT:Init(data)
	local ent = data:GetEntity()
	self.Ent = ent
	self.Emitter = ParticleEmitter(ent:GetPos())
	self.CreateTime = CurTime()+0.5
	self.NextPart = CurTime()
end

function EFFECT:Think()
	if CurTime() >= self.CreateTime then
		if not IsValid(self.Ent) or not self.Ent:GetNWBool("Emit",true) then
			self.Emitter:Finish()
			return false
		end
		if CurTime() >= self.NextPart then
			self.NextPart = CurTime()+math.Rand(0.1,1)/8
			local part = self.Emitter:Add("particles/smokey",self.Ent:GetPos()+Vector(0,0,10))
			local size = math.Rand(2, 4)
			part:SetColor(175, 25, 175, 255)
			part:SetVelocity(VectorRand() * (8 + (math.random(5, 6))))
			part:SetDieTime(math.Rand(1,3))
			part:SetLifeTime(0)
			part:SetStartSize(5)
			part:SetEndSize((size * 12))
			part:SetStartAlpha(math.random(140, 200))
			part:SetEndAlpha(0)
			part:SetBounce(1)
			part:SetCollide(true)
			part:SetGravity(Vector(0, 0, .5))
			part:SetAirResistance(7.5 + math.Rand(0.8,6.5))
			part:SetAngleVelocity(Angle(math.Rand(-0.8, 0.8), math.Rand(-0.8, 0.8), math.Rand(-0.8, 0.8)))
			part:SetLighting(false)
		end
	end
	return true
end

function EFFECT:Render()
end