--//Physics Fix
--sv_crazyphysics_defuse 0
--sv_crazyphysics_remove 0
--sv_crazyphysics_warning 0

--//Collision Models
PIKMIN_PHYMDL = {
"models/pikmin/pikmin_collision.mdl",
"models/pikmin/pikmin_collision.mdl",
"models/pikmin/pikmin_collision.mdl",
"models/pikmin/pikmin_collisionp.mdl",
"models/pikmin/pikmin_collisionw.mdl",
"models/pikmin/pikmin_collision.mdl",
}

--//Display Models
PIKMIN_COLMDL = {
"models/pikmin/pikmin_red%s.mdl",
"models/pikmin/pikmin_yellow%s.mdl",
"models/pikmin/pikmin_blue%s.mdl",
"models/pikmin/pikmin_purple%s.mdl",
"models/pikmin/pikmin_white%s.mdl",
"models/pikmin/pikmin_bulbmin%s.mdl",
}

--//not in the real game (pikmin have no health)
PIKMIN_HEALTH = {
24,
18,
28,
40,
12,
18
}

--//reds do 1.5x damage
PIKMIN_DAMAGE = {
15,
10,
10,
20,
10,
10,
}

--//convert damage values to something more appropriate
PIKMIN_DAMAGE_MULT = 0.1

--//colors for death effects
PIKMIN_SOUL_COLORS = {
Vector(255,10,10),
Vector(255,255,10),
Vector(10,10,255),
Vector(150,10,150),
Vector(250,250,250),
Vector(255,255,255)
}

--//colors for flower effects
PIKMIN_FLOWER_COLORS = {
Vector(255, 255, 255),
Vector(255, 255, 255),
Vector(255, 255, 255),
Vector(220, 100, 150),
Vector(220, 100, 150),
Vector(255, 255, 255),
}

--//colors for disband effects
PIKMIN_DISBAND_COLORS = {
Color(255, 150, 150, 200),
Color(255, 255, 150, 200),
Color(150, 150, 255, 200),
Color(225, 150, 225, 200),
Color(255, 255, 255, 200),
Color(0,255,0,200),
}

--//base shadow parameters for physics
PIKMIN_SHADOW_PARAMS = {
	secondstoarrive = .2,
	maxangular = 5000,
	maxangulardamp = 10000,
	maxspeed = 0,
	maxspeeddamp = 0,
	dampfactor = 0.8,
	teleportdistance = 0,
}

--props that can be carried to any available onion
PikiCarryOnionList = {
"models/pikmin/pellet_1.mdl",
"models/pikmin/pellet_5.mdl",
"models/pikmin/pellet_10.mdl",
"models/pikmin/pellet_20.mdl"
}

--(MinWeight,MaxPiki)
PikiCarryDict = {
["models/pikmin/pellet_1.mdl"] = {1,2},
["models/pikmin/pellet_5.mdl"] = {5,10},
["models/pikmin/pellet_10.mdl"] = {10,20},
["models/pikmin/pellet_20.mdl"] = {20,40},
}

PikiFueDict = {
["models/pikmin/pellet_1.mdl"] = 1,
["models/pikmin/pellet_5.mdl"] = 5,
["models/pikmin/pellet_10.mdl"] = 10,
["models/pikmin/pellet_20.mdl"] = 20,
}

--multiply the count by 2 based on matching skin
PikiFueSDict = {
["models/pikmin/pellet_1.mdl"] = true,
["models/pikmin/pellet_5.mdl"] = true,
["models/pikmin/pellet_10.mdl"] = true,
["models/pikmin/pellet_20.mdl"] = true,
}

local CryBurn = {
"pikmin/burn1.wav",
"pikmin/burn2.wav",
"pikmin/burn3.wav",
"pikmin/burn4.wav",
}

local CryGas = {
"pikmin/poison1.wav",
"pikmin/poison2.wav",
"pikmin/poison3.wav",
}

PIKMIN_SOUND_CRY = {true,CryBurn,CryGas,true}

--//pikmin spawn limit
PIKMIN_MAXFIELD = 100

--//pikmin collide with eachother
PIKMIN_AUTO_COLLIDE = true

--//pikmin think on their own
PIKMIN_AUTO_THINK = true

