include("shared.lua")

function ENT:Initialize()
	if not self.GetLinkWire then return end
	local wire = self:GetLinkWire()
	if wire and IsValid(wire) and wire ~= self then
		local data = EffectData()
		data:SetEntity(self)
		util.Effect("pikmin_zap",data)
	end
end

function ENT:Draw()
	self:DrawModel()
end