include("shared.lua")

function ENT:Initialize()
	self:SetSolid(SOLID_NONE)
end

local BoneNames = {"piki_leaf","piki_bud","piki_flower"}

function ENT:Draw()
	--//stop drawing held pikmin
	local ply = LocalPlayer()
	if self:GetParent():GetParent() == ply then
		if not ply:ShouldDrawLocalPlayer() then return end
	end
	
	self:DrawModel()
	
	local seq = self:GetSequence()
	if self:GetNWBool("Dismissed",false) and seq ~= 9 and seq ~= 4 then
		local bone = self:LookupBone(BoneNames[self:GetNWInt("Level",1)])
		if bone then
			local pos = self:GetBonePosition(bone)
			if pos == self:GetPos() then pos = self:GetBoneMatrix(bone):GetTranslation() end
			render.SetMaterial(PIKMIN_DISBAND_LIGHT)
			render.DrawSprite(pos, 28, 28, PIKMIN_DISBAND_COLORS[self:GetNWInt("Color",1)])
		end
	end
	
	if self:GetNWBool("Poison") then
		local bone = self:LookupBone(BoneNames[self:GetNWInt("Level",1)])
		if bone then
			local pos = self:GetBonePosition(bone)
			if pos == self:GetPos() then pos = self:GetBoneMatrix(bone):GetTranslation() end
			render.SetMaterial(PIKMIN_POISON_MAT)
			local sizevar = math.sin(CurTime()*12)*4
			render.DrawQuadEasy(pos,(EyePos()-pos):GetNormal(),24+sizevar,24+sizevar,Color(175,25,175),math.sin(CurTime()*10)*8)
		end
	end
end