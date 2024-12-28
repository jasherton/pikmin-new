PikiMenu = PikiMenu or nil

local function SpawnPikminMenu(ply, cmd, args)
	if args[1] == "0" then if PikiMenu then PikiMenu:Close() end return end
	if PikiMenu then return end
	if args[1] == "2" and LocalPlayer():GetNWBool("ispikmin") then return end
	if not LocalPlayer():Alive() then return end
	local w, h = surface.ScreenWidth(), surface.ScreenHeight()
	local frame = vgui.Create("DFrame")
	
	local MenuType = tonumber(args[1]) or 0
	
	if MenuType == 3 then
		frame:SetSize((w * .4), (h * .275))
	else
		frame:SetSize((w * .7), (h * .275))
	end
	
	PikiMenu = frame
	
	local W = frame:GetWide();
	local H = frame:GetTall();
	
	function frame:OnClose()
		PikiMenu = nil
		gui.EnableScreenClicker(false)
	end
	frame:SetPos(((w * .5) - (W * .5)), (h * .125));
	frame:SetVisible(true);
	
	frame:SetTitle("#pikispawn")
	if MenuType ~= 0 then frame:SetTitle("#pikispawn"..MenuType) end
	
	if MenuType <= 2 then
		local piktbl = {
			"red",
			"yellow",
			"blue",
			"purple",
			"white",
		}
		
		local inc = 0;
		
		for i = 1, #piktbl do //lets do this neatly...
			local btn = vgui.Create("DModelPanel", frame);
			btn:SetPos(((W * .05) + inc), (H * .2));
			btn:SetWide((W * .175));
			btn:SetTall((H * .55));
			btn:SetModel("models/pikmin/pikmin_" ..  piktbl[i] .. "1.mdl");
			btn:SetLookAt(Vector(0, 0, 25));
			btn:SetFOV(56);
			btn:SetAmbientLight(Color(80, 80, 80));
			btn:SetCamPos(Vector(60, 15, 40));
			btn:SetAnimSpeed(math.Rand(.9, 1.2));
			btn:SetAnimated(true);
			btn.Entity:ResetSequence(btn.Entity:LookupSequence("dismissed"));
			function btn:LayoutEntity(ent)
				self:RunAnimation();
			end
			function btn:DoClick()
				if MenuType == 1 then
					RunConsoleCommand("pikmin_create","2",piktbl[i])
				elseif MenuType == 2 then
					RunConsoleCommand("pikmin_player",piktbl[i])
				else
					RunConsoleCommand("pikmin_create",piktbl[i])
				end
				if MenuType == 2 then frame:Close() end
			end
			inc = (inc + (28 + (w * .1)));
		end
		
		local rand = vgui.Create("DButton", frame);
		rand:SetPos((W * .1), (H * .8));
		rand:SetWide((W * .8));
		rand:SetTall((H * .1));
		rand:SetText("#pikirand");
		rand.DoClick = function()
			if MenuType == 1 then
				RunConsoleCommand("pikmin_create","2","random")
			elseif MenuType == 2 then
				RunConsoleCommand("pikmin_player","random")
			else
				RunConsoleCommand("pikmin_create","random")
			end
			if MenuType == 2 then frame:Close() end
		end
	elseif MenuType == 3 then
		local onionExist = {}
		for _,v in ipairs(ents.FindByClass("pikmin_onion")) do
			onionExist[v:GetSkin()] = true
		end
		local inc = 0
		for i = 1,3 do
			if not onionExist[3-i] then
				local btn = vgui.Create("DModelPanel", frame);
				btn:SetPos(((W * .05) + inc), (H * .2))
				btn:SetWide((W * .35))
				btn:SetTall((H * .7))
				btn:SetModel("models/pikmin/onion.mdl")
				btn.Entity:SetSkin(3-i)
				btn:SetLookAt(Vector(0, 0, 25))
				btn:SetFOV(56)
				btn:SetAmbientLight(Color(80, 80, 80))
				btn:SetCamPos(Vector(500, 15, 500))
				btn:SetAnimSpeed(math.Rand(.9, 1.2))
				btn:SetAnimated(true)
				btn.Entity:ResetSequence(1)
				function btn:LayoutEntity(ent)
					self:RunAnimation();
				end
				function btn:DoClick()
					RunConsoleCommand("pikmin_create","3",3-i)
					frame:Close()
				end
			end
			inc = (inc + (24 + (w * .1)))
		end
	elseif MenuType == 4 then
		local inc = 0
		for i = 1,5 do
			local btn = vgui.Create("DModelPanel", frame);
			btn:SetPos(inc, (H * .2))
			btn:SetWide((W * .2))
			btn:SetTall((H * .7))
			btn:SetModel("models/pikmin/pom.mdl")
			btn.Entity:SetSkin(i-1)
			btn:SetLookAt(Vector(0, 0, 25))
			btn:SetFOV(56)
			btn:SetAmbientLight(Color(80, 80, 80))
			btn:SetCamPos(Vector(140, 15, 140))
			btn:SetAnimSpeed(math.Rand(.9, 1.2))
			btn:SetAnimated(true)
			btn.Entity:ResetSequence(1)
			function btn:LayoutEntity(ent) self:RunAnimation() end
			function btn:DoClick() RunConsoleCommand("pikmin_create","4",i) end
			inc = inc + W*.2
		end
	end
	
	frame:SizeToContents()
	gui.EnableScreenClicker(true)
