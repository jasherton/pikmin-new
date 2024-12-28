AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	if not self.Leader:Alive() or self.Leader:GetNWBool("ispikmin") then self:Remove() return end
	self:DrawShadow(false)
	self.Leader:SetNWBool("ispikmin",true)
	local pik = ents.Create("pikmin")
	pik.PikPly = self
	pik.Color = self.Color
	pik.Level = self.Level
	pik.Leader = self
	pik.Dismissed = false
	pik:SetPos(self.Leader:GetPos())
	pik:SetAngles(self.Leader:GetAngles())
	self:SetPos(pik:GetPos())
	pik:Spawn()
	pik:Activate()
	self.Pik = pik
	self.Leader:StripWeapons()
	self.Leader:SetMoveType(MOVETYPE_OBSERVER)
	self.Leader:Spectate(OBS_MODE_CHASE)
	self.Leader:SpectateEntity(pik)
	if self.Leader:FlashlightIsOn() then self.Leader:Flashlight(false) end
	self.Leader:AllowFlashlight(false)
	self:SetNWEntity("Leader",self.Leader)
	self:SetNWEntity("Piki",self.Pik)
	self.IgnoreList = {self,self.Leader,self.Pik}
	for _,v in ipairs(ents.FindByClass("pikmin")) do if v.Leader == self.Leader then v.Leader = nil end end
end

local function GetChargeTarget(pos,aim,ignore)
	local tr = util.QuickTrace(pos,aim,ignore)
	if IsValid(tr.Entity) then
		if not CanPikminCharge(tr.Entity) then return end
	end
	return tr.Entity
end

local SingLow = {
{"pikmin/sing1.wav",0.5},
{"pikmin/sing2.wav",0.5},
{"pikmin/sing3.wav",0.25},
{"pikmin/sing4.wav",0.25},
{"pikmin/sing2.wav",0.5},
{"pikmin/sing5.wav",1}
}
local SingMed = {
{"pikmin/sing6.wav",0.5},
{"pikmin/sing7.wav",0.5},
{"pikmin/sing8.wav",0.25},
{"pikmin/sing9.wav",0.25},
{"pikmin/sing7.wav",0.5},
{"pikmin/sing10.wav",1}
}
local SingHigh = {
{"pikmin/sing11.wav",0.5},
{"pikmin/sing12.wav",0.5},
{"pikmin/sing13.wav",0.25},
{"pikmin/sing14.wav",0.25},
{"pikmin/sing12.wav",0.5},
{"pikmin/sing15.wav",1}
}
local SingAll = {SingLow,SingMed,SingHigh}

function ENT:Think()
	if not IsValid(self.Pik) or not IsValid(self.Leader) or self.Pik.Dead then self:Remove() return false end
	if not self.Leader:Alive() then self.Pik:Die() self:Remove() return false end
	
	if not self.Pik.Dead then
		local LookAngles = self.Leader:EyeAngles()
		LookAngles = Angle(0,LookAngles.y,0)
		local MoveX,MoveZ = self.Leader:KeyDown(IN_MOVERIGHT) and 1 or self.Leader:KeyDown(IN_MOVELEFT) and -1 or 0,self.Leader:KeyDown(IN_FORWARD) and 1 or self.Leader:KeyDown(IN_BACK) and -1 or 0
		self:SetPos(self.Pik:GetPos()+LookAngles:Forward()*50+LookAngles:Forward()*MoveZ*500+LookAngles:Right()*MoveX*500)
		
		if self.Leader:KeyDown(IN_ATTACK) and (self.Pik.PikMdl.CurAnim == 1 or self.Pik.PikMdl.CurAnim == 2) then
			if self.SingTick and CurTime() >= self.SingTick or not self.SingTick then
				if not self.SingID then
					self.SingType = math.random(1,3)
					self.SingID = 1
				end
				local info = SingAll[self.SingType][self.SingID]
				self.SingTick = CurTime()+info[2]
				self.Pik:EmitSound(info[1])
				self.SingID = self.SingID + 1
				if self.SingID > 6 then self.SingID = nil end
			end
		end
		
		if self.Leader:KeyDown(IN_ATTACK2) then
			if not self.Pik.Dismissed and not self.Pik.AttackTarget then
				local target = GetChargeTarget(self.Pik:GetPos()+Vector(0,0,30),self.Leader:EyeAngles():Forward()*6000,self.IgnoreList)
				if target and IsValid(target) then self.Pik:Charge(target) end
			end
		end
		
		if self.Leader:KeyDown(IN_RELOAD) and (self.ActDebounce and CurTime() >= self.ActDebounce or not self.ActDebounce) then
			self.ActDebounce = CurTime()+0.5
			if self.Leader:KeyDown(IN_USE) then
				if not self.Pik.Dismissed and not self.Pik.Drinking then
					if self.Pik.AttackTarget or self.Pik.Carrying then self.Pik:Drop() end
					self.Pik:Disband()
				end
			else
				if self.Pik.Leader ~= self then self.Pik.Leader = self end
				self.Pik:Call(self)
				if not self.Pik.Drinking and (self.Pik.AttackTarget or self.Pik.Carrying) then
					self.Pik:Drop()
				end
			end
		end
		
		if self.Leader:KeyDown(IN_JUMP) then
			local ground = util.QuickTrace(self.Pik:GetPos(),vector_up*-5,self.IgnoreList)
			if ground.Hit and (self.JumpDebounce and CurTime() >= self.JumpDebounce or not self.JumpDebounce) then
				self.JumpDebounce = CurTime()+1
				if not self.Pik.Dismissed and not self.Pik.Carrying and not self.Pik.Drinking and not self.Pik:IsOnFire() and not self.Pik.Poison and not self.Pik.Drowning and not self.Pik.Attacking and not self.Pik.Thrown and CurTime() >= self.Pik.ThrowNext then
					self.Pik.Thrown = true
					self.Pik.Phys:ApplyForceCenter(self.Pik.JumpVector*2)
				end
			end
		end
	end
	
	self:NextThink(CurTime())
	return true
end

--haha read this fake value
function ENT:Alive()
	return true
end

function ENT:OnRemove()
	if self.Pik and IsValid(self.Pik) then if not self.Pik.Dead then self.Pik:Remove() end end
	if self.Leader and IsValid(self.Leader) then self.Leader:SetNWBool("ispikmin",false) self.Leader:KillSilent() end
end

function ENT:SpawnFunction(ply)
	ply:ConCommand("pikmin_menu 2")
end