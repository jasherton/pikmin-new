local mat = Material("effects/tool_tracer")

function EFFECT:Init(data)
	local ent = data:GetEntity()
	self.Entity = ent
	self.CreateTime = CurTime()+0.2
end

function EFFECT:Think()
	if CurTime() >= self.CreateTime then
		self.Entity2 = self.Entity.GetLinkWire and self.Entity:GetLinkWire() or self.Entity
		if not IsValid(self.Entity) or not IsValid(self.Entity2) or self.Entity2 == self.Entity then
			if self.Light1 then
				self.Light1.decay = 4000
				self.Light1.dietime = CurTime()+1
			end
			if self.Light2 then
				self.Light2.decay = 4000
				self.Light2.dietime = CurTime()+1
			end
			return false
		end
		self:SetRenderBoundsWS(self.Entity:GetPos(),self.Entity2:GetPos())
		if not self.Light1 then
			local light = DynamicLight(self.Entity:EntIndex())
			self.Light1 = light
			light.pos = self.Entity:GetPos()
			light.r = 255
			light.g = 255
			light.b = 255
			light.brightness = 0.1
			light.decay = 1
			light.dietime = CurTime()+5
			light.size = 500
		end
		if not self.Light2 then
			local light = DynamicLight(self.Entity2:EntIndex())
			self.Light2 = light
			light.pos = self.Entity2:GetPos()
			light.r = 255
			light.g = 255
			light.b = 255
			light.brightness = 0.1
			light.decay = 1
			light.dietime = CurTime()+5
			light.size = 500
		end
	end
	return true
end


function EFFECT:Render()
	if not self.Entity2 or not IsValid(self.Entity2) then return end
	render.SetMaterial(mat)
	local coord = math.Rand(0,1)
	local dir = (self.Entity:GetPos()-self.Entity2:GetPos()):GetNormalized()
	local s,e = self.Entity:GetPos()-dir*4+Vector(0,0,16),self.Entity2:GetPos()+dir*4+Vector(0,0,16)
	render.DrawBeam(s,e,28,coord,coord+(e-s):Length()/128,Color(0,255,255,255))
end