AddCSLuaFile("pikmin_shared.lua")
AddCSLuaFile("pikmin_client.lua")
AddCSLuaFile("pikmin_video.lua")
include("pikmin_shared.lua")

--//pikmin creation function
function PikminCreateServer(ply,args)
	if #ents.FindByClass("pikmin")+#ents.FindByClass("pikmin_sprout") > PIKMIN_MAXFIELD then return false end
	local color,level = args.color or 1,args.level or 1
	local ent = ents.Create("pikmin")
	ent.Leader = ply
	if not ply then ent.Dismissed = true end
	ent.Color = color
	ent.Level = level
	--ent:SetModel(ColorCollideTable[ent.Color])
	ent:SetPos(args.pos or ply:GetPos() + ply:GetForward() * -32 + ply:GetRight() * math.Rand(-50, 50) + vector_up*30)
	--ent:SetMoveCollide(MOVECOLLIDE_FLY_SLIDE)
	ent:Spawn()
	ent:Activate()
	undo.Create("#pikminf"..ent.Color)
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()
	return ent
end

--//sprout creation function (onion/candypop)
function PikminCreateSproutServer(onion,pos)
	if #ents.FindByClass("pikmin")+#ents.FindByClass("pikmin_sprout") >= PIKMIN_MAXFIELD then return false end
	local ent = ents.Create("pikmin_sprout")
	ent.Color = onion.Color
	ent:SetPos(pos)
	local angle = (ent:GetPos()-onion:GetPos()):Angle()
	ent:SetAngles(Angle(0,angle.Y,0))
	ent:Spawn()
	ent:Activate()
	return true
end

--//pikmin automation
PIKMIN_CHARGE_TABLE = {}

local ThinkNext = 0
local function PikminThink()
	if CurTime() > ThinkNext then
		ThinkNext = CurTime()+0.1
		
		if PIKMIN_AUTO_THINK then
			local ctable = {}
			table.Add(ctable,ents.FindByClass("npc_*"))
			table.Add(ctable,ents.FindByClass("pikmin_fire"))
			table.Add(ctable,ents.FindByClass("pikmin_wire"))
			table.Add(ctable,ents.FindByClass("pikmin_gas"))
			table.Add(ctable,ents.FindByClass("pikmin_nectar"))
			PIKMIN_CHARGE_TABLE = ctable
		end
		
		if not PIKMIN_AUTO_COLLIDE then return end
		local pik = ents.FindByClass("pikmin")
		if #pik ~= 0 then
			local pikDict = {}
			for _,v in ipairs(pik) do
				if IsValid(v.Leader) and not v.Drowning and not v.Attacking and not v.Drinking and not v.Carrying then
					local t = pikDict[v.Leader]
					if not t then t = {} pikDict[v.Leader] = t end
					table.insert(t,v)
				end
			end
			for ply,pikt in pairs(pikDict) do
				if #pikt == 1 then continue end
				for i,pik1 in ipairs(pikt) do
					local pos = pik1:GetPos()
					local pik2
					for _,v in ipairs(ents.FindInSphere(pos,1)) do
						if v.Leader ~= ply then continue end
						pik2 = v
						break
					end
					if not pik2 then continue end
					local p = (pos-pik2:GetPos())*100
					pik1.Phys:ApplyForceCenter(p-p*vector_up)
				end
			end
		end
	end
end
hook.Add("Think","PikminServerThink",PikminThink)

--//olimar weapon skin
util.AddNetworkString("pikmin_skin")
net.Receive("pikmin_skin",function(len,ply)
	local wep = ply:GetWeapon("olimar_gun")
	if IsValid(wep) then wep:UpdateSkin() end
end)

--//pikmin collision
hook.Add("ShouldCollide","PikiCollide",function(ent1,ent2)
	if ent1.PikMdl and ent2.PikMdl then return false end
	if ent1.PikMdl and ent2:IsPlayer() and ent1.Leader == ent2 and not ent1.Thrown then local wep = ent2:GetActiveWeapon() if not IsValid(wep) or wep:GetClass() == "olimar_gun" then return false end end
	if ent1.PikMdl and ent2:IsPlayer() and ent1:GetParent() == ent2 then return false end
	if ent1:GetClass() == "pikmin_model" then
		--nothing should collide except npcs
		if not ent2:IsNPC() then return false end
		--prevents antlions from spazzing out in the air
		if ent1:GetParent():GetParent() == ent2 then return false end
		--prevent npcs from getting stuck on pikmin
		if ent2:GetPos().Z >= ent1:GetPos().Z+5 then return false end
	end
	return GAMEMODE:ShouldCollide(ent1,ent2)
end)

