function EFFECT:Init(data)
	local ent = data:GetEntity()
	if not IsValid(ent) then return end
	self.Ent = ent
	self.Emitter = ParticleEmitter(ent:GetPos())
	self.CreateTime = CurTime()+0.5
end

function EFFECT:Think()
	if CurTime() >= self.CreateTime then
		if not IsValid(self.Ent) or not self.Ent:GetNWBool("Emit",true) then
			if self.Light then
				self.Light.decay = 2000
				self.Light.dietime = CurTime()+1
			end
			self.Emitter:Finish()
			return false
		end
		if not self.Light then
			local light = DynamicLight(self.Ent:EntIndex())
			self.Light = light
			light.pos = self.Ent:GetPos()
			light.r = 255
			light.g = 255
			light.b = 0
			light.brightness = 2
			light.decay = 1
			light.dietime = CurTime()+3
			light.size = 200
		end
		local part = self.Emitter:Add("effects/fire_embers3",self.Ent:GetPos()-vector_up*2)
		local spread = Vector(math.sin(math.Rand(0, 360)) * math.Rand(-50, 50), math.cos(math.Rand(0, 360)) * math.Rand(-50, 50), math.sin(math.random()) * math.Rand(-50, 50))
		part:SetStartSize(10)
		part:SetEndSize(50)
		part:SetStartAlpha(255)
		part:SetEndAlpha(0)
		part:SetColor(255,255,0)
		part:SetDieTime(1)
		part:SetLifeTime(0)
		part:SetLighting(false)
		part:SetGravity(Vector(0,0,0))
		part:SetVelocity(spread+vector_up*200)
		part:SetAngles(vector_up:Angle())
		part:SetAngleVelocity(Angle(0,0,0))
		part:SetCollide(true)
		part:SetAirResistance(0)
		part:SetBounce(0)
	end
	return true
end

function EFFECT:Render()
end