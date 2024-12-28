local PluckSound = "pikmin/pikmin_pluck.wav"

--//Helper Function
local function NameToColor(name)
	local color = 1
	if name == "red" then color = 1
	elseif name == "yellow" then color = 2
	elseif name == "blue" then color = 3
	elseif name == "purple" then color = 4
	elseif name == "white" then color = 5
	elseif name == "bulbmin" then color = 6
	elseif name == "random" then color = math.random(1,5)
	end
	return color
end

--//Helper Function
local function NameToLevel(name)
	local level = 1
	if name == "bud" then
		level = 2
	elseif name == "flower" then
		level = 3
	end
	return level
end

--//Base Pikmin
function PikminCreate(ply,cmd,args)
	if #ents.FindByClass("pikmin")+#ents.FindByClass("pikmin_sprout") >= PIKMIN_MAXFIELD then return end
	if not args[1] then return end
	local color = NameToColor(args[1])
	
	local ent = ents.Create("pikmin")
	ent.Level = NameToLevel(args[2])
	
	ent.Leader = ply
	ent.Color = color
	ent:SetPos(ply:GetPos() + ply:GetForward() * -32 + ply:GetRight() * math.Rand(-50, 50) + vector_up*30)
	ent:EmitSound(PluckSound)
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikminf"..ent.Color)
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()
end

--//Pikmin Sprouts
function PikminCreateSprout(ply,cmd,args)
	if #ents.FindByClass("pikmin")+#ents.FindByClass("pikmin_sprout") >= PIKMIN_MAXFIELD then return end
	local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 10000, ents.GetAll())
	if not (tr.Hit and tr.HitPos) then return end
	if not args[1] then return end
	local color = NameToColor(args[1])
	
	local ent = ents.Create("pikmin_sprout")
	ent.Color = color
	ent.Planted = true
	ent:SetPos(tr.HitPos + tr.HitNormal*-12)
	local angle = (ent:GetPos()-ply:GetPos()):Angle()
	ent:SetAngles(Angle(0,angle.Y,0))
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikminf"..ent.Color)
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()
end

--//Playable Pikmin
function PikminPlayerFunc(ply,cmd,args)
	if #ents.FindByClass("pikmin")+#ents.FindByClass("pikmin_sprout") >= PIKMIN_MAXFIELD then return end
	if not args[1] then return end
	local color = NameToColor(args[1])
	
	local ent = ents.Create("pikmin_player")
	ent.Level = NameToLevel(args[2])
	
	ent.Leader = ply
	ent.Color = color
	ent:EmitSound(PluckSound)
	ent:Spawn()
	ent:Activate()
end

--//Onions
function PikminCreateOnion(ply,cmd,args)
	local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 10000, ply)
	if not (tr.Hit and tr.HitPos) then return end
	if not args[1] then return end
	local num = tonumber(args[1])
	if not num then return end
	for _,v in ipairs(ents.FindByClass("pikmin_onion")) do
		if v.Skin == num then return end
	end
	local ent = ents.Create("pikmin_onion")
	ent.Skin = math.Clamp(num,0,2)
	ent:SetPos(tr.HitPos + tr.HitNormal * 30)
	local angle = (ply:GetPos()-ent:GetPos()):Angle()
	ent:SetAngles(Angle(0,angle.Y,0))
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikmin_onion"..num)
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()
end

--//Candypop Buds
function PikminCreateBud(ply,cmd,args)
	local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 10000, ents.GetAll())
	if not (tr.Hit and tr.HitPos) then return end
	local ent = ents.Create("pikmin_bud")
	ent.Color = tonumber(args[1]) or 1
	ent:SetPos(tr.HitPos)
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikmin_bud")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
end

--//Onion Call
local function PikminCallFunc(ply,cmd,args)
	local tr = util.QuickTrace(ply:GetShootPos(), (ply:GetAimVector() * 500), ply)
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "pikmin_onion" then
		tr.Entity:Call(ply,tonumber(args[1]) or 0,tonumber(args[2]) or 0)
	end
end

--//Weapon Config
local ConfigLUT = {"pikidis","piknd","pikipluck","pikfire","pikzap"}
local function PikiUpgradeFunc(ply,cmd,args)
	if not args[1] or not args[2] then return end
	local num = tonumber(args[1])
	if not num then return end
	ply:SetNWBool(ConfigLUT[num],args[2] == "1" and true or false)
end

--//Clear Onion Data
local function PikiOnionReset(ply,cmd,args)
	SetPikiOnionData(0,{})
	SetPikiOnionData(1,{})
	SetPikiOnionData(2,{})
	for _,v in ipairs(ents.FindByClass("pikmin_onion")) do
		v.PikiList = PIKIONIONDATA[v.Skin] and table.Copy(PIKIONIONDATA[v.Skin])
	end
end

