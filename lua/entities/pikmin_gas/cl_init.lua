include("shared.lua")

function ENT:Initialize()
	local effect = EffectData()
	effect:SetEntity(self)
	util.Effect("pikmin_gas",effect)
end

function ENT:Draw()
	self:DrawModel()
end