--//captain death ragdoll fix
util.AddNetworkString("RagColorPly")
hook.Add("PlayerDeath","PikiClientDeath",function(ply)
	local cval = table.KeyFromValue(PIKMIN_CAPTAIN_MODELS,ply:GetModel())
	local pk = ply:GetNWBool("ispikmin",false)
	if pk or cval then ply:GetRagdollEntity():Remove() end
	if cval and not pk then
		local mdl = ply:GetModel()
		local rag = ents.Create("prop_ragdoll")
		rag:SetNWBool("pkrg",true)
		rag:SetCollisionGroup(COLLISION_GROUP_WORLD)
		rag:SetModel(string.sub(mdl,1,#mdl-4).."_r.mdl")
		rag:SetBodygroup(1,ply:GetBodygroup(1))
		rag:SetBodygroup(2,ply:GetBodygroup(2))
		rag:SetPos(ply:GetPos()+Vector(0,0,10))
		rag:SetAngles(ply:GetAngles())
		rag:Spawn()
		for i = 1, rag:GetPhysicsObjectCount() do
			local bone = rag:GetPhysicsObjectNum(i)
			if IsValid(bone) then
				bone:ApplyForceOffset(ply:GetVelocity(), ply:GetPos())
				bone:AddVelocity(ply:GetVelocity())
			end
		end
		rag:Activate()
		ply.PikRag = rag
		ply:Spectate(OBS_MODE_CHASE)
		ply:SpectateEntity(rag)
		net.Start("RagColorPly")
		net.WriteEntity(ply)
		net.WriteInt(rag:EntIndex(),32)
		net.Broadcast()
	end
	ply:ConCommand("pikmin_menu 0")
end)

--//remove captain ragdoll
hook.Add("PlayerSpawn","PikiPlayerSpawn",function(ply)
	if IsValid(ply.PikRag) then ply.PikRag:Remove() ply.PikRag = nil end
end)

--//remove captain ragdoll
hook.Add("PlayerDisconnected", "PikiPlayerLeave", function(ply)
	if IsValid(ply.PikRag) then ply.PikRag:Remove() ply.PikRag = nil end
end)

--//damage hook
hook.Add("EntityTakeDamage","PikiDamage",function(ent,dmg)
	if ent:IsPlayer() and ent:GetNWBool("ispikmin") then return true end
	local inflict = dmg:GetInflictor()
	local IsPoison = dmg:IsDamageType(DMG_POISON) and IsValid(inflict) and (inflict:GetClass() == "pikmin_gas" or inflict:GetClass() == "pikmin")
	local IsFire = dmg:IsDamageType(DMG_BURN)
	local IsZap = dmg:IsDamageType(DMG_SHOCK)
	if (IsFire or IsPoison or IsZap) and ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == "olimar_gun" then
		if IsPoison then return true end
		if IsFire and ent:GetNWBool("pikfire",false) then return true end
		if IsZap and ent:GetNWBool("pikzap",false) then return true end
	end
	if ent:IsPlayer() and ent:Alive() and IsPoison then
		if math.random(1,2) == 1 then ent:EmitSound("ambient/voices/cough" .. math.random(1,4) .. ".wav") end
	end
end)

--//save pikmin from being removed
hook.Add("EntityRemoved","PikminVanishFix",function(obj)
	for _,v in ipairs(obj:GetChildren()) do
		if v:GetClass() == "pikmin" then
			v.Target = nil
			v:SetNWBool("Target",false)
			v.Attacking = false
			v:SetPos(Vector(0,0,8))
			v:SetParent()
		end
	end
end)

--//Onion Data
PIKIONIONDATA = {}
PIKIONIONDATASTRINGS = {}

--//change the filenames in the future to allow gamemodes to have separate data
function ReadPikiOnionData(id)
	if file.Exists("pikmin_onion"..id..".txt","DATA") then
	local dat = file.Read("pikmin_onion"..id..".txt","DATA")
	PIKIONIONDATASTRINGS[id] = dat
	if #dat ~= 0 then
		local ntab = {}
		for _,val in ipairs(string.Split(dat," ")) do table.insert(ntab,tonumber(val)) end
		PIKIONIONDATA[id] = ntab
	else
		PIKIONIONDATA[id] = {}
	end
	end
end

function SetPikiOnionData(id,t)
	if #t == 0 then
		if (PIKIONIONDATA[id] and #PIKIONIONDATA[id] ~= 0) or not PIKIONIONDATA[id] then
			PIKIONIONDATASTRINGS[id] = ""
			PIKIONIONDATA[id] = {}
			file.Write("pikmin_onion"..id..".txt","")
		end
		return
	end
	local dat = ""
	for k,v in ipairs(t) do
		dat = dat .. v .. " "
	end
	dat = string.sub(dat,1,#dat-1)
	if PIKIONIONDATASTRINGS[id] ~= dat then
		file.Write("pikmin_onion"..id..".txt",dat)
	end
	PIKIONIONDATASTRINGS[id] = dat
	PIKIONIONDATA[id] = t
end

ReadPikiOnionData(0)
ReadPikiOnionData(1)
ReadPikiOnionData(2)

--//Old Hooks
local function DontToolMe(ply, tr, tool)
	if tool ~= "duplicator" then return true end
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "pikmin_onion" or tr.Entity:GetClass() == "pikmin" or tr.Entity:GetClass() == "pikmin_model" or tr.Entity:GetClass() == "pikmin_fire") then
		return false
	end
	return true
end
hook.Add("CanTool", "DontDupeOnions", DontToolMe)

local function DontPickMeUp(ply, ent)
	if IsValid(ent) and ent:GetClass() == "pikmin_onion" then
		return false
	end
	return true
end
hook.Add("GravGunPickupAllowed", "DontPickupOnions", DontPickMeUp)

local function PikGravPunt(ply, ent)
	if ent:GetClass() == "pikmin" then
		ply:EmitSound("pikmin/pikmin_throw.wav")
		ent.Thrown = true
	end
end
hook.Add("GravGunPunt", "ThrowAnimOnPunt", PikGravPunt)

local function PikDontHitPlayer(ply,ent) --Pikmin are charging me!
	if IsValid(ent) and ent:GetClass() == "pikmin" then return false end
	return GAMEMODE:PlayerShouldTakeDamage(ply,ent)
end
hook.Add("PlayerShouldTakeDamage", "OMGPIKMINDONTHURTMEH", PikDontHitPlayer)