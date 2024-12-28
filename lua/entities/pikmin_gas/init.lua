AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:KeyValue(key,value)
	if key == "hammerid" then self.WorldEnt = true end
	if string.Left(key,2) == "On" then
		self:StoreOutput(key,value)
	end
end

function ENT:AcceptInput(name,activator,caller,data) 
	if name == "Destroy" then self:TakeDamage(self:Health()) return true end
	return false
end

function ENT:Initialize()
	self:SetHealth(15)
	self:SetModel("models/pikmin/gashiba.mdl")
	local tr = util.QuickTrace(self:GetPos(),-vector_up*10000,ents.GetAll())
	if tr.Hit then self:SetPos(tr.HitPos) end
	self:SetPos(self:GetPos()+self:GetUp()*2)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	self:SetNWBool("Emit",true)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
	self:TriggerOutput("OnActivated",self)
end

function ENT:SpawnFunction(ply,tr)
	local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 10000, ents.GetAll())
	if not (tr.Hit and tr.HitPos) then return end
	local ent = ents.Create("pikmin_gas")
	ent:SetPos(tr.HitPos)
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikmin_gas")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
end

function ENT:Think()
	if self.NoThink then self:SetNWBool("Emit",false) return false end
	local dmg = DamageInfo()
	dmg:SetDamage(5)
	dmg:SetAttacker(self)
	dmg:SetInflictor(self)
	dmg:SetDamageType(DMG_POISON)
	for _,v in ipairs(ents.FindInSphere(self:GetPos(),30)) do
		if v == self then continue end
		local class = v:GetClass()
		if class == "pikmin_fire" or class == "pikmin_gas" or class == "pikmin_wire" then continue end
		v:TakeDamageInfo(dmg)
	end
	self:NextThink(CurTime()+0.5)
	return true
end

function ENT:OnRemove() end

function ENT:OnTakeDamage(DamageInfo)
	if self.NoThink then return end
	if DamageInfo:IsDamageType(DMG_POISON) then return end
	local nhealth = self:Health()-DamageInfo:GetDamage()
	self:SetHealth(nhealth)
	if nhealth <= 0 then
		self:TriggerOutput("OnDeath",self)
		self:SetNWBool("Emit",false)
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
	end
	ent.EntityMods = nil
end