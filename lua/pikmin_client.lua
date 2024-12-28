include("pikmin_shared.lua")
include("pikmin_video.lua")

--//temp fix to display Olimar Gun info properly (https://github.com/Facepunch/garrysmod-issues/issues/5186)
language.Add("olimar_gun",language.GetPhrase("olimar_gun"))
language.Add("olimar_gun.purpose",language.GetPhrase("olimar_gun.purpose"))
language.Add("olimar_gun.info1",language.GetPhrase("olimar_gun.info1"))
language.Add("olimar_gun.info2",language.GetPhrase("olimar_gun.info2"))
language.Add("olimar_gun.info3",language.GetPhrase("olimar_gun.info3"))
language.Add("olimar_gun.info4",language.GetPhrase("olimar_gun.info4"))
language.Add("olimar_gun.info5",language.GetPhrase("olimar_gun.info5"))

killicon.Add("pikmin","HUD/kill_pik",Color(255,80,0,255))
killicon.Add("olimar_gun","HUD/kill_orima",Color(255,80,0,255))

hook.Add("AddToolMenuCategories", "CreateUtilitiesCategories", function()
	spawnmenu.AddToolCategory("Main","Pikmin","#pikmin")
end)

--//captain death ragdoll fix
net.Receive("RagColorPly",function()
	local ply = net.ReadEntity()
	local ragIdx = net.ReadInt(32)
	local rag = Entity(ragIdx)
	if not IsValid(rag) then
		local hookname = "pkrg"..ragIdx
		hook.Add("Think",hookname,function()
			rag = Entity(ragIdx)
			if IsValid(rag) then
				rag.GetPlayerColor = function() return ply:GetPlayerColor() end
				hook.Remove("Think",hookname)
			end
		end)
		return
	end
	rag.GetPlayerColor = function() return ply:GetPlayerColor() end
end)

--//get player color
local function GetPlayerColor(ply)
	if not IsValid(ply) then return end
	if ply:IsBot() then return Color(0,0,0,30) end
	local val = ply:GetPlayerColor():ToColor() --Vector(ply:GetInfo("cl_playercolor")):ToColor()
	local r,g,b,a = val:Unpack()
	val:SetUnpacked(r,g,b,30)
	return val
end

--//draw captain light
local OrimaLightMultX = {36,36,33}
local GlowLight = Material("pikmin/glow")
local RayLight = Material("pikmin/ray")
hook.Add("PostPlayerDraw", "PikiGlow", function(ply)
	local idx = table.KeyFromValue(PIKMIN_CAPTAIN_MODELS,ply:GetModel())
	if not idx then return end
	if ply:GetBodygroup(1) ~= 0 then return end
	local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
	if not bone then return end
	local pos,ang = ply:GetBonePosition(bone)
	pos = pos + ang:Forward()*OrimaLightMultX[idx] - ang:Right()*21
	local color = ply.PikiColor
	if not color then color = GetPlayerColor(ply) ply.PikiColor = color end
	render.SetMaterial(GlowLight)
	render.DrawSprite(pos, 18, 18, color)
	local EyeNormal = (EyePos() - pos):GetNormal()
	EyeNormal.z = 0
	render.SetMaterial(RayLight)
	local rad = 22 + math.sin(CurTime()*2.5)
	render.DrawQuadEasy(pos, EyeNormal, rad, rad, color_white, CurTime() * 22)
	local dlight = DynamicLight(ply:EntIndex())
	if not dlight then return end
	dlight.pos = pos
	dlight.r,dlight.g,dlight.b = color.r,color.g,color.b
	dlight.brightness = 1
	dlight.Decay = 1000
	dlight.Size = 100
	dlight.DieTime = CurTime() + 0.1
end)

--//initiate captain light color
gameevent.Listen("player_spawn")
hook.Add("player_spawn","PikiGlowPre",function(data)
	local ply = Player(data.userid)
	ply.PikiColor = GetPlayerColor(ply)
end)

