include("shared.lua")

function ENT:Initialize() end

local BoneNames = {"piki_leaf","piki_bud","piki_flower"}

function ENT:Draw()
	self:DrawModel()
	local bone = self:LookupBone(BoneNames[self:GetNWInt("Level",1)])
	if bone then
		local pos = self:GetBonePosition(bone)
		if pos == self:GetPos() then pos = self:GetBoneMatrix(bone):GetTranslation() end
		render.SetMaterial(PIKMIN_DISBAND_LIGHT)
		render.DrawSprite(pos, 28, 28, PIKMIN_DISBAND_COLORS[self:GetNWInt("Color",1)])
	end
end