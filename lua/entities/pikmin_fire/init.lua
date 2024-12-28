AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--//HP is 150; 150*0.1 = 15

function ENT:KeyValue(key,value)
	if key == "hammerid" then self.WorldEnt = true end
	if string.Left(key,2) == "On" then
		self:StoreOutput(key,value)
	end
end

function ENT:AcceptInput(name,activator,caller,data) 
	if name == "Destroy" then self:TakeDamage(self:Health()) return true end
	if name == "Trigger" then self.NextFire = CurTime() return true end
	return false
end

function ENT:Initialize()
	self:SetHealth(15)
	self.NextFire = CurTime()+5
	self.Emit = false
	self:SetModel("models/pikmin/firehiba.mdl")
	local tr = util.QuickTrace(self:GetPos(),-vector_up*10000,ents.GetAll())
	if tr.Hit then self:SetPos(tr.HitPos) end
	self:SetPos(self:GetPos()+self:GetUp()*2)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	self.FireSound = CreateSound(self,"pikmin/fire.wav")
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
end

function ENT:SpawnFunction(ply,tr)
	local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 10000, ents.GetAll())
	if not (tr.Hit and tr.HitPos) then return end
	local ent = ents.Create("pikmin_fire")
	ent:SetPos(tr.HitPos)
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikmin_fire")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
end

local NoBurnSurf = {
"metal",
"computer",
"canister",
"combine_metal",
"metal_barrel",
"metal_bouncy",
"roller",
"popcan",
"metalvehicle",
"metalvent",
"metalgrate",
"metalpanel",
"Metal_Box",
"gunship",
"crowbar",
"rock",
"concrete",
"boulder",
"gravel"
}

function ENT:Think()
	if self:Health() == 0 then self.NoThink = true end
	if self.NoThink then self.FireSound:Stop() self:SetNWBool("Emit",false) return false end
	if self.Emit then
		local dmg = DamageInfo()
		dmg:SetDamage(10)
		dmg:SetAttacker(self)
		dmg:SetInflictor(self)
		dmg:SetDamageType(DMG_BURN)
		for _,v in ipairs(ents.FindInSphere(self:GetPos(),30)) do
			if v == self then continue end
			local class = v:GetClass()
			if class == "pikmin_fire" or class == "pikmin_gas" or class == "pikmin_wire" then continue end
			if not v:IsOnFire() and (class == "prop_physics" or class == "prop_ragdoll") and not table.KeyFromValue(NoBurnSurf,v:GetBoneSurfaceProp(0)) then v:Ignite(5,0) end
			v:TakeDamageInfo(dmg)
		end
	end
	if CurTime() >= self.NextFire then
		self.Emit = not self.Emit
		self:SetNWBool("Emit",self.Emit)
		if self.Emit then
			self:TriggerOutput("OnActivated",self)
			local effect = EffectData()
			effect:SetEntity(self)
			util.Effect("pikmin_blaze",effect)
			self.FireSound:Play()
			self.NextFire = CurTime()+2.5
		else
			self:TriggerOutput("OnIdle",self)
			self.FireSound:FadeOut(0.5)
			self.NextFire = CurTime()+5
		end
	end
	self:NextThink(CurTime()+0.5)
	return true
end

function ENT:OnRemove()
	if self.FireSound then self.FireSound:Stop() end
end

function ENT:OnTakeDamage(DamageInfo)
	if self.NoThink then return end
	if DamageInfo:IsDamageType(DMG_BURN) then return end
	local nhealth = self:Health()-DamageInfo:GetDamage()
	self:SetHealth(nhealth)
	if nhealth <= 0 then
		self:TriggerOutput("OnDeath",self)
		self.NoThink = true
	end
end

function ENT:PreEntityCopy()
	duplicator.StoreEntityModifier(self,"PikInfo",{Health=self:Health()})
end

function ENT:PostEntityPaste(ply,ent,created)
	local pikinfo = ent.EntityMods.PikInfo
	if pikinfo then
		self:SetHealth(pikinfo.Health)
		self.Emit = false
		self.NextFire = CurTime()+5
	end
	ent.EntityMods = nil
end