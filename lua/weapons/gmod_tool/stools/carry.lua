TOOL.Category		= "Pikmin"
TOOL.Name			= "#tool.carry.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Information = {{name="left"},{name="right"},{name="reload"}}

TOOL.ClientConVar = {
["min"] = 1,
["max"] = 1,
["autoweight"] = 0,
["automax"] = 0,
}

TOOL:BuildConVarList()

function TOOL:LeftClick(trace)
	if trace.HitWorld then return end
	local ent = trace.Entity
	if not IsValid(ent) or ent:GetClass() ~= "prop_physics" then return end
	
	if not ent.LastMass then ent.LastMass = ent:GetPhysicsObject():GetMass() end
	local autovalue = math.max(1,math.floor(ent:GetPhysicsObject():GetMass()/50))
	local autovalue2 = autovalue*2
	local dictInfo = PikiCarryDict[ent:GetModel()]
	if dictInfo then autovalue,autovalue2 = dictInfo[1],dictInfo[2] end
	
	ent.DidWeight = true
	local mincarry = self:GetClientNumber("autoweight") == 1 and autovalue or math.max(1,self:GetClientNumber("min"))
	local maxcarry = self:GetClientNumber("automax") == 1 and autovalue2 or math.max(1,self:GetClientNumber("max"))
	ent:GetPhysicsObject():SetMass(mincarry*50)
	ent:SetNWInt("pikiweight",mincarry)
	ent:SetNWInt("pikimax",maxcarry)
	ent:SetNWBool("iscarry",true)
	ent.IsCarry = true
	ent.PikMove = ent:GetNWInt("weight") >= mincarry
	return true
end

function TOOL:RightClick(trace)
	if trace.HitWorld then return end
	local ent = trace.Entity
	if not IsValid(ent) or ent:GetClass() ~= "prop_physics" then return end
	local ply = self:GetOwner()
	
	local autovalue = math.max(1,math.floor(ent:GetPhysicsObject():GetMass()/50))
	local autovalue2 = autovalue*2
	local dictInfo = PikiCarryDict[ent:GetModel()]
	if dictInfo then autovalue,autovalue2 = dictInfo[1],dictInfo[2] end
	
	ply:ConCommand("carry_min "..ent:GetNWInt("pikiweight",autovalue))
	ply:ConCommand("carry_max "..ent:GetNWInt("pikimax",autovalue2))
	return true
end

function TOOL:Reload(trace)
	if trace.HitWorld then return end
	local ent = trace.Entity
	if not IsValid(ent) or ent:GetClass() ~= "prop_physics" then return end
	local dictInfo = PikiCarryDict[ent:GetModel()]
	ent.IsCarry = dictInfo and true or false
	ent.DidWeight = true
	
	if ent.LastMass then ent:GetPhysicsObject():SetMass(ent.LastMass) end
	local autovalue = math.max(1,math.floor(ent:GetPhysicsObject():GetMass()/50))
	local autovalue2 = autovalue*2
	if dictInfo then autovalue,autovalue2 = dictInfo[1],dictInfo[2] end
	
	ent:SetNWInt("pikiweight",autovalue)
	ent:SetNWInt("pikimax",autovalue2)
	ent:SetNWBool("iscarry",dictInfo and true or false)
	ent.PikMove = ent:GetNWInt("weight") >= autovalue
	return true
end

if CLIENT then
	surface.CreateFont("PIKICARRYBIG",
	{
		font = "Roboto",
		size = 52,
		weight = 500,
		antialias = true,
		blursize = 0,
		scanlines = 0,
		outline = false,
	})
	surface.CreateFont("PIKICARRY",
	{
		font = "Roboto",
		size = 32,
		weight = 500,
		antialias = true,
		blursize = 0,
		scanlines = 0,
		outline = false,
	})
end

local HookedDraw = false
local EntityDraw = nil
local EntityMin,EntityMax,EntityCur = 0,0,0
local EntityValid = false
local color_gray = Color(200,200,200,255)
local function ToolCarryDraw()
	if EntityDraw and IsValid(EntityDraw) then
		cam.IgnoreZ(true)
		local pos = EntityDraw:WorldSpaceCenter()
		local _,max = EntityDraw:WorldSpaceAABB()
		
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(LocalPlayer():GetForward(), 270)
		ang:RotateAroundAxis(LocalPlayer():GetRight(), -180)
		ang:RotateAroundAxis(LocalPlayer():GetUp(), 90)
		ang = Angle(0, ang.y, ang.r)
		
		local scale = math.min(0.7,pos:Distance(LocalPlayer():GetPos())/256)
		pos = Vector(pos.X,pos.Y,max.Z+60*scale)
		cam.Start3D2D(pos,ang,scale)
		surface.SetTextColor(EntityValid and color_white or color_gray)
		surface.SetDrawColor(EntityValid and color_white or color_gray)
		surface.SetFont("PIKICARRYBIG")
		local w1,h1 = surface.GetTextSize(EntityMin)
		surface.SetTextPos(-w1/2,-h1/2)
		surface.DrawText(EntityMin)
		surface.SetFont("PIKICARRY")
		local w2,h2 = surface.GetTextSize(EntityCur)
		surface.DrawRect(-w1/2-4,h1/2-4,w1+8,2)
		surface.SetTextPos(-w2/2,h1/2-2)
		surface.DrawText(EntityCur)
		cam.End3D2D()
		cam.IgnoreZ(false)
	end
end

function TOOL:Think()
	if CLIENT then if not HookedDraw then HookedDraw = true hook.Add("PreDrawEffects","PikiToolCarry",ToolCarryDraw) end end
	local trace = self:GetOwner():GetEyeTrace()
	if not trace.HitWorld and IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_physics" then
		local ent = trace.Entity
		if SERVER then
			if not ent.DidWeight then
				ent.DidWeight = true
				local autovalue = math.max(1,math.floor(trace.Entity:GetPhysicsObject():GetMass()/50))
				local autovalue2 = autovalue*2
				local dictInfo = PikiCarryDict[trace.Entity:GetModel()]
				if dictInfo then autovalue,autovalue2 = dictInfo[1],dictInfo[2] end
				ent:SetNWInt("pikiweight",autovalue)
				ent:SetNWInt("pikimax",autovalue2)
			end
		end
		if CLIENT then
			EntityMin = ent:GetNWInt("pikiweight")
			EntityMax = ent:GetNWInt("pikimax")
			EntityCur = ent:GetNWInt("weight")
			EntityValid = ent:GetNWBool("iscarry") or PikiCarryDict[ent:GetModel()]
			EntityDraw = ent
		end
	else
		if CLIENT then EntityDraw = nil end
	end
end

function TOOL:Holster()
	if CLIENT then
		if HookedDraw then
			HookedDraw = false
			hook.Remove("PreDrawEffects","PikiToolCarry")
		end
		EntityDraw = nil
	end
end

function TOOL.BuildCPanel(panel)
	panel:Help("#tool.carry.desc")
	local weightslider = panel:NumSlider("#tool.carry.menu1", "carry_min", 1, 1000, 0)
	local maxslider = panel:NumSlider("#tool.carry.menu2", "carry_max", 1, 200, 0)
	panel:CheckBox("#tool.carry.menu3","carry_autoweight")
	panel:CheckBox("#tool.carry.menu4","carry_automax")
	--add checkbox for marking the object as a treasure (pathfind to dropoff or ship)
end