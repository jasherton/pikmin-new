AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[
--//Animations//--
Ragdoll (0)
Full Idle (1)
Standard Idle (2)
Land (3)
Seed Spit (4)
Entity Inhaled (5)
--]]

ENT.CurAnim = 2
ENT.DoLand = true

function ENT:SpawnFunction(ply,tr)
	ply:ConCommand("pikmin_menu 3")
end

function ENT:KeyValue(key,value)
	if key == "hammerid" then self.WorldEnt = true end
	if key == "land" then self.DoLand = value == "1" end
	if key == "data" then
		if #value ~= 0 then
			self.SaveOnly = true
			local ntab = {}
			for _,v in ipairs(string.Split(value," ")) do table.insert(ntab,tonumber(v) or 0) end
			self.PikiList = ntab
		end
	end
	if key == "skin" then self.Skin = tonumber(value) or 0 end
	if string.Left(key,2) == "On" then
		self:StoreOutput(key,value)
	end
end

function ENT:Initialize()
	if #ents.FindByClass("pikmin_onion") >= 4 then self:Remove() return end
	local skin = self.Skin or math.random(0,2)
	local usedSkins = {}
	for _,v in ipairs(ents.FindByClass("pikmin_onion")) do
		if v ~= self then usedSkins[v:GetSkin()] = true end
	end
	if usedSkins[skin] then
		skin = -1
		repeat skin = skin + 1 until skin == 2 or not usedSkins[skin]
	end
	if self:WaterLevel() >= 1 then skin = 0 end
	if usedSkins[skin] then self:Remove() return end
	
	local exclude = {self}
	table.Add(exclude,ents.FindByClass("pikmin"))
	table.Add(exclude,ents.FindByClass("pikmin_sprout"))
	table.Add(exclude,ents.FindByClass("player"))
	local trace = util.QuickTrace(self:GetPos(),Vector(0,0,100000),ents.GetAll())
	if not trace.HitSky then
		self.DoLand = false
	end
	
	self.Skin = skin
	if not self.PikiList then self.PikiList = PIKIONIONDATA[skin] and table.Copy(PIKIONIONDATA[skin]) or {} end
	self.PullTable = {}
	self.EXID = 0
	self:SetSkin(skin)
	self:SetColor(Color(255,255,255,0))
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetModel("models/pikmin/onion.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(true)
	self:StartMotionController()
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self.Color = self.Skin == 2 and 1 or self.Skin == 1 and 2 or self.Skin == 0 and 3
	self.NextUse = CurTime()
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetBuoyancyRatio(0)
		phys:Wake()
	end
	
	timer.Create("vis"..self:EntIndex(), 0.5, 1, function() self:SetColor(Color(255,255,255,255)) end)
	if self.DoLand then
		self.CurAnim = 3
		timer.Create("land"..self:EntIndex(), 4.5, 1, function() self.CurAnim = 2 end)
	end
end

function ENT:Think()
	if self.LastAnim ~= self.CurAnim then
		self.LastAnim = self.CurAnim
		self:ResetSequence(self.CurAnim)
	end
	if self.CurAnim == 2 or self.CurAnim == 0 then
		self.CurAnim = #self.PikiList >= 100 and 1 or 2
	end
	local PullCenter = self:GetPos()+Vector(0,0,160)
	for _,v in ipairs(self.PullTable) do
		if not IsValid(v) then table.remove(self.PullTable,table.KeyFromValue(self.PullTable,v)) continue end
		local phys = v.PikPhys
		if not phys then
			phys = v:GetPhysicsObject()
			phys:EnableGravity(false)
			v:SetCollisionGroup(COLLISION_GROUP_WORLD)
			v.PikPR = v:BoundingRadius()
			v.PikPhys = phys
			v:SetModelScale(0,v:GetPos():Distance(PullCenter)/math.min(200,5*v.PikPR))
		end
		local pos = v:GetPos()
		local speed = math.max((40000-pos:DistToSqr(PullCenter))/64,64)
		phys:SetVelocity((PullCenter-pos):GetNormalized()*speed)
		if pos:DistToSqr(PullCenter) <= v.PikPR then
			--produce seeds
			self.CurAnim = 5
			timer.Remove("suck"..self:EntIndex())
			timer.Create("suck"..self:EntIndex(),0.8,1,function() self.CurAnim = 4 end)
			self.EXID = self.EXID + 1
			
			local pikCount = PikiFueDict[v:GetModel()] or math.random(1,3)
			if PikiFueSDict[v:GetModel()] and v:GetSkin() == self.Skin then
				pikCount = pikCount * 2
			end
			timer.Create("expel"..self:EntIndex()..self.EXID,1.8,1,function()
				if self.CurAnim == 4 then
					self.CurAnim = 2
				end
				for i=1,pikCount do
					local rand = math.Rand(-10,10)
					if not PikminCreateSproutServer(self,self:GetPos()+Vector(math.sin(rand)*150,math.cos(rand)*150,100)) then
						table.insert(self.PikiList,0)
					end
				end
				self:TriggerOutput("OnCreate",self,pikCount)
				if self.EXID > 0 then self.EXID = self.EXID - 1 end
			end)
			v:Remove()
		end
	end
	self:NextThink(CurTime())
	return true
end

function ENT:CanProperty(ply,prop)
	if prop == "skin" then
		timer.Simple(0.1,function()
			self.Skin = self:GetSkin()
			self.Color = self.Skin == 2 and 1 or self.Skin == 1 and 2 or self.Skin == 0 and 3
		end)
	end
	return true
end

function ENT:Call(ply,call,send)
	if call > 0 or send > 0 then self.NextUse = CurTime() + 0.5 end
	if send > 0 then
		local pikiCount = 0
		for _,v in ipairs(ents.FindByClass("pikmin")) do
			if not v.PikPly and v.Color == self.Color and v.Leader == ply and not v.Dismissed and (v.PikMdl.CurAnim == 1 or v.PikMdl.CurAnim == 2 or v.PikMdl.CurAnim == 5) then
				pikiCount = pikiCount + 1
				table.insert(self.PikiList,v.Level)
				v:Remove()
				if pikiCount == send then break end
			end
		end
		if pikiCount > 0 then self:TriggerOutput("OnReturn",self,pikiCount) end
	end
	if call > 0 and #self.PikiList >= call then
		timer.Create("call"..self:EntIndex(),0.1,1,function()
			for i=1,call do
				if PikminCreateServer(ply,{level=self.PikiList[#self.PikiList],color=self.Color}) then
					table.remove(self.PikiList,#self.PikiList)
				end
			end
		end)
		self:TriggerOutput("OnCall",self,call)
	end
end

function ENT:Use(activator,caller)
	if CurTime() < self.NextUse then return end
	if activator:IsPlayer() then
		local pikiCount = 0
		for _,v in ipairs(ents.FindByClass("pikmin")) do
			if not v.PikPly and v.Color == self.Color and v.Leader == activator and not v.Dismissed and (v.PikMdl.CurAnim == 1 or v.PikMdl.CurAnim == 2 or v.PikMdl.CurAnim == 5) then
				pikiCount = pikiCount + 1
			end
		end
		local TooMany = #ents.FindByClass("pikmin")+#ents.FindByClass("pikmin_sprout") >= PIKMIN_MAXFIELD and " 1" or ""
		activator:ConCommand("pikmin_onion "..self:GetSkin().." "..#self.PikiList.." "..pikiCount..TooMany)
	end
end

local function IsValidFood(obj)
	return obj:GetClass() == "prop_physics" and table.KeyFromValue(PikiCarryOnionList,obj:GetModel())
end

function ENT:Pull(obj)
	if not IsValidFood(obj) then return end
	obj.PikIgnore = true
	table.insert(self.PullTable,obj)
end

function ENT:PreEntityCopy()
	duplicator.StoreEntityModifier(self,"PikInfo",{Skin=self.Skin,PikiList=self.PikiList})
	self.SaveOnly = true
end

function ENT:PostEntityPaste(ply,ent,created)
	local pikinfo = ent.EntityMods.PikInfo
	if pikinfo then
		self.Skin = pikinfo.Skin
		self:SetSkin(self.Skin)
		self.PikiList = pikinfo.PikiList
		self.PullTable = {}
		self.EXID = 0
		self.Color = self.Skin == 2 and 1 or self.Skin == 1 and 2 or self.Skin == 0 and 3
		self.SaveOnly = true
	end
	ent.EntityMods = nil
end

function ENT:OnRemove()
	local idx = self:EntIndex()
	timer.Remove("vis"..idx)
	timer.Remove("land"..idx)
	timer.Remove("call"..idx)
	timer.Remove("suck"..idx)
	for i=1,self.EXID do
		timer.Remove("expel"..idx..i)
	end
	if not self.SaveOnly then SetPikiOnionData(self.Skin,self.PikiList) end
end