--//Onion Menu
--change this to make use of EntIndex instead of sending arguments
local function PikminOnionMenu(ply,cmd,args)
	if not args[1] or not args[2] or not args[3] then return end
	--local tr = util.QuickTrace(ply:GetShootPos(), (ply:GetAimVector() * 200), ply)
	--if IsValid(tr.Entity) and tr.Entity:GetClass() == "pikmin_onion" then
	args[1] = tonumber(args[1])
	args[2] = tonumber(args[2])
	args[3] = tonumber(args[3])
	local frameColor = args[1] == 2 and Color(150,0,0,250)
	or args[1] == 1 and Color(150,150,0,250)
	or args[1] == 0 and Color(0,0,100,250)
	
	local w, h = surface.ScreenWidth(), surface.ScreenHeight()
	local frame = vgui.Create("DFrame")
	frame:SetSize((w * .3), (h * .5))
	
	local W = frame:GetWide()
	local H = frame:GetTall()
	frame.Paint = function()
		draw.RoundedBox(8,0,0,frame:GetWide(),frame:GetTall(),frameColor)
	end
	
	frame:SetPos(((w * .5) - (W * .5)), (h * .5) - (H * .5))
	frame:SetVisible(true)
	frame:MakePopup()
	frame:SetTitle("#pikionionmenu")
	
	local label = vgui.Create("DLabel",frame)
	label:SetPos(0,H*0.1)
	label:SetSize(W,H*0.1)
	label:SetText(args[2]..language.GetPhrase("pikmin_count"))
	label:SetFont("DermaLarge")
	label:SetTextColor(Color(255,255,255,255))
	label:SetContentAlignment(5)
	
	local call_slider = nil
	local send_slider = nil
	local act_button = nil
	
	if (args[2] ~= 0 and not args[4]) or args[3] ~= 0 then
		act_button = vgui.Create("DButton", frame)
		act_button:SetPos((W * .1), (H * .8))
		act_button:SetWide((W * .8))
		act_button:SetTall((H * .1))
		act_button:SetText("#pikicall")
		act_button.DoClick = function()
			if call_slider and send_slider then
				ply:ConCommand("pikmin_call "..math.floor(call_slider:GetValue()).." "..math.floor(send_slider:GetValue()))
			elseif call_slider then
				ply:ConCommand("pikmin_call "..math.floor(call_slider:GetValue()))
			elseif send_slider then
				ply:ConCommand("pikmin_call 0 "..math.floor(send_slider:GetValue()))
			end
			frame:Close()
		end
	end
	
	local CallTotal = math.min(100-#ents.FindByClass("pikmin")-#ents.FindByClass("pikmin_sprout"),args[2])
	
	if CallTotal ~= 0 then
		call_slider = vgui.Create("DNumSlider",frame)
		call_slider:SetMinMax(0,CallTotal)
		call_slider:SetPos(W*-0.18, H*0.6)
		call_slider:SetSize(W, H*0.1)
		call_slider:SetValue(0)
		call_slider:SetDecimals(0)
		function call_slider:OnValueChanged(val)
			if send_slider then
				label:SetText(args[2]-math.floor(val)+math.floor(send_slider:GetValue())..language.GetPhrase("pikmin_count"))
			else
				label:SetText(args[2]-math.floor(val)..""..language.GetPhrase("pikmin_count"))
			end
		end
	end
	
	if args[3] ~= 0 then
		act_button:SetText("#pikisend")
		send_slider = vgui.Create("DNumSlider",frame)
		send_slider:SetPos(W*-0.18, H*0.6)
		if call_slider then
			send_slider:SetPos(W*-0.18, H*0.4)
			act_button:SetText("#pikicallsend")
		end
		send_slider:SetMinMax(0,args[3])
		send_slider:SetSize(W, H*0.1)
		send_slider:SetValue(0)
		send_slider:SetDecimals(0)
		function send_slider:OnValueChanged(val)
			if call_slider then
				label:SetText(args[2]-math.floor(call_slider:GetValue())+math.floor(val)..language.GetPhrase("pikmin_count"))
			else
				label:SetText(args[2]+math.floor(val)..language.GetPhrase("pikmin_count"))
			end
		end
	end
	
	frame:SizeToContents()
	--end
end
concommand.Add("pikmin_onion", PikminOnionMenu)