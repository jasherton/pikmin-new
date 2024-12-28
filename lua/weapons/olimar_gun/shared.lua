SWEP.Author = "Aska & jasherton"
SWEP.Purpose = "#olimar_gun.purpose"
SWEP.Instructions = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = "#pikmin"

if SERVER then
	AddCSLuaFile()
	SWEP.Weight	= 5
	SWEP.AutoSwitchTo = false
	SWEP.AutoSwitchFrom = false
end

if CLIENT then
	SWEP.PrintName = "#olimar_gun"
	SWEP.Instructions = language.GetPhrase("olimar_gun.info1").."\n"..
	language.GetPhrase("olimar_gun.info2").."\n"..
	language.GetPhrase("olimar_gun.info3").."\n"..
	language.GetPhrase("olimar_gun.info4").."\n"..
	language.GetPhrase("olimar_gun.info5").."\n"..
	language.GetPhrase("olimar_gun.info6")
	SWEP.Slot = 1
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
	SWEP.WepSelectIcon = surface.GetTextureID("weapons/pikmincommand")
end

SWEP.ViewModel = "models/weapons/v_olimar.mdl"
SWEP.WorldModel = "models/weapons/w_olimar.mdl"

SWEP.SelRadius = 0
SWEP.LastSkin = -1
SWEP.LastWhistle = -1

function SWEP:Initialize()
	self:UpdateHoldType("melee")
end

function SWEP:UpdateHoldType(ht)
	if self.HoldType ~= ht then
		self.HoldType = ht
		self:SetHoldType(ht)
	end
end

function SWEP:PreDrawViewModel(view,wep,ply)
	view:SetSkin(self:GetSkin())
	if not view.GetPlayerColor then view.GetPlayerColor = function() return ply:GetPlayerColor() end end
end

if CLIENT then
modelexample = ClientsideModel( "models/thrusters/jetpack.mdl" )
modelexample:SetNoDraw( true )
end

function SWEP:DrawWorldModel(flags)
	if IsValid(self.Owner) then
		local boneid = self.Owner:LookupBone("ValveBiped.Bip01_L_Toe0")
		if not boneid then self:DrawShadow(false) return end
		local matrix = self.Owner:GetBoneMatrix(boneid)
		if not matrix then self:DrawShadow(false) return end
		if self.Owner:GetNWBool("piknd",false) or table.KeyFromValue(PIKMIN_CAPTAIN_MODELS,self.Owner:GetModel()) then self:DrawShadow(false) return end
		if not self.GetPlayerColor then self.GetPlayerColor = function() return self.Owner:GetPlayerColor() end end
	end
	self:DrawShadow(true)
	self:DrawModel(flags)
end

--//use player skin info
function SWEP:UpdateSkin()
	local skinID = math.Clamp(self.Owner:GetInfoNum("cl_pikminskin",0),0,5)
	local whistleType = math.Clamp(self.Owner:GetInfoNum("cl_pikwhistle",0),0,3)
	if self.LastSkin == skinID and self.LastWhistle == whistleType then return end
	self.LastSkin = skinID
	self.LastWhistle = whistleType
	self:SetSkin(skinID)
	if self.WhistleSound then self.WhistleSound:Stop() end
	if self.SwarmSound then self.SwarmSound:Stop() end
	
	local soundWhistle = "pikmin/whistle.wav"
	local soundSwarm = "pikmin/swarm1.wav"
	
	if whistleType == 0 then
		soundWhistle = skinID == 2 and "pikmin/whistle2.wav" or skinID == 3 and "pikmin/whistle3.wav" or soundWhistle
		soundSwarm = skinID == 2 and "pikmin/swarm2.wav" or skinID == 3 and "pikmin/swarm3.wav" or soundSwarm
	else
		soundWhistle = whistleType == 2 and "pikmin/whistle2.wav" or whistleType == 3 and "pikmin/whistle3.wav" or soundWhistle
		soundSwarm = whistleType == 2 and "pikmin/swarm2.wav" or whistleType == 3 and "pikmin/swarm3.wav" or soundSwarm
	end
	
	self.WhistleSound = CreateSound(self,soundWhistle)
	self.SwarmSound = CreateSound(self,soundSwarm)
	if self.Swarm then self.SwarmSound:Play() end
end