--//enemies drop pellets
PIKMIN_TEKI_DROPS = true

--//draw pikmin shadows
PIKMIN_DRAW_SHADOW = false

--//draw weapon hud
PIKMIN_DRAW_HUD = true

--//materials
PIKMIN_DISBAND_LIGHT = Material("pikmin/disband_light")
PIKMIN_POISON_MAT = Material("particles/smokey")

--//captains
PIKMIN_CAPTAIN_MODELS = {"models/player/orima.mdl","models/player/louie.mdl","models/player/chacho.mdl"}

--//hazard enums
HAZARD_WATER = 1
HAZARD_FIRE = 2
HAZARD_POISON = 3
HAZARD_SHOCK = 4

--//convars
local CVAR_PIKHEALTH = CreateConVar("sv_pikhealth",table.concat(PIKMIN_HEALTH," "),{FCVAR_REPLICATED},"")
local CVAR_PIKDAMAGE = CreateConVar("sv_pikdamage",table.concat(PIKMIN_DAMAGE," "),{FCVAR_REPLICATED},"")
CreateConVar("sv_pikfield",PIKMIN_MAXFIELD,{FCVAR_REPLICATED},"")
CreateConVar("sv_pikshadow",PIKMIN_DRAW_SHADOW and 1 or 0,{FCVAR_REPLICATED},"")
CreateConVar("sv_pikdrops",PIKMIN_TEKI_DROPS and 1 or 0,{FCVAR_REPLICATED},"")
CreateConVar("sv_pikthink",PIKMIN_AUTO_THINK and 1 or 0,{FCVAR_REPLICATED,FCVAR_NOTIFY},"")
CreateConVar("sv_piktouch",PIKMIN_AUTO_COLLIDE and 1 or 0,{FCVAR_REPLICATED,FCVAR_NOTIFY},"")

if CLIENT then
	CreateClientConVar("cl_pikminskin","0",true,true,"",0,5)
	CreateClientConVar("cl_pikminhud","1",true,true,"",0,1)
	CreateClientConVar("cl_pikwhistle","0",true,true,"",0,3)
	cvars.AddChangeCallback("cl_pikminhud",function(name,ov,nv) PIKMIN_DRAW_HUD = nv == "1" and true or false end)
	local function NetWeaponUpdate()
		net.Start("pikmin_skin")
		net.SendToServer()
	end
	cvars.AddChangeCallback("cl_pikminskin",NetWeaponUpdate)
	cvars.AddChangeCallback("cl_pikwhistle",NetWeaponUpdate)
end