end
concommand.Add("pikmin_menu", SpawnPikminMenu)


hook.Add("AddToolMenuCategories","PikiToolMenuCat",function()
	spawnmenu.AddToolCategory("Utilities","Pikmin","#pikmin")
end)

--//ConVar Override (sv_pikhealth/sv_pikdamage)
RealGetConVar = RealGetConVar or GetConVar
PikConVarCache = PikConVarCache or {}

--//PikConVarWrapper("sv_pikhealth",1)
local function PikConVarWrapper(name)
	local numStart = string.find(name,"%d+")
	local sourceName = string.sub(name,1,numStart-1)
	local SourceVar = RealGetConVar(sourceName)
	local TypeNumber = tonumber(string.sub(name,numStart))
	
	local convar = {}
	
	function convar:GetBool() return false end
	
	function convar:GetDefault() return end
	
	function convar:GetFlags() return SourceVar:GetFlags() end
	
	function convar:GetFloat() return tonumber(convar:GetString()) end
	
	function convar:GetHelpText() return SourceVar:GetHelpText() end
	
	function convar:GetInt() return math.floor(convar:GetFloat()) end
	
	function convar:GetMax() return end
	
	function convar:GetMin() return end
	
	function convar:GetName() return name end
	
	function convar:GetString()
		local values = string.Split(SourceVar:GetString()," ")
		return values[TypeNumber]
	end
	
	function convar:IsFlagSet(...) return SourceVar:IsFlagSet(...) end
	
	convar.MetaName = "ConVar"
	
	function convar:Revert() return end
	
	function convar:SetBool(value) return end
	
	function convar:SetFloat(value) RunConsoleCommand(sourceName,TypeNumber,value) end
	
	function convar:SetInt(value) RunConsoleCommand(sourceName,TypeNumber,value) end
	
	function convar:SetString(value) RunConsoleCommand(sourceName,TypeNumber,value) end
	
	convar.__index = convar
	convar.__tostring = function() return string.format("ConVar [%s]",name) end
	
	return setmetatable({},convar)
end

function GetConVar(name)
	if string.find(name,"sv_pikhealth") or string.find(name,"sv_pikdamage") then
		local cvar = PikConVarCache[name]
		if not cvar then
			cvar = PikConVarWrapper(name)
			PikConVarCache[name] = cvar
		end
		return cvar
	end
	return RealGetConVar(name)
end

--//Derma RunConsoleCommand Override
REAL_RunConsoleCommand = REAL_RunConsoleCommand or RunConsoleCommand
local cmd = REAL_RunConsoleCommand
RunConsoleCommand = function(...)
	local name,value = ...
	if string.find(name,"sv_pikhealth") or string.find(name,"sv_pikdamage") then
		local numStart = string.find(name,"%d+")
		cmd(string.sub(name,1,numStart-1),string.sub(name,numStart).." "..value)
		return
	end
	cmd(...)
end