function SWEP:Deploy()
	if SERVER then
		self:UpdateSkin()
		self:SendWeaponAnim(ACT_VM_DRAW)
		timer.Remove("OlimarGunIdle" .. self:EntIndex())
		timer.Create("OlimarGunIdle" .. self:EntIndex(), 1.2, 1, function()
			if not IsValid(self) then return end
			self:SendWeaponAnim(ACT_VM_IDLE)
		end)
		self.Owner:SetCanZoom(false)
	end
	return true
end

function SWEP:Holster()
	if SERVER then
		timer.Remove("OlimarGunIdle" .. self:EntIndex())
		timer.Remove("OlimarGunIdleCharge" .. self:EntIndex())
		if self.Swarm then self.Owner:SetSlowWalkSpeed(self.Owner.SlowSpeed) end
		self.Owner:SetCanZoom(true)
		self.Owner.SwarmVec = nil
		self.Swarm = false
		self.Whistling = false
		self.WhistleSound:Stop()
		self.SwarmSound:Stop()
		self:SendWeaponAnim(ACT_VM_HOLSTER)
		local ply = self.Owner
		local throwpikmin = ply:GetNWEntity("piki",ply)
		if IsValid(throwpikmin) and throwpikmin ~= ply then
			ply:StopSound("pikmin/grab.wav")
			throwpikmin:SetMoveType(MOVETYPE_VPHYSICS)
			throwpikmin:SetPos(Vector(0,0,0))
			throwpikmin:SetParent(nil)
			throwpikmin:SetPos(ply:GetPos()-ply:GetForward()*24)
			throwpikmin:SetAngles(throwpikmin.params.angle)
			ply:SetNWEntity("piki",ply)
		end
	end
	return true
end

function SWEP:OnRemove()
	if not SERVER then return end
	if self.Swarm then self.Owner:SetSlowWalkSpeed(self.Owner.SlowSpeed) end
	self.Owner:SetCanZoom(true)
	self.Owner.SwarmVec = nil
	self.Swarm = false
	self.Whistling = false
	self.WhistleSound:Stop()
	self.SwarmSound:Stop()
	local ply = self.Owner
	local throwpikmin = ply:GetNWEntity("piki",ply)
	if IsValid(throwpikmin) and throwpikmin ~= ply then
		ply:StopSound("pikmin/grab.wav")
		throwpikmin:SetMoveType(MOVETYPE_VPHYSICS)
		throwpikmin:SetPos(Vector(0,0,0))
		throwpikmin:SetParent(nil)
		throwpikmin:SetPos(ply:GetPos()-ply:GetForward()*24)
		throwpikmin:SetAngles(throwpikmin.params.angle)
		ply:SetNWEntity("piki",ply)
	end
end

function SWEP:PrimaryAttack() end

function SWEP:SecondaryAttack()
	if not SERVER then return end
	if self.Whistling then return end
	if self.ChargeTick and CurTime()-self.ChargeTick < 0.5 then return end
	local tr = util.QuickTrace(self.Owner:GetShootPos(), (self.Owner:GetAimVector() * 3000), self.Owner)
	if IsValid(tr.Entity) then
		if tr.Entity.PikIgnore then
			if not tr.Entity:IsNPC() then return end
			tr = util.QuickTrace(self.Owner:GetShootPos(), (self.Owner:GetAimVector() * 3000), {self.Owner,tr.Entity})
			if not IsValid(tr.Entity) then return end
		end
		if not CanPikminCharge(tr.Entity) then return end
		local charged = false
		local chargetype = self.Owner:GetNWEntity("piki")
		if IsValid(chargetype) and chargetype.PikMdl then
			self.Owner:SetNWEntity("piki",self.Owner)
			chargetype:SetMoveType(MOVETYPE_VPHYSICS)
			chargetype:SetPos(Vector(0,0,0))
			chargetype:SetParent()
			chargetype:SetPos(self.Owner:GetPos()-self.Owner:GetForward()*24)
			chargetype:SetAngles(chargetype.params.angle)
			timer.Simple(0,function() self.Owner:StopSound("pikmin/grab.wav") end)
		else
			chargetype = nil
		end
		for _,v in ipairs(ents.FindByClass("pikmin")) do
			if v.Leader == self.Owner and not v.Carrying and not v.Drinking and not v.Hazard and not v.Attacking and not v.Target and (chargetype and (v.Color == chargetype.Color and v.Level == chargetype.Level) or not chargetype) then
				charged = true
				v:Charge(tr.Entity)
			end
		end
		if charged then
			self.ChargeTick = CurTime()
			self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
			self.WhistleSound:Stop()
			self.WhistleSound:Play()
			if timer.Exists("OlimarGunIdleCharge"..self:EntIndex()) then timer.Remove("OlimarGunIdleCharge"..self:EntIndex()) end
			timer.Create("OlimarGunIdleCharge"..self:EntIndex(), 1.45, 1, function() self:SendWeaponAnim(ACT_VM_IDLE) self.WhistleSound:Stop() end)
		end
	end
