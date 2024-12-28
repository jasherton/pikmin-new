ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.PrintName		= "#pikmin_wire"
ENT.Author			= "jasherton"
ENT.Category		= "#pikmin"

ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "LinkWire")
end