--//Spawn Menu
hook.Add("PopulateToolMenu","PikiToolMenu",function()
	spawnmenu.AddToolMenuOption("Utilities","Pikmin","PikiSettings","#pikimenu.settings","","",function(panel)
		panel:Help("#pikimenu.general"):SetFont("DermaLarge")
		
		local n = panel:NumSlider("#pikimenu.max","sv_pikfield",0,200,0)
		n:SetDefaultValue(PIKMIN_MAXFIELD)
		panel:ControlHelp("#pikimenu.max2")
		
		panel:CheckBox("#pikimenu.touch","sv_piktouch")
		panel:ControlHelp("#pikimenu.touch2")
		
		panel:CheckBox("#pikimenu.think","sv_pikthink")
		panel:ControlHelp("#pikimenu.think")
		
		panel:CheckBox("#pikimenu.shadow","sv_pikshadow")
		panel:CheckBox("#pikimenu.drops","sv_pikdrops")
		
		local htab,dtab = {},{}
		
		panel:Help("#pikimenu.health"):SetFont("DermaLarge")
		
		for i=1,#PIKMIN_COLMDL do
			local n = panel:NumSlider("#pikmin"..i,"sv_pikhealth"..i,1,100,0)
			n:SetDefaultValue(PIKMIN_HEALTH[i])
			table.insert(htab,n)
		end
		
		panel:Help("#pikimenu.damage"):SetFont("DermaLarge")
		for i=1,#PIKMIN_COLMDL do
			local n = panel:NumSlider("#pikmin"..i,"sv_pikdamage"..i,0,40,0)
			n:SetDefaultValue(PIKMIN_DAMAGE[i])
			n:SetValue(10)
			table.insert(dtab,n)
		end
		
		local btn = panel:Button("#pikimenu.reset","")
		function btn:DoClick()
			for i=1,#PIKMIN_COLMDL do
				htab[i]:SetValue(PIKMIN_HEALTH[i])
				dtab[i]:SetValue(PIKMIN_DAMAGE[i])
			end
			n:SetValue(PIKMIN_MAXFIELD)
		end
		
		local btn = panel:Button("#pikimenu.reset2","pikmin_oreset")
	end)
end)

--//Context Menu
hook.Add("PopulateMenuBar","PikiContext",function(bar)
	local menu = bar:AddOrGetMenu("#pikmin")
	
	local skinMenu,skinOption = menu:AddSubMenu("#pikicontext.skin")
	skinMenu:SetDeleteSelf(false)
	
	for i=0,5 do
		local skinOption = skinMenu:AddOption("#pikicontext.skin"..i+1,function() RunConsoleCommand("cl_pikminskin",tostring(i)) end)
		local optionPaint = skinOption.Paint
		function skinOption:Paint(w,h)
			skinOption:SetChecked(cvars.Number("cl_pikminskin",0) == i)
			optionPaint(skinOption,w,h)
		end
	end
	
	local whistleMenu,whistleOption = menu:AddSubMenu("#pikicontext.whistle")
	whistleMenu:SetDeleteSelf(false)
	
	for i=0,3 do
		local option = whistleMenu:AddOption("#pikicontext.whistle"..i+1,function() RunConsoleCommand("cl_pikwhistle",tostring(i)) end)
		local optionPaint = option.Paint
		function option:Paint(w,h)
			option:SetChecked(cvars.Number("cl_pikwhistle",0) == i)
			optionPaint(option,w,h)
		end
	end
	
	menu:AddSpacer()
	
	local option = nil
	option = menu:AddOption("#pikicontext.dismiss", function()
		RunConsoleCommand("pikmin_upgrade","1",LocalPlayer():GetNWBool("pikidis",false) and "0" or "1")
	end)
	local optionPaint = option.Paint
	function option:Paint(w,h)
		option:SetChecked(LocalPlayer():GetNWBool("pikidis",false))
		optionPaint(option,w,h)
	end
	
	local option2 = nil
	option2 = menu:AddOption("#pikicontext.hide", function()
		RunConsoleCommand("pikmin_upgrade","2",LocalPlayer():GetNWBool("piknd",false) and "0" or "1")
	end)
	local optionPaint = option2.Paint
	function option2:Paint(w,h)
		option2:SetChecked(LocalPlayer():GetNWBool("piknd",false))
		optionPaint(option2,w,h)
	end
	
	local option3 = nil
	option3 = menu:AddOption("#pikicontext.hud", function()
		RunConsoleCommand("cl_pikminhud",cvars.Bool("cl_pikminhud") and "0" or "1")
	end)
	local optionPaint = option3.Paint
	function option3:Paint(w,h)
		option3:SetChecked(not cvars.Bool("cl_pikminhud"))
		optionPaint(option3,w,h)
	end
	
	menu:AddSpacer()
	
	local upgradeMenu,upgradeOption = menu:AddSubMenu("#pikicontext.upgrades")
	upgradeMenu:SetDeleteSelf(false)
	
	local option3 = nil
	option3 = upgradeMenu:AddOption("#pikiupgrade.pluck", function()
		RunConsoleCommand("pikmin_upgrade","3",LocalPlayer():GetNWBool("pikipluck",false) and "0" or "1")
	end)
	local optionPaint = option3.Paint
	function option3:Paint(w,h)
		option3:SetChecked(LocalPlayer():GetNWBool("pikipluck",false))
		optionPaint(option3,w,h)
	end
	
	local option4 = nil
	option4 = upgradeMenu:AddOption("#pikiupgrade.fire", function()
		RunConsoleCommand("pikmin_upgrade","4",LocalPlayer():GetNWBool("pikfire",false) and "0" or "1")
	end)
	local optionPaint = option4.Paint
	function option4:Paint(w,h)
		option4:SetChecked(LocalPlayer():GetNWBool("pikfire",false))
		optionPaint(option4,w,h)
	end
	
	local option5 = nil
	option5 = upgradeMenu:AddOption("#pikiupgrade.zap", function()
		RunConsoleCommand("pikmin_upgrade","5",LocalPlayer():GetNWBool("pikzap",false) and "0" or "1")
	end)
	local optionPaint = option5.Paint
	function option5:Paint(w,h)
		option5:SetChecked(LocalPlayer():GetNWBool("pikzap",false))
		optionPaint(option5,w,h)
	end
end)