end

function SWEP:Think()
	if not SERVER then return end
	if self.Swarm then
		local dirX = self.Owner:KeyDown(IN_MOVELEFT) and -1 or self.Owner:KeyDown(IN_MOVERIGHT) and 1 or 0
		local dirZ = self.Owner:KeyDown(IN_BACK) and -1 or self.Owner:KeyDown(IN_FORWARD) and 1 or 0
		if dirX ~= 0 or dirZ ~= 0 then
			local angles = self.Owner:EyeAngles()
			angles:SetUnpacked(0,angles[2],0)
			self.Owner.SwarmVec = (angles:Forward()*dirZ+angles:Right()*dirX):GetNormalized()*250
		else
			self.Owner.SwarmVec = nil
		end
	end
	if self.Whistling then
		local diffTime = CurTime()-self.WhistleTime
		if diffTime > 1.25 then
			self.WhistleSound:Stop()
			self.Whistling = false
			self:SendWeaponAnim(ACT_VM_IDLE)
		end
		local start = self.Owner:GetShootPos()
		local tr = util.TraceLine({
			start=start,
			endpos=start+self.Owner:GetAimVector()*750,
			mask=MASK_ALL,
			filter={self.Owner},
		})
		--local tr = util.QuickTrace(self.Owner:GetShootPos(), self.Owner:GetAimVector() * 750, function() return false end)
		if tr.Hit then
			local whistleRange = math.min(10 + diffTime*256,200)
			local hasPluck = self.Owner:GetNWBool("pikipluck",false)
			if hasPluck then
				for _,v in ipairs(ents.FindByClass("pikmin_sprout")) do
					if v:GetPos():Distance(tr.HitPos) <= whistleRange then
						v:Pluck(self.Owner,true)
					end
				end
			end
			--local drownTick = CurTime() + 0.1
			for _,v in ipairs(ents.FindByClass("pikmin")) do
				if v:GetPos():Distance(tr.HitPos) <= whistleRange and self.Owner:GetForward():Dot((self.Owner:GetPos()-v:GetPos()):GetNormalized()) < 0 then
					v:Call(self.Owner)
					--[[if v.Leader == self.Owner then
						if v.Target and not v.Drinking then
							v:Drop()
						end
						if v.Drowning then
							v.DrownCall = drownTick
						end
					end
					if v.Poison then v.Poison = false end
					if v:IsOnFire() then
						v:Extinguish()
					end
					if v.Carrying and (v.Leader == self.Owner or v.Dismissed) then
						v:Drop()
					end
					if v.Dismissed and v.Leader == nil then
						v:Join(self.Owner)
					end--]]
				end
			end
		end
	end
	
	if self.LastType and self.Owner:GetNWEntity("piki",self.Owner) == self.Owner then
		local LastThrow = self.ThrowTick or CurTime()
		if CurTime() - LastThrow >= 0.5 then
			self.LastType = nil
			self.Owner:SetNWInt("pikic",0)
		end
	end
end

local function IsCaptain(ply)
if not ply:Alive() then return end
local wep = ply:GetActiveWeapon()
if not IsValid(wep) then return end
if wep:GetClass() ~= "olimar_gun" then return end
return true
end

if SERVER then
	util.AddNetworkString("PikiVMThrow")
else
	net.Receive("PikiVMThrow",function()
		local ply = net.ReadEntity()
		if IsValid(ply) then ply:SetAnimation(PLAYER_ATTACK1) end
	end)
end