if SERVER then
	cvars.AddChangeCallback("sv_pikhealth", function(name,ov,nv)
		local values = string.Split(nv," ")
		if #values ~= #PIKMIN_HEALTH then
			if #values == 2 then
				local index = math.Clamp(math.floor(tonumber(values[1]) or 0),1,#PIKMIN_HEALTH)
				PIKMIN_HEALTH[index] = tonumber(values[2]) or PIKMIN_HEALTH[index]
			end
			CVAR_PIKHEALTH:SetString(table.concat(PIKMIN_HEALTH," "))
			return
		end
		for k,v in ipairs(values) do
			PIKMIN_HEALTH[k] = tonumber(v) or PIKMIN_HEALTH[k]
		end
		for _,v in ipairs(ents.FindByClass("pikmin")) do
			local number = PIKMIN_HEALTH[v.Color]
			if v.PikHP >= number then v.PikHP = number end
		end
	end)
	
	cvars.AddChangeCallback("sv_pikdamage", function(name,ov,nv)
		local values = string.Split(nv," ")
		if #values ~= #PIKMIN_DAMAGE then
			if #values == 2 then
				local index = math.Clamp(math.floor(tonumber(values[1]) or 0),1,#PIKMIN_DAMAGE)
				PIKMIN_DAMAGE[index] = tonumber(values[2]) or PIKMIN_DAMAGE[index]
			end
			CVAR_PIKDAMAGE:SetString(table.concat(PIKMIN_DAMAGE," "))
			return
		end
		for k,v in ipairs(values) do
			PIKMIN_DAMAGE[k] = tonumber(v) or PIKMIN_DAMAGE[k]
		end
		for _,v in ipairs(ents.FindByClass("pikmin")) do
			v.Damage = PIKMIN_DAMAGE[v.Color]*PIKMIN_DAMAGE_MULT
		end
	end)
	
	cvars.AddChangeCallback("sv_pikfield", function(name,ov,nv) PIKMIN_MAXFIELD = math.Clamp(math.floor(tonumber(nv) or 0),0,200) end)
	cvars.AddChangeCallback("sv_pikthink", function(name,ov,nv) PIKMIN_AUTO_THINK = nv == "1" and true or false end)
	cvars.AddChangeCallback("sv_piktouch", function(name,ov,nv) PIKMIN_AUTO_COLLIDE = nv == "1" and true or false end)
	cvars.AddChangeCallback("sv_pikdrops", function(name,ov,nv) PIKMIN_TEKI_DROPS = nv == "1" and true or false end)
	
	cvars.AddChangeCallback("sv_pikshadow", function(name,ov,nv)
		PIKMIN_DRAW_SHADOW = nv == "1" and true or false
		--for _,v in ipairs(ents.FindByClass("pikmin_model")) do v:DrawShadow(PIKMIN_DRAW_SHADOW) end
	end)
end

--//determines interactable objects
function CanPikminCharge(target)
	local class = target:GetClass()
	if target:IsNPC() and class ~= "pikmin_model" or target:IsPlayer() then
		if target:Health() <= 0 then return false end
		return true
	end
	if class == "pikmin_nectar" then return true end
	if class == "pikmin_fire" or class == "pikmin_gas" or class == "pikmin_wire" then return target:Health() > 0 end
	--[[
	local class = target:GetClass()
		if class == "pikmin" or class == "pikmin_onion" or class == "pikmin_model" or class == "prop_ragdoll" or class == "pikmin_sprout" or class == "pikmin_bud" then return end
		if class == "prop_physics" and not (table.KeyFromValue(PikiCarryOnionList,target:GetModel()) or target.IsCarry) then return end
		if (class == "pikmin_fire" or class == "pikmin_gas" or class == "pikmin_wire") and target:Health() <= 0 then return end
		if string.sub(class,1,4) == "func" and class ~= "func_breakable" then return end
		if target.IsCarry and target:GetNWInt("pikimax") ~= 0 and target:GetNWInt("piki") >= target:GetNWInt("pikimax") then return end
	--]]
	return false
end

--//determines latchable objects
function CanPikminGrab(target)
	if target:IsNPC() or target:IsPlayer() then return true end
	local class = target:GetClass()
	if class == "pikmin_fire" or class == "pikmin_gas" or class == "pikmin_wire" then return target:Health() > 0 end
	return false
end

--//load special scripts for non-pikmin gamemodes
if SERVER then
	function IncludeNonPikminGamemode(gamemode)
		local name = gamemode .. "/pik_shared.lua"
		if file.Exists(name,"LUA") then AddCSLuaFile(name) include(name) end
		local name = gamemode .. "/pik_client.lua"
		if file.Exists(name,"LUA") then AddCSLuaFile(name) end
		local name = gamemode .. "/pik_server.lua"
		if file.Exists(name,"LUA") then include(name) end
	end
elseif CLIENT then
	function IncludeNonPikminGamemode(gamemode)
		local name = gamemode .. "/pik_shared.lua"
		if file.Exists(name,"LUA") then include(name) end
		local name = gamemode .. "/pik_client.lua"
		if file.Exists(name,"LUA") then include(name) end
	end
end

--//hook to load the scripts
hook.Add("PreGamemodeLoaded","PikiGMPreLoad",function()
	IncludeNonPikminGamemode(GAMEMODE.FolderName)
end)

--//prevent property editing
--//sadly wont stop the context menu halo effect from PreDrawHalos
hook.Add("CanProperty","PikiProperty",function(ply,prop,ent)
	if ent:GetClass() == "pikmin" or ent:GetClass() == "pikmin_model" then return false end
	if ent:GetNWBool("pkrg",false) then return false end
	return GAMEMODE:CanProperty(ply,prop,ent)
end)

--//Playermodels
player_manager.AddValidModel("Olimar","models/player/orima.mdl")
player_manager.AddValidModel("Louie","models/player/louie.mdl")
player_manager.AddValidModel("The President","models/player/chacho.mdl")