local function PikminCreator(ply,cmd,args)
	if not args[1] then return end
	local CreateType = tonumber(args[1])
	if not CreateType then
		CreateType = 1
	else
		table.remove(args,1)
	end
	if CreateType == 1 then
		PikminCreate(ply,cmd,args)
	elseif CreateType == 2 then
		PikminCreateSprout(ply,cmd,args)
	elseif CreateType == 3 then
		PikminCreateOnion(ply,cmd,args)
	elseif CreateType == 4 then
		PikminCreateBud(ply,cmd,args)
	end
end

--//Console Commands
concommand.Add("pikmin_create",PikminCreator)
concommand.Add("pikmin_player",PikminPlayerFunc)
concommand.Add("pikmin_call",PikminCallFunc)
concommand.Add("pikmin_upgrade",PikiUpgradeFunc)
concommand.Add("pikmin_oreset",PikiOnionReset)

--//Hack to fix duplicator/save stack overflow
--//this may become obsolete with new carrying code
--//(https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/duplicator.lua)
local CachedDuplicatorFunction = duplicator.GetAllConstrainedEntitiesAndConstraints
duplicator.GetAllConstrainedEntitiesAndConstraints = function(ent,EntTable,ConstraintTable)
	if ( !IsValid( ent ) && !ent:IsWorld() ) then return end
	
	if ent:GetClass() == "pikmin" then
		EntTable[ent:EntIndex()] = ent
		return EntTable,ConstraintTable
	end
	
	CachedDuplicatorFunction(ent,EntTable,ConstraintTable)
	
	return EntTable, ConstraintTable
end

local EntDrops = {
	{"models/pikmin/pellet_1.mdl"},
	{"models/pikmin/pellet_5.mdl"},
	{"models/pikmin/pellet_10.mdl"},
}

local function PikiDropSandbox(ent,dmg,took)
	if not PIKMIN_TEKI_DROPS then return end
	if not took then return end
	if not ent.PikDrops and ent:IsNPC() and ent:Health() <= 0 and IsValid(dmg:GetInflictor()) and dmg:GetInflictor().PikMdl then
		ent.PikDrops = true
		if ent:GetClass() == "npc_antlion" then if math.random(1,8) <= 4 then return end ent.PikDropName = "models/pikmin/pellet_1.mdl" end
		if ent:GetClass() == "npc_dog" then if math.random(1,8) <= 4 then return end ent.PikDropName = "models/pikmin/pellet_5.mdl" end
		local drop = ent.PikDropName
		if not drop then
			if ent:GetMaxHealth() <= 35 or math.random(1,8) <= 4 then return end
			local rng = ent:GetMaxHealth()+math.random(0,20)
			rng = math.ceil(rng/8)/60
			local dropTable = EntDrops[math.Clamp(math.floor(rng*3),1,3)]
			drop = dropTable[math.random(#dropTable)]
		end
		local dropEnt = ents.Create("prop_physics")
		dropEnt:SetModel(drop)
		dropEnt:SetPos(ent:WorldSpaceCenter()+Vector(0,0,10))
		dropEnt:SetAngles(Angle(math.random(-15,15),math.random(-90,90),math.random(-15,15)))
		dropEnt:SetSkin(math.random(dropEnt:SkinCount())-1)
		dropEnt:Spawn()
		dropEnt:Activate()
		dropEnt:EmitSound("pikmin/discover.wav")
	end
end

hook.Add("PostEntityTakeDamage","PikiDropSandbox",PikiDropSandbox)

--0.4 fadebias for morning sky
--Sunset Vector (0,-1,0)
--X axis is forward in GMod

--make pik_mapinfo class to manage variables for gamemode related things
--such as: level name, sky properties, etc

--also make class for end of day camera position (small custom background area to be seen when lifting off; wouldn't be required)

--[[hook.Add("InitPostEntity","SkyInit",function()
	local sky = ents.FindByClass("env_skypaint")[1]
	if not sky then
		sky = ents.Create("env_skypaint")
		sky:Spawn()
		timer.Simple(1,function() RunConsoleCommand("sv_skyname","painted") end)
	end
	local sun = ents.FindByClass("env_sun")[1]
	if sun then sun:Remove() end
	sky:SetKeyValue("topcolor","0 0 0.01 0")
	sky:SetKeyValue("bottomcolor","0 0 0 0")
	sky:SetKeyValue("fadebias","0")
	sky:SetKeyValue("duskintensity","0")
	sky:SetKeyValue("sunsize","0")
	sky:SetKeyValue("starfade","1")
	sky:SetKeyValue("starlayers","1")
	sky:SetKeyValue("starscale","2")
	sky:SetKeyValue("starspeed","0.01")
	sky:SetKeyValue("hdrscale","0.1")
	sky:SetKeyValue("drawstars","Yes")
	sky:SetKeyValue("startexture","skybox/starfield")
	engine.LightStyle(0,"a")
	timer.Simple(0.1,function() BroadcastLua("render.RedownloadAllLightmaps()") end)
end)--]]