local function PikSWepKeyPress(ply, key)
	if not SERVER then return end
	if not IsCaptain(ply) then return end
	if key == IN_ATTACK then
		if ply:GetActiveWeapon().Whistling then return end
		local piki = {}
		local typeLUT = {}
		local opos = ply:GetPos()
		local ctime = CurTime()
		local minDistConstant = 200^2
		for _,v in ipairs(ents.FindByClass("pikmin")) do
			if v.Leader == ply and v.ThrowNext <= ctime and v:GetPos():DistToSqr(opos) <= minDistConstant and not v.Thrown and not v.Carrying and not v.Drinking and not v.Hazard and not v.Target then
				table.insert(piki,v)
				local num = typeLUT[v.Color] or 0
				typeLUT[v.Color] = num+1
			end
		end
		if #piki ~= 0 then
			--maybe add functionality for picking up a pikmin if the player is looking at it
			ply:GetActiveWeapon().HoldTick = CurTime()
			ply:GetActiveWeapon().PunchTick = CurTime()
			
			local LastType = ply:GetActiveWeapon().LastType
			local TypeSwap = ply:GetActiveWeapon().TypeSwap
			
			local LastThrow = ply:GetActiveWeapon().ThrowTick or CurTime()
			if LastType and typeLUT[LastType] and (CurTime() - LastThrow < 0.5 or TypeSwap) then
				table.sort(piki,function(a,b)
					return a:GetPos():DistToSqr(opos) + math.abs(a.Color-LastType)*minDistConstant <
						b:GetPos():DistToSqr(opos) + math.abs(b.Color-LastType)*minDistConstant
				end)
			else
				table.sort(piki,function(a,b) return a:GetPos():DistToSqr(opos) < b:GetPos():DistToSqr(opos) end)
			end
			
			local throwpikmin = piki[1]
			ply:GetActiveWeapon().LastType = throwpikmin.Color
			ply:SetNWInt("pikic",throwpikmin.Color)
			
			if not TypeSwap then
				timer.Simple(0.03,function() ply:EmitSound("pikmin/grab.wav", 100, math.random(98, 105)) end)
			else
				ply:GetActiveWeapon().TypeSwap = nil
			end
			
			local attachID = ply:LookupAttachment("anim_attachment_RH")
			ply:SetNWEntity("piki",throwpikmin)
			throwpikmin:SetParent(ply,attachID)
			throwpikmin:SetPos(Vector(5,2,-8))
			throwpikmin:SetAngles(Angle(0,0,0))
			throwpikmin:SetMoveType(MOVETYPE_NONE)
		else
			if ply:GetActiveWeapon().PunchTick and CurTime()-ply:GetActiveWeapon().PunchTick < 0.5 then return end
			ply:GetActiveWeapon().PunchTick = CurTime()
			local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 100, ply)
			if tr.Hit and tr.Entity:Health() > 0 and (tr.Entity:IsNPC() or tr.Entity:IsPlayer() or tr.Entity:GetClass() == "pikmin_fire") then
				tr.Entity:TakeDamage(10, ply, ply:GetActiveWeapon())
				ply:EmitSound("pikmin/punch.wav")
			else
				ply:EmitSound("pikmin/punchair.wav",75,math.random(90,120))
			end
			ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_PRIMARYATTACK)
			net.Start("PikiVMThrow")
			net.WriteEntity(ply)
			net.Broadcast()
			if timer.Exists("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex()) then
				timer.Remove("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex())
			end
			timer.Create("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex(), 0.8, 1, function() ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_IDLE) end)
		end
	elseif key == IN_ZOOM then
		local throwpikmin = ply:GetNWEntity("piki")
		if IsValid(throwpikmin) and throwpikmin ~= ply then
			local piki = {}
			local typeLUT = {}
			local opos = ply:GetPos()
			local ctime = CurTime()
			local minDistConstant = 200^2
			local LastType = ply:GetActiveWeapon().LastType
			for _,v in ipairs(ents.FindByClass("pikmin")) do
				if v.Leader == ply and v.ThrowNext <= ctime and v:GetPos():DistToSqr(opos) <= minDistConstant and not v.Thrown and not v.Carrying and not v.Drinking and not v.Hazard and not v.Target then
					table.insert(piki,v)
					typeLUT[v.Color] = true
				end
			end
			
			if #piki ~= 0 then
				LastType = (LastType%#PIKMIN_COLMDL)+1
			
				while not typeLUT[LastType] do
					LastType = (LastType%#PIKMIN_COLMDL)+1
				end
				
				ply:GetActiveWeapon().LastType = LastType
				ply:GetActiveWeapon().TypeSwap = true
				
				ply:StopSound("pikmin/grab.wav")
				throwpikmin:SetMoveType(MOVETYPE_VPHYSICS)
				throwpikmin:SetPos(Vector(0,0,0))
				throwpikmin:SetParent(nil)
				throwpikmin:SetPos(ply:GetPos()-ply:GetForward()*24)
				throwpikmin:SetAngles(throwpikmin.params.angle)
				ply:SetNWEntity("piki",ply)
				
				PikSWepKeyPress(ply,IN_ATTACK)
			end
		end
	elseif key == IN_RELOAD then
		local throwpikmin = ply:GetNWEntity("piki")
		if IsValid(throwpikmin) and throwpikmin ~= ply then
			ply:StopSound("pikmin/grab.wav")
			throwpikmin:SetMoveType(MOVETYPE_VPHYSICS)
			throwpikmin:SetPos(Vector(0,0,0))
			throwpikmin:SetParent(nil)
			throwpikmin:SetPos(ply:GetPos()-ply:GetForward()*24)
			throwpikmin:SetAngles(throwpikmin.params.angle)
			ply:SetNWEntity("piki",ply)
		end
		if ply:KeyDown(IN_USE) then
			local disbanded = false
			
			if ply:GetNWBool("pikidis",false) then
				local pikiArray = {}
				local typeDict = {}
				local typeArray = {}
				local typeCount = 0
				local sepDist = 100
				local forDist = 200
				local pos = ply:GetPos()
				local eyeangles = ply:EyeAngles()
				eyeangles = Angle(0,eyeangles.Y,0)
				local forward = eyeangles:Forward()
				local squadCenter = Vector(0,0,0)
				
				--Split by color
				for _,v in ipairs(ents.FindByClass("pikmin")) do
					if v.Leader == ply and not v.Target and not v.Hazard and not v.Carrying and not v.Called and not v.Thrown and not v.Drinking then
						disbanded = true
						if v:GetPos():Distance(pos) >= 400 or math.abs((v:GetPos()-pos)[3]) >= 120 or forward:Dot((pos-v:GetPos()):GetNormalized()) > 0 then
							v:Disband()
						else
							if not table.KeyFromValue(typeArray,v.Color) then
							table.insert(typeArray,v.Color)
							end
							if not typeDict[v.Color] then
								typeDict[v.Color] = {}
								typeCount = typeCount + 1
							end
							table.insert(typeDict[v.Color],v)
							table.insert(pikiArray,v)
							squadCenter = squadCenter + v:GetPos()
						end
					end
				end
				
				--Split by level if possible
				if typeCount == 1 then
					sepDist = 70
					forDist = 120
					typeDict = {}
					typeArray = {}
					typeCount = 0
					for _,v in ipairs(pikiArray) do
						if not table.KeyFromValue(typeArray,v.Level) then
							table.insert(typeArray,v.Level)
						end
						if not typeDict[v.Level] then
							typeDict[v.Level] = {}
							typeCount = typeCount + 1
						end
						table.insert(typeDict[v.Level],v)
					end
				end
				if typeCount == 2 then
					sepDist = 75
					forDist = 120
				elseif typeCount == 3 then
					sepDist = 90
					forDist = 140
				end
				
				sepDist = sepDist-math.Clamp(ply:EyeAngles().X-40,0,45)/2
				
				squadCenter = squadCenter/#pikiArray
				
				if typeCount == 1 then
					for _,v in ipairs(pikiArray) do
						v:Disband()
					end
				else
					local posArray = {}
					local basePos = squadCenter --+ forward*forDist
					local slice = 2 * math.pi / typeCount
					local right = eyeangles:Right()
					for i=0,typeCount-1 do
						local angle = slice * i
						table.insert(posArray,basePos+right*sepDist*math.cos(angle)+forward*sepDist*math.sin(angle))
					end
					for k,typ in ipairs(typeArray) do
						for _,v in ipairs(typeDict[typ]) do
							v:Disband(posArray[k])
						end
					end
				end
			else
				for _,v in ipairs(ents.FindByClass("pikmin")) do
					if v.Leader == ply and not v.Target and not v.Hazard and not v.Carrying and not v.Called and not v.Thrown and not v.Drinking then
						disbanded = true
						v:Disband()
					end
				end
			end
			
			if disbanded then
				ply:GetActiveWeapon().WhistleSound:Stop()
				ply:EmitSound("pikmin/disband.wav")
				ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_DRYFIRE)
				if timer.Exists("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex()) then
					timer.Remove("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex())
				end
				if timer.Exists("OlimarGunIdleCharge"..ply:GetActiveWeapon():EntIndex()) then
					timer.Remove("OlimarGunIdleCharge"..ply:GetActiveWeapon():EntIndex())
				end
				timer.Create("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex(), 0.8, 1, function() ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_IDLE) end)
				if ply:GetActiveWeapon().Swarm then
					ply:GetActiveWeapon().Swarm = false
					ply:SetSlowWalkSpeed(ply.SlowSpeed)
					ply:GetActiveWeapon().SwarmSound:FadeOut(0.2)
					ply.SwarmVec = nil
				end
			end
		else
			if timer.Exists("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex()) then
				timer.Remove("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex())
			end
			if timer.Exists("OlimarGunIdleCharge"..ply:GetActiveWeapon():EntIndex()) then
				timer.Remove("OlimarGunIdleCharge"..ply:GetActiveWeapon():EntIndex())
			end
			ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_RELOAD)
			ply:GetActiveWeapon().WhistleTime = CurTime()
			ply:GetActiveWeapon().Whistling = true
			ply:GetActiveWeapon().WhistleSound:Stop()
			ply:GetActiveWeapon().WhistleSound:Play()
		end
	elseif key == IN_WALK then
		ply.SlowSpeed = ply:GetSlowWalkSpeed()
		local valid = false
		for _,v in ipairs(ents.FindByClass("pikmin")) do if v.Leader == ply then valid = true break end end
		if not valid then return end
		ply:SetSlowWalkSpeed(1)
		ply:GetActiveWeapon().Swarm = true
		ply:GetActiveWeapon().SwarmSound:Play()
	end
end

local function PikSWepKeyRelease(ply, key)
	if not SERVER then return end
	if not IsCaptain(ply) then return end
	if key == IN_ATTACK then
		local throwpikmin = ply:GetNWEntity("piki")
		if IsValid(throwpikmin) and throwpikmin ~= ply then
			ply:SetNWEntity("piki",ply)
			local aimVector = ply:GetAimVector()
			ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_PRIMARYATTACK)
			net.Start("PikiVMThrow")
			net.WriteEntity(ply)
			net.Broadcast()
			if timer.Exists("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex()) then
				timer.Remove("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex())
			end
			timer.Create("OlimarGunIdle"..ply:GetActiveWeapon():EntIndex(), 0.8, 1, function()
				local wep = ply:GetActiveWeapon()
				if not IsValid(wep) then return end
				wep:SendWeaponAnim(ACT_VM_IDLE)
			end)
			local force = throwpikmin.Color == 2 and 56 or 40
			local forceMult = 0.8+math.min(0.3,CurTime()-ply:GetActiveWeapon().HoldTick)
			throwpikmin:SetPos(Vector(0,0,0))
			throwpikmin:SetParent(nil)
			throwpikmin:SetMoveType(MOVETYPE_VPHYSICS)
			local phys = throwpikmin:GetPhysicsObject()
			throwpikmin.ThrowNext = CurTime() + 1
			if aimVector.Z < -0.4 then
				throwpikmin:SetPos((ply:GetShootPos() - Vector(0,0,16) + (aimVector * 28)))
				if throwpikmin:GetPos().Z <= ply:GetPos().Z then
					local diff = ply:GetPos().Z - throwpikmin:GetPos().Z
					throwpikmin:SetPos(throwpikmin:GetPos()+Vector(0,0,diff*1.5))
				end
			else
				throwpikmin:SetPos((ply:GetShootPos() + (aimVector * 28)))
			end
			ply:GetActiveWeapon().ThrowTick = CurTime()
			timer.Simple(0,function() ply:StopSound("pikmin/grab.wav") end)
			throwpikmin:EmitSound("pikmin/pikmin_throw.wav")
			throwpikmin.Thrown = true
			throwpikmin.params.angle = (throwpikmin:GetPos()-ply:GetShootPos()):Angle()
			throwpikmin:SetAngles(throwpikmin.params.angle)
			if IsValid(phys) then
				phys:EnableMotion(true)
				phys:SetVelocity(ply:GetVelocity())
				phys:ApplyForceCenter(((aimVector*(force*forceMult) + Vector(0,0,5)) * 125))
			end
			
			local typeLUT = {}
			local opos = ply:GetPos()
			local ctime = CurTime()
			local minDistConstant = 200^2
			for _,v in ipairs(ents.FindByClass("pikmin")) do
				if v.Leader == ply and v.ThrowNext <= ctime and v:GetPos():DistToSqr(opos) <= minDistConstant and not v.Thrown and not v.Carrying and not v.Drinking and not v.Hazard and not v.Target then
					local num = typeLUT[v.Color] or 0
					typeLUT[v.Color] = num+1
				end
			end
			
			if not typeLUT[throwpikmin.Color] then
				ply:GetActiveWeapon().LastType = nil
				ply:SetNWInt("pikic",0)
			end
		end
	elseif key == IN_RELOAD then
		if ply:GetActiveWeapon().Whistling then
			ply:GetActiveWeapon().Whistling = false
			ply:GetActiveWeapon().WhistleSound:FadeOut(0.2)
			ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_IDLE)
		end
	elseif key == IN_WALK then
		ply:SetSlowWalkSpeed(ply.SlowSpeed)
		ply:GetActiveWeapon().Swarm = false
		ply:GetActiveWeapon().SwarmSound:FadeOut(0.2)
		ply.SwarmVec = nil
	end
end

hook.Add("KeyPress", "OlimarGunKeyPress", PikSWepKeyPress)
hook.Add("KeyRelease", "OlimarGunKeyRelease", PikSWepKeyRelease)

local BoxColor = Color(0,0,0,100)
local IconMat = Material("icons/piki.png","noclamp")
local IconColor = Color(255,255,255,255)
local TextColor = Color(255,255,255,255)
local MinPikiDistance = 40000

function SWEP:DrawHUD()
	if not cvars.Bool("cl_pikminhud") then return end
	local pikEnts = ents.FindByClass("pikmin_model")
	local CurPik = 0
	local MinDist = MinPikiDistance
	local opos = LocalPlayer():GetPos()
	local heldpiki = LocalPlayer():GetNWEntity("piki")
	local ourEnts = 0
	
	local holdColor = LocalPlayer():GetNWInt("pikic",0)
	holdColor = holdColor ~= 0 and holdColor or nil
	
	for k,v in ipairs(pikEnts) do
		local parent = v:GetParent()
		if not IsValid(parent) then continue end
		if parent == heldpiki then
			ourEnts = ourEnts+1
			MinDist = 0
			CurPik = (v:GetNWInt("Color",1)-1)*3+v:GetNWInt("Level",1)
			continue
		end
		if parent:GetNWEntity("Leader") ~= self.Owner then continue end
		if parent:GetNWBool("Target",false) then continue end
		local seq = v:GetSequence()
		if seq > 2 and seq ~= 5 then continue end
		ourEnts = ourEnts+1
		if holdColor and v:GetNWInt("Color") ~= holdColor then continue end
		local dist = v:GetPos():DistToSqr(opos)
		if dist <= MinDist then
			MinDist = dist
			CurPik = (v:GetNWInt("Color",1)-1)*3+v:GetNWInt("Level",1)
		end
	end
	
	local w,h = ScrW(),ScrH()
	draw.RoundedBox(8, w - 138 - 64, h - 58, 128, 48, BoxColor)
	draw.DrawText(ourEnts.." / "..#pikEnts,"DermaLarge",w-76 - 64,h-49,TextColor,TEXT_ALIGN_CENTER)
	surface.SetMaterial(IconMat)
	surface.SetDrawColor(IconColor)
	local suv = CurPik*0.0526
	if CurPik ~= self.LastPik then
		if self.LastPik then self.IconBounce = 16 end
		self.LastPik = CurPik
	end
	local addSize = self.IconBounce or 0
	if addSize > 0 then
		addSize = addSize-2
		self.IconBounce = addSize
	end
	surface.DrawTexturedRectUV(w-68-addSize/2,h-72-addSize/2,64+addSize,64+addSize,suv,0,suv+0.053,1)
end