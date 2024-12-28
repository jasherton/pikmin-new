AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[
--//Animations//--
Ragdoll (0)
Idle (1)
Shake (2)
Close (3)
Spit (4)
--]]

ENT.CurAnim = 1
ENT.CurPiki = {}

function ENT:Initialize()
	self:SetModel("models/pikmin/pom.mdl")
	local tr = util.QuickTrace(self:GetPos(),-vector_up*10000,ents.GetAll())
	if tr.Hit then self:SetPos(tr.HitPos) end
	self:SetPos(self:GetPos()+self:GetUp()*2)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end
	if self.Color then self:SetSkin(self.Color-1) end
	self.Color = self:GetSkin()+1
	self.Cycle = self.Cycle or math.Rand(0,1)
end

function ENT:SpawnFunction(ply,tr)
	ply:ConCommand("pikmin_menu 4")
end

function ENT:Think()
	if self.LastAnim ~= self.CurAnim then
		self.LastAnim = self.CurAnim
		self:ResetSequence(self.CurAnim)
		if self.Cycle then self:SetCycle(self.Cycle) self.Cycle = nil end
	end
	local pos = self:GetPos()
	if self.CurAnim == 3 or self.CurAnim == 4 then
		if CurTime() >= self.SpitNext then
			if self.CurAnim == 3 then
				for _,v in ipairs(self.CurPiki) do
					v:Remove()
					local rand = math.Rand(-10,10)
					timer.Simple(0.05,function()
						PikminCreateSproutServer(self,self:GetPos()+Vector(math.sin(rand)*100,math.cos(rand)*100,50))
					end)
				end
				self:EmitSound("bud/spit.wav")
				table.Empty(self.CurPiki)
				self.CurAnim = 4
				self.SpitNext = CurTime() + 0.3
			elseif self.CurAnim == 4 then
				self.SpitNext = nil
				self.CurAnim = 1
			end
		end
		for _,v in ipairs(ents.FindInSphere(pos+vector_up*20,50)) do
			if v == self then continue end
			if v:IsNPC() or v:GetClass() == "pikmin" then
				local phys = v.Phys or v:GetPhysicsObject()
				if not phys or not IsValid(phys) then continue end
				phys:ApplyForceCenter((v:GetPos()-pos):GetNormalized()*300)
			elseif v:IsPlayer() then
				v:SetVelocity((v:GetPos()-pos):GetNormalized()*200)
			end
		end
	else
		if self.SpitNext and CurTime() >= self.SpitNext or #self.CurPiki >= 10 then
			self.CurAnim = 3
			self.SpitNext = CurTime() + 1.5
			self:SetModelScale(1,0.1)
			self:EmitSound("bud/close.wav")
		end
	end
	self:NextThink(CurTime())
	return true
end

function ENT:StartTouch(ent)
	if self.CurAnim == 3 or self.CurAnim == 4 then return end
	local rpos = ent:GetPos()-self:GetPos()
	if rpos.Z >= 0 then
		if (rpos*Vector(1,1,0)):Length() <= 40 then
			if ent:GetClass() == "pikmin" then
				ent:EmitSound("pikmin/pikmin_die.wav")
				ent:Die(true)
				table.insert(self.CurPiki,ent)
				self.SpitNext = CurTime()+2
				self:SetModelScale(1.3,0.05)
				timer.Simple(0.05,function() if IsValid(self) then self:SetModelScale(1,0.2) end end)
			end
		end
		return
	end
	if self.CurAnim == 2 then return end
	if (ent:GetVelocity()*Vector(1,1,0)):Length() <= 150 then return end
	self.CurAnim = 2
	timer.Simple(0.5,function() if IsValid(self) and self.CurAnim == 2 then self.CurAnim = 1 end end)
end

function ENT:CanProperty(ply,prop)
	if prop == "skin" then
		timer.Simple(0.1,function() self.Color = self:GetSkin()+1 end)
	end
	return true
end

function ENT:PreEntityCopy()
	local data = {Cycle=self:GetCycle()}
	duplicator.StoreEntityModifier(self,"PikInfo",data)
end