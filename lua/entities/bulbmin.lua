AddCSLuaFile()

ENT.Type 		= "point"
ENT.Base 		= "base_entity"
ENT.PrintName	= "#pikmin6"
ENT.Category	= "#pikmin"
ENT.Spawnable	= true
ENT.AdminOnly	= false

function ENT:SpawnFunction(ply,tr)
	ply:ConCommand("pikmin_create bulbmin")
end