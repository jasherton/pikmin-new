AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Debounce = false
ENT.PikInteract = true

function ENT:Initialize()
	self:SetModel("models/pikmin/nectar.mdl") --self:SetModel("models/props_vehicles/carparts_wheel01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetColor(Color(255, 191, 0, 255))
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(500)
		phys:Wake()
	end
end

function ENT:SpawnFunction(ply, tr)
	if !tr.Hit then return end
	local ent = ents.Create("pikmin_nectar")
	ent:SetPos(tr.HitPos + tr.HitNormal * 16)
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikmin_nectar")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
end

function ENT:Think()
	if self:WaterLevel() >= 1 then self:Remove() return false end
	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:PikTrigger()
	if not self.Debounce then
		self.Debounce = true
		timer.Create("nectar"..self:EntIndex(),2.5,1,function()
			self:Remove()
		end)
	end
end

function ENT:OnRemove()
	timer.Remove("nectar"..self:EntIndex())
	for _,v in ipairs(self:GetChildren()) do
		if v:GetClass() == "pikmin" then
			v:SetPos(Vector(math.Rand(-20, 20), math.Rand(-20, 20), 10))
			v:SetParent()
			v:SetLevel(3)
			v:EmitSound("pikmin/level.wav")
			v.Drinking = false
		end
	end
end