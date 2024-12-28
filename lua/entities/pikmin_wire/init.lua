AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:KeyValue(key,value)
	if key == "hammerid" then self.WorldEnt = true end
	if key == "target" then self.LockLink = value end
	if key == "repeat" and value == "1" then self.Repeat = true end
	if string.Left(key,2) == "On" then
		self:StoreOutput(key,value)
	end
end

function ENT:AcceptInput(name,activator,caller,data) 
	if name == "Destroy" then self:TakeDamage(self:Health()) return true end
	if name == "Trigger" then
		self.NextShock = CurTime()
		return true
	end
	if name == "TriggerWith" then
		local ent = ents.FindByName(data)
		if ent[1] then self.NextLink = ent[1] end
		self.NextShock = CurTime()
		return true
	end
	return false
end

function ENT:Initialize()
	self:SetHealth(15)
	self:SetModel("models/pikmin/wirehiba.mdl")
	local tr = util.QuickTrace(self:GetPos(),-vector_up*10000,ents.GetAll())
	if tr.Hit then self:SetPos(tr.HitPos) end
	self:SetPos(self:GetPos()+self:GetUp()*2)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	self.NextShock = CurTime()+2.5
	self.CanHurt = false
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
end

function ENT:SpawnFunction(ply,tr)
	local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 10000, ents.GetAll())
	if not (tr.Hit and tr.HitPos) then return end
	local ent = ents.Create("pikmin_wire")
	ent:SetPos(tr.HitPos)
	local ang = (ply:GetPos()-tr.HitPos):Angle()
	ent:SetAngles(Angle(0,ang.Y,0))
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikmin_wire")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
end

local WireCenterOffset = Vector(0,0,10)

