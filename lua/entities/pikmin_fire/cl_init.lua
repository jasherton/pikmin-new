include("shared.lua")

function ENT:Initialize()
	if self:GetNWBool("Emit",false) then
		local effect = EffectData()
		effect:SetEntity(self)
		util.Effect("pikmin_blaze",effect)
	end
end

function ENT:Draw()
	self:DrawModel()
end