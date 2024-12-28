include("shared.lua")

local PikiObject = nil

local function PikiViewFunc(ply,pos,angles,fov,znear,zfar)
	if not IsValid(PikiObject) then return end
	pos = PikiObject:GetPos() + Vector(0,0,30)
	local pushLook = -angles:Forward()*100
	local trace = util.QuickTrace(pos,pushLook,ents.GetAll())
	local view = {
		origin = trace.HitWorld and trace.HitPos+trace.HitNormal*5 or pos+pushLook,
		angles = angles,
		fov = fov,
		drawviewer = true,
	}
	return view
end

function ENT:Initialize()
	timer.Simple(0.1,function()
	if IsValid(self) then
			if self:GetNWEntity("Leader") == LocalPlayer() then
				self.PikiView = true
				PikiObject = self:GetNWEntity("Piki")
				hook.Add("CalcView","PIKIVIEW",PikiViewFunc)
			end
		end
	end)
end

function ENT:Draw() end

function ENT:OnRemove()
	if self.PikiView then hook.Remove("CalcView","PIKIVIEW") end
end