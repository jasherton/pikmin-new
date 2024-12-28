AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.CurAnim = 2

ENT.m_iClass = CLASS_PLAYER
AccessorFunc(ENT, "m_iClass", "NPCClass")

function ENT:Initialize()
	self:DrawShadow(false)
	self.Cycle = self.Cycle or math.Rand(0,1)
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetSolid(SOLID_BBOX)
	self:SetCustomCollisionCheck(true)
	--self.m_iClass = CLASS_NONE --npcs cant detect me
end

function ENT:Think()
	if self.LastAnim ~= self.CurAnim then
		self.LastAnim = self.CurAnim
		self:ResetSequence(self.CurAnim)
		if self.Cycle then self:SetCycle(self.Cycle) self.Cycle = nil end
	end
	self:NextThink(CurTime())
	return true
end