function ENT:Think()
	if self.NoThink then return false end
	
	if self.CanHurt then
		if IsValid(self.WireLink) and self.WireLink:Health() > 0 then
			local dmg = DamageInfo()
			dmg:SetDamage(1)
			dmg:SetAttacker(self)
			dmg:SetInflictor(self)
			dmg:SetDamageType(DMG_SHOCK)
			local victims = ents.FindAlongRay(self:GetPos(),self.WireLink:GetPos(),Vector(-15,-15,-15),Vector(15,15,15))
			for _,v in ipairs(victims) do
				if v == self then continue end
				local class = v:GetClass()
				if class == "pikmin_fire" or class == "pikmin_gas" or class == "pikmin_wire" then continue end
				dmg:SetDamagePosition(v:WorldSpaceCenter())
				v:TakeDamageInfo(dmg)
			end
			for _,v in ipairs(ents.FindInSphere(self:GetPos(),30)) do
				if v == self then continue end
				local class = v:GetClass()
				if class == "pikmin_fire" or class == "pikmin_gas" or class == "pikmin_wire" then continue end
				dmg:SetDamagePosition(v:WorldSpaceCenter())
				v:TakeDamageInfo(dmg)
			end
		else
			self.CanHurt = false
			self.WireLink = nil
			self.Shocking = false
			self.NextShock = CurTime()+2.5
			self:SetLinkWire(self)
		end
	end
	
	if CurTime() >= self.NextShock and not self.Linked then
		if not self.Shocking then
			self.Shocking = true
			self.NextShock = CurTime()+5
			local pos = self:GetPos()
			
			if self.LockLink and not self.LockFound then
				self.LockFound = true
				self.LockLink = ents.FindByName(self.LockLink)[1]
				self.LockLink.NoThink = true 
			end
			
			local wire = self.NextLink or self.LockLink
			if not wire or not IsValid(wire) then
				local wires = ents.FindByClass("pikmin_wire")
				table.sort(wires,function(a,b) return a:GetPos():DistToSqr(pos) < b:GetPos():DistToSqr(pos) end)
				wire = wires[2]
				if wire and wire.LockFound then wire = nil end
			end
			
			if self.NextLink then self.NextLink = nil end
			
			if wire and wire:Health() > 0 and not wire.Shocking and wire:GetPos():DistToSqr(pos) <= 180000 and not util.QuickTrace(pos+WireCenterOffset,wire:GetPos()-pos,ents.GetAll()).HitWorld then	
				self:TriggerOutput("OnActivated",self)
				self.Repeat = self.Repeat or wire.Repeat
				if (wire.LockFound and wire.LockLink == self) or (not wire.LockFound and wire.LockLink == self:GetName()) then
					wire.NoThink = true
					self.LockFound = true
					self.LockLink = wire
				end
				self.WireLink = wire
				self.WireLink.Shocking = true
				self.WireLink.NextShock = self.NextShock
				self.WireLink.WireLink = self
				self.WireLink.Linked = true
				self:SetLinkWire(self.WireLink)
				
				pos = pos+WireCenterOffset
				local pos2 = self.WireLink:GetPos()+WireCenterOffset
				
				timer.Create("spark"..self:EntIndex(),0.1,5,function()
					if not IsValid(self.WireLink) then return end
					local data = EffectData()
					data:SetOrigin(pos)
					data:SetScale(20)
					util.Effect("StunstickImpact",data)
					data:SetOrigin(pos2)
					util.Effect("StunstickImpact",data)
				end)
				
				timer.Create("tracer"..self:EntIndex(),0.3,1,function()
					if not IsValid(self) or not IsValid(self.WireLink) then return end
					self.CanHurt = true
					local data = EffectData()
					data:SetEntity(self)
					util.Effect("pikmin_zap",data)
				end)
			else
				self.NextShock = CurTime()+2.5
			end
		else
			if not self.Repeat then
				self.CanHurt = false
				self.Shocking = false
				self.NextShock = CurTime()+2.5
				if self.WireLink then
					if IsValid(self.WireLink) then
						self.WireLink.Shocking = false
						self.WireLink.NextShock = self.NextShock
						self.WireLink.Linked = false
					end
					self.WireLink = nil
					self:SetLinkWire(self)
				end
				timer.Remove("spark"..self:EntIndex())
				timer.Remove("tracer"..self:EntIndex())
				timer.Remove("tracer2"..self:EntIndex())
				self:TriggerOutput("OnIdle",self)
			end
		end
	end
	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:OnRemove()
	timer.Remove("spark"..self:EntIndex())
	timer.Remove("tracer"..self:EntIndex())
	timer.Remove("tracer2"..self:EntIndex())
	if self.WireLink and IsValid(self.WireLink) then self.WireLink.Shocking = false self.WireLink.Linked = false end
end

function ENT:OnTakeDamage(DamageInfo)
	if self.NoThink then self:SetHealth(0) return end
	if DamageInfo:IsDamageType(DMG_SHOCK) then return end
	local nhealth = self:Health()-DamageInfo:GetDamage()
	self:SetHealth(nhealth)
	if nhealth <= 0 then
		self.NoThink = true
		self.CanHurt = false
		if self.WireLink then
			if IsValid(self.WireLink) then
				self.WireLink.Shocking = false
				self.WireLink.NextShock = self.NextShock
				DamageInfo:SetDamage(100)
				self.WireLink:TakeDamageInfo(DamageInfo)
			end
			self.WireLink = nil
			self:SetLinkWire(self)
		end
		self:TriggerOutput("OnDeath",self)
	end
end

function ENT:PreEntityCopy()
	duplicator.StoreEntityModifier(self,"PikInfo",{Health=self:Health()})
end

function ENT:PostEntityPaste(ply,ent,created)
	local pikinfo = ent.EntityMods.PikInfo
	if pikinfo then
		self:SetHealth(pikinfo.Health)
	end
	self.Shocking = false
	self.WireLink = nil
	self.NextShock = CurTime() + 2.5
	self.Linked = false
	self.CanHurt = false
	ent.EntityMods = nil
end