--//hacky fix for entity list
if not PikiLayoutFixed then
	PikiLayout = nil
	PikiLayoutFixed = false
	PikiBaseEntSwitchPanelFun = nil
	local function CreateContentIconWrapper(data,name,panel)
		data = data[name]
		spawnmenu.CreateContentIcon( data.ScriptedEntityType or "entity", panel, {
			nicename	= data.PrintName or data.ClassName,
			spawnname	= name,
			material	= data.IconOverride or "entities/" .. name .. ".png",
			admin		= data.AdminOnly
		})
	end
	local function FixPikiEntList(pnlContent)
		if IsValid(pnlContent.SelectedPanel) then
			local layout = pnlContent.SelectedPanel:GetChild(0):GetChild(0)
			if not PikiLayout then
				local child = layout:GetChildren()
				for k,v in ipairs(child) do
					if v:GetSpawnName() == "pikmin" then PikiLayout = layout break end
				end
				if layout == PikiLayout then for k,v in ipairs(child) do v:Remove() end end
			end
			if PikiLayout and layout == PikiLayout then
				PikiLayoutFixed = true
				hook.Remove("SpawnMenuOpen","PikiSpawnMenuOpen")
				local ents = list.Get("SpawnableEntities")
				CreateContentIconWrapper(ents,"pikmin",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_sprout",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_player",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_onion",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_bud",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_nectar",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_fire",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_gas",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"pikmin_wire",pnlContent.SelectedPanel)
				CreateContentIconWrapper(ents,"bulbmin",pnlContent.SelectedPanel)
			end
		end
	end
	hook.Add("SpawnMenuOpen","PikiSpawnMenuOpen",function()
		if not g_SpawnMenu then return end
		local entPanel = nil
		for k,v in ipairs(g_SpawnMenu.CreateMenu.Items) do
			if v.Name == "#spawnmenu.category.entities" then
				entPanel = v.Panel
				break
			end
		end
		if entPanel then
			local pnlContent = entPanel:Find("SpawnmenuContentPanel")
			if not PikiLayoutFixed then FixPikiEntList(pnlContent) end
			pnlContent.SwitchPanel = function(self,panel)
				if ( IsValid( self.SelectedPanel ) ) then
					self.SelectedPanel:SetVisible( false )
					self.SelectedPanel = nil
				end

				self.SelectedPanel = panel

				if ( !IsValid( panel ) ) then return end
				if not PikiLayoutFixed then FixPikiEntList(self) end

				self.HorizontalDivider:SetRight( self.SelectedPanel )
				self.HorizontalDivider:InvalidateLayout( true )

				self.SelectedPanel:SetVisible( true )
				self:InvalidateParent()
			end
		end
	end)
end


spawnmenu.AddPropCategory("pikmin","#pikmin",{
{
type = "model",
model = "models/pikmin/pikmin_red1.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_red2.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_red3.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_yellow1.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_yellow2.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_yellow3.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_blue1.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_blue2.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_blue3.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_purple1.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_purple2.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_purple3.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_white1.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_white2.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_white3.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_bulbmin1.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_bulbmin2.mdl",
},
{
type = "model",
model = "models/pikmin/pikmin_bulbmin3.mdl",
},
{
type = "model",
model = "models/weapons/w_olimar.mdl",
},
{
type = "model",
model = "models/pikmin/onion.mdl",
skin = 2
},
{
type = "model",
model = "models/pikmin/pellet_1.mdl",
skin = 2
},
{
type = "model",
model = "models/pikmin/pellet_5.mdl",
skin = 2
},
{
type = "model",
model = "models/pikmin/pellet_10.mdl",
skin = 2
},
{
type = "model",
model = "models/pikmin/pellet_20.mdl",
skin = 2
},
{
type = "model",
model = "models/pikmin/pom.mdl",
skin = 0
},
{
type = "model",
model = "models/player/orima_r.mdl",
skin = 0
},
{
type = "model",
model = "models/player/louie_r.mdl",
skin = 0
},
{
type = "model",
model = "models/player/chacho_r.mdl",
skin = 0
},
}, "icons/flower.png")