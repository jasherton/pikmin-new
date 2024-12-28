AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:SpawnFunction(ply,tr)
	ply:ConCommand("pikmin_menu")
end

function ENT:SetLevel(num)
	if num > self.Level then self.PikHP = PIKMIN_HEALTH[self.Color] end
	self.Level = num
	self.PikMdl:SetModel(string.format(PIKMIN_COLMDL[self.Color],self.Level))
	self.PikMdl.LastAnim = nil
	self.PikMdl:SetNWInt("Level",self.Level)
	self.MoveForce = self.BaseMoveForce + (self.Level-1)*100
	--self.MoveForce = math.min(self.BaseMoveForce + (self.Level-1)*(self.Color == 5 and 320 or self.Color == 4 and 150 or 250),1250)
end

function ENT:KeyValue(key,value)
	if key == "model" then
		local idx = tonumber(value) or 0
		self.Color = math.floor(idx/3)+1
		self.Level = idx%3+1
	end
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:Initialize()
	self.Color = self.Color or 1
	self.Level = self.Level or 1
	self.PikHP = PIKMIN_HEALTH[self.Color]
	self.Dead = self.Dead or false
	self.Target = self.Target or nil
	self.NextHop = 0
	self.NextObHop = 0
	self.ThrowNext = 0
	
	--//flower level does not affect the damage value
	--//only affects the amount of time it takes for tasks to be completed (bridges/etc)
	self.Damage = PIKMIN_DAMAGE[self.Color]*PIKMIN_DAMAGE_MULT
	
	--//death timer (drown/poison/etc)
	--self.HazardTimer = nil
	
	--//time until drowning pikmin stop swimming towards their leader
	--self.SwimTimer = nil
	
	--//time until next attack
	--self.AttackTimer = nil
	
	self.BaseMoveForce = self.Color == 4 and 600 or self.Color == 5 and 1000 or 700
	self.ZForceVector = self.Color == 4 and Vector(0,0,425) or Vector(0,0,325)
	self.JumpVector = Vector(0,0,self.Color == 4 and 2000 or 1750)
	self.MoveForce = 0
	
	self:SetModel(PIKMIN_PHYMDL[self.Color])
	
	--//SetModel must be called before Spawn or NPCs will ignore us
	local mdl = self.PikMdl
	if not mdl then
		mdl = ents.Create("pikmin_model")
		self.PikMdl = mdl
		self:SetLevel(self.Level)
		mdl:SetPos(self:GetPos())
		mdl:SetAngles(self:GetAngles())
		mdl:SetParent(self)
		mdl:Spawn()
		mdl:Activate()
	end
	self:SetLevel(self.Level)
	mdl:SetNWInt("Color",self.Color)
	mdl:SetNWInt("Level",self.Level)
	
	if not self.Phys then
		self:SetMoveCollide(MOVECOLLIDE_FLY_SLIDE)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(false)
		self:StartMotionController()
		self:SetCustomCollisionCheck(true)
		local phys = self:GetPhysicsObject()
		self.Phys = phys
		if IsValid(phys) then
			phys:SetBuoyancyRatio(.375)
			phys:Wake()
		end
	end
	
	if not self.Leader or self.Dismissed then self:Disband() end
	if self.Leader and IsValid(self.Leader) and self.Leader:GetNWBool("ispikmin") then self:Disband() end
	self:SetNWEntity("Leader",self.Leader)
	self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
end

local ZeroVector = Vector(0,0,0)
function ENT:PhysicsSimulate(phys,delta)
	local TargetPos = self.TargetPos or IsValid(self.Target) and self.Target:GetPos() or IsValid(self.Leader) and self.Leader:GetPos()
	phys:Wake()
	if self.params == nil then self.params = table.Copy(PIKMIN_SHADOW_PARAMS) self.params.angle = self:GetAngles() end
	local params = self.params
	params.pos = ZeroVector
	params.angle = (self.Thrown or self.Attacking or self.Carrying) and self.params.angle or TargetPos and (TargetPos - self:GetPos()):Angle() or self.params.angle
	params.angle.p = 0
	params.deltatime = delta
	phys:ComputeShadowControl(params)
end

function ENT:Disband(TargetPos)
	if self.Hazard then return end
	if self.Attacking then return end
	if TargetPos then
		self.DismissTimer = CurTime() + 2
	else
		self.DismissTimer = CurTime() + 1
	end
	self.TargetPos = TargetPos
	self.Dismissed = true
	self.Leader = nil
	self:SetNWEntity("Leader",self)
	self.Target = nil
	self:SetNWBool("Target",false)
	self.PikMdl:SetNWBool("Dismissed",true)
end

--//call pikmin (remove status effects or set new leader)
function ENT:Call(Leader)
	if self.Drinking then return end
	if self.Dismissed or not IsValid(self.Leader) then
		self.TargetPos = nil
		self.Dismissed = false
		self.PikMdl:SetNWBool("Dismissed",false)
		self.Leader = Leader
		self:SetNWEntity("Leader",Leader)
		self.PikMdl.CurAnim = 7
		if not self.Hazard and not IsValid(self:GetParent()) then
			self.Called = true
			self:EmitSound("pikmin/coming.wav")
			timer.Remove("call" .. self:EntIndex())
			timer.Create("call" .. self:EntIndex(), 0.325, 1, function() self.Called = false end)
		end
	end
	if self.Leader == Leader then
		--//Drop Current Task
		if self.Target then
			self.Target = nil
			self.Attacking = false
			self:SetNWBool("Target",false)
			if IsValid(self:GetParent()) then
				local quickpos = self:GetPos() + Vector(0,0,8)
				self:SetParent()
				self:SetPos(quickpos)
			end
		end
		--//Hazard Removal
		if self.Hazard then
			if self.Hazard == HAZARD_WATER then
				self.SwimTimer = CurTime() + 5
			elseif self.Hazard == HAZARD_FIRE or self.Hazard == HAZARD_POISON then
				self:SetHazard()
			end
		end
	end
end

--//set entity as new target
function ENT:Charge(Target)
	self.Target = Target
	self:SetNWBool("Target",IsValid(self.Target))
	self.Attacking = false
	if self.Dismissed then
		self.Dismissed = false
		self.PikMdl:SetNWBool("Dismissed",false)
	end
end

--//grab onto entity
function ENT:LatchOn(ent)
	if self.Leader == ent then return end
	if ent:GetClass() == "pikmin_gas" and not (self.Color == 5 or self.Color == 6) then self:SetHazard(HAZARD_POISON) return end
	if self.Color == 4 and self.Thrown then
		ent:TakeDamage(10,self,self)
		self:EmitSound("physics/body/body_medium_impact_hard" .. math.random(4, 6) .. ".wav")
		self.AttackTimer = CurTime() + 1
	else
		self.AttackTimer = 0
	end
	self.Attacking = true
	self.Thrown = false
	self.Target = ent
	timer.Simple(0,function()
		self.Phys:SetVelocity(Vector(0,0,0))
		self:SetParent(ent)
	end)
end

function ENT:MoveTo(TargetPos,MinDist,WalkSpeed,Immediate)
	local CurPos = self:GetPos()
	local TargetDist = CurPos:DistToSqr(TargetPos)
	local Speed = self:GetVelocity():Length()
	local CTime = CurTime()
	
	MinDist = MinDist*MinDist
	if TargetDist > MinDist and (CTime >= self.NextHop or Immediate) then
		self.NextHop = CTime + 0.1
		local InWater = self:WaterLevel() >= 1
		if Speed <= WalkSpeed*0.25 then
			local dirVec = TargetPos - CurPos
			if InWater and not self.Hazard then
				self.Phys:ApplyForceCenter(dirVec * (self.Color == 6 and 30 or 10))
			else
				local finalVec = Vector(dirVec.X,dirVec.Y,0):GetNormalized()
				local finalSpeed = WalkSpeed
				--local finalSpeed = WalkSpeed * math.Clamp(TargetDist/MinDist - 1,0.25,1)
				if self.Hazard then
					self.Phys:ApplyForceCenter(finalVec * finalSpeed)
				else
					self.Phys:ApplyForceCenter(finalVec * finalSpeed + self.ZForceVector)
				end
			end
		end
		if CTime >= self.NextObHop then
			self.NextObHop = CTime + 1
			if not InWater then
				local qpos = CurPos + Vector(0,0,4)
				local tr = util.QuickTrace(qpos, self:GetForward() * 20, function() return false end)
				if tr.HitWorld then
					self.Phys:ApplyForceCenter(self.JumpVector)
				end
			end
		end
	end
	
	return TargetDist,Speed
end

function ENT:SetHazard(num)
	self.SwimTimer = nil
	if not num then
		num = self.Hazard
		if not num then return end
		if self.Dismissed then self.PikMdl:SetNWBool("Dismissed",true) end
		if self.Hazard == HAZARD_WATER then
			self.Phys:SetBuoyancyRatio(.375)
			self:StopSound("pikmin/drowning.wav")
		elseif self.Hazard == HAZARD_FIRE then
			self:Extinguish()
		elseif num == HAZARD_POISON then
			self.PikMdl:SetNWBool("Poison",false)
		end
		self.Hazard = nil
		return
	end
	if self.Hazard ~= num then
		self.Hazard = num
		self.HazardTimer = CurTime() + 7
		self.CryTimer = 0
		self.PikMdl:SetNWBool("Dismissed",false)
		self.PikMdl:SetNWBool("Poison",false)
		self.Thrown = false
		self:Charge()
		if num == HAZARD_WATER then
			local vel = self.Phys:GetVelocity()
			self.Phys:SetVelocity(Vector(vel[1],vel[2],0))
			self.Phys:SetBuoyancyRatio(1)
			self:EmitSound("pikmin/drowning.wav")
			self:Extinguish()
		elseif num == HAZARD_SHOCK then
			self:Die()
		elseif num == HAZARD_POISON then
			self.PikMdl:SetNWBool("Poison",true)
			self:Extinguish()
		end
	end
end

--//performance in milliseconds
function ENT:Benchmark(FPS,Finish)
	if not Finish then self.LastBench = os.clock() return end
	if self.LastBench then
		self.BenchTime = os.clock()-self.LastBench
		PIKMIN_BENCHMARK_NUM = PIKMIN_BENCHMARK_NUM and PIKMIN_BENCHMARK_NUM+1 or 1
		if PIKMIN_BENCHMARK_NUM >= #ents.FindByClass(self.ClassName)*FPS then
			ents.FindByClass("player")[1]:ChatPrint((PIKMIN_BENCHMARK_TIME/PIKMIN_BENCHMARK_NUM)*1000000)
			PIKMIN_BENCHMARK_NUM = 0
			PIKMIN_BENCHMARK_TIME = 0
		else
			PIKMIN_BENCHMARK_TIME = PIKMIN_BENCHMARK_TIME and PIKMIN_BENCHMARK_TIME+self.BenchTime or self.BenchTime
		end
	end
end

function ENT:ThinkIdle()
	self.PikMdl.CurAnim = 8
	--self:Benchmark(30)
	--experimental range similar to pikmin 2
	local dist = 128*128
	--THIS IS WAY FASTER THAN FINDINSPHERE (took about 2 hours to code)
	local pos = self:GetPos()
	local mdl = self.PikMdl
	for _,v in ipairs(PIKMIN_CHARGE_TABLE) do
		if not IsValid(v) then continue end
		local ndist = v:GetPos():DistToSqr(pos)
		if ndist > dist then continue end
		dist = ndist
		if v.ClassName == "pikmin_nectar" and self.Level ~= 3 then self:Charge(v) return end
		if v:Health() <= 0 then continue end
		if v.ClassName == "pikmin_fire" or v.ClassName == "pikmin_gas" or v.ClassName == "pikmin_wire" then self:Charge(v) return end
		if mdl:Disposition(v) == D_HT then self:Charge(v) return end
	end
	
	--[[local tab = ents.FindInSphere(self:GetPos(),128)
	for _,v in ipairs(tab) do
		if v:IsNPC() and self.PikMdl:Disposition(v) == D_HT and v:Health() > 0 then self:Charge() break end
		if v.ClassName == "pikmin_nectar" and self.Level ~= 3 then self:Charge() break end
		if (v.ClassName == "pikmin_fire" or v.ClassName == "pikmin_gas" or v.ClassName == "pikmin_wire") and v:Health() > 0 then self:Charge() break end
	end--]]
	--self:Benchmark(30,true)
end

function ENT:Think()
	self:NextThink(CurTime() + 0.03)
	if self.Dead then return false end
	if not IsValid(self.PikMdl) then self:Remove() return false end
	
	local ValidLeader = IsValid(self.Leader) and self.Leader
	if not self.Target and not self.Dismissed and (not ValidLeader or not self.Leader:Alive()) then self:Disband() end
	
	local InWater = self:WaterLevel() >= 1
	local IsHeld = ValidLeader and self:GetParent() == self.Leader
	local OnFire = self:IsOnFire()
	
	self.PikMdl:DrawShadow(not IsHeld and PIKMIN_DRAW_SHADOW or false)
	
	--if IsHeld and self.Target == self.Leader then
	--	self.Leader = nil
	--end
	
	if self.PikMdl:IsOnFire() then self.PikMdl:Extinguish() end
	
	local CTime = CurTime()
	
	--//Hazard Handling
	if self.Hazard then
		if CTime >= self.HazardTimer then self:Die() return true end
		if self.SwimTimer and ValidLeader and CTime < self.SwimTimer then
			self:MoveTo(self.Leader:GetPos(),0,self.MoveForce*0.5,true)
		end
		if OnFire or self.Hazard == HAZARD_POISON then
			local TargetPos = self:GetPos() + Vector(math.Rand(-500,500), math.Rand(-500,500), 0)
			self:MoveTo(TargetPos,200,self.BaseMoveForce+500)
			if CTime >= self.CryTimer then
				self.CryTimer = CTime + math.Rand(0.5,1)
				local snds = PIKMIN_SOUND_CRY[self.Hazard]
				self:EmitSound(snds[math.random(#snds)])
			end
		end
		if IsHeld then
			self.Leader:SetNWEntity("piki",self.Leader)
			self.Leader:StopSound("pikmin/grab.wav")
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetPos(Vector(0,0,0))
			self:SetParent()
		end
		if IsValid(self:GetParent()) then
			local quickpos = self:GetPos() + Vector(0,0,8)
			self:SetParent()
			self:SetPos(quickpos)
		end
	end
	
	--//Shock Hazard
	if self.Hazard == HAZARD_SHOCK then return true end
	
	--//Water Hazard
	if InWater and self.Color ~= 3 and self.Color ~= 6 then
		self.PikMdl.CurAnim = 6
		if self.Hazard ~= HAZARD_WATER then
			self:SetHazard(HAZARD_WATER)
		end
		return true
	end
	
	--//Poison Hazard
	if self.Hazard == HAZARD_POISON and self.Color ~= 5 and self.Color ~= 6 then
		self.PikMdl.CurAnim = 10
		return true
	end
	
	--//Fire Hazard
	if OnFire and self.Color ~= 1 and self.Color ~= 6 then
		self.PikMdl.CurAnim = 10
		if self.Hazard ~= HAZARD_FIRE then
			self:SetHazard(HAZARD_FIRE)
		end
		return true
	else
		self:Extinguish()
	end
	
	--//Hazard Finished
	self:SetHazard(nil)
	
	if self.Called then return true end
	if self.Thrown then self.PikMdl.CurAnim = 3 return true end
	if IsHeld then self.PikMdl.CurAnim = 10 return true end
	
	--//Attack Behavior
	if IsValid(self.Target) and self.Attacking then
		self.PikMdl.CurAnim = 4
		if self.Target:IsOnFire() then self:Ignite(1000,0) end
		if CTime >= self.AttackTimer then
			self.AttackTimer = CTime + 0.75
			local dmg = self.Damage
			if self.Target:Health() - dmg <= 0 then
				for k,v in ipairs(self.Target:GetChildren()) do
					if v ~= self and v:GetClass() == "pikmin" then
						v.Target = nil
						v:SetNWBool("Target",false)
						v.Attacking = false
						local quickpos = v:GetPos() + Vector(0,0,8)
						v:SetParent()
						v:SetPos(quickpos)
					end
				end
				self.Attacking = false
				local quickpos = self:GetPos() + Vector(0,0,8)
				self:SetParent()
				self:SetPos(quickpos)
				self.Target:TakeDamage(dmg, self.PikPly and self or self.Leader or self, self)
				self.Target = nil
				self:SetNWBool("Target",false)
			else
				self.Target:TakeDamage(dmg, self.PikPly and self or self.Leader or self, self)
			end
			self:EmitSound("pikmin/hit.wav", 100, math.random(98, 105))
		end
		return true
	end
	
	if self.Drinking then self.PikMdl.CurAnim = 9 return true end
	
	if self.Dismissed then
		if PIKMIN_AUTO_THINK and not self.DismissTimer then self:ThinkIdle(PIKMIN_AUTO_THINK) end
		if self.Dismissed then
			if self.DismissTimer then
				if CTime < self.DismissTimer then
					if self.TargetPos then
						local TargetDist = self:MoveTo(self.TargetPos,50,400)
						if TargetDist <= 50*50 then
							self.TargetPos = nil
							self.DismissTimer = nil
						end
					end
				else
					self.TargetPos = nil
					self.DismissTimer = nil
				end
			end
			local Speed = self:GetVelocity():Length()
			self.PikMdl.CurAnim = InWater and 5 or Speed >= 6 and 1 or 8
			return true
		end
	end
	
	local CurTarget = IsValid(self.Target) and self.Target or ValidLeader and self.Leader
	local TargetPos = self.TargetPos or CurTarget and CurTarget:GetPos() or self:GetPos()
	local MinDist = 200
	
	if ValidLeader and CurTarget == self.Leader and self.Leader.SwarmVec then
		TargetPos = TargetPos+self.Leader.SwarmVec
		MinDist = 50
	end
	
	--replace this with type switching in the weapon (special keybinds; will perform way better)
	--the weapon should just let you select the pikmin type without actually moving them in the world
	--giving the same functionality as below but without the insane checks per frame
	--[[if ValidLeader and CurTarget == self.Leader then
		local HeldPik = self.Leader:GetNWEntity("piki")
		if IsValid(HeldPik) and HeldPik ~= self.Leader and not self.Leader.SwarmVec then
			if HeldPik.Color ~= self.Color or HeldPik.Level ~= self.Level then
				TargetPos = TargetPos - self.Leader:GetAngles():Forward()*140
				MinDist = 60
			else
				TargetPos = TargetPos - self.Leader:GetAngles():Forward()*40
				MinDist = 50
			end
		end
		if self.Leader.SwarmVec then
			TargetPos = TargetPos+self.Leader.SwarmVec
			MinDist = 50
		end
	end--]]
	
	if self.Target and (not IsValid(self.Target) or not CanPikminCharge(self.Target)) then self:Charge() end
	if IsValid(self.Target) and CurTarget == self.Target then MinDist = 0 end
	
	local TargetDist,Speed = self:MoveTo(TargetPos,MinDist,self.MoveForce)
	if CurTarget and TargetDist >= 1400*1400 then self:Disband() end
	
	self.PikMdl.CurAnim = InWater and 5 or Speed >= 6 and 1 or 2
	return true
end

function ENT:PikInteract(obj)
	if self.Drinking then return end
	if obj:GetClass() == "pikmin_nectar" then
		if self.Level == 3 then if self.Target == obj then self:Charge() end return end
		if (not self.Target or self.Target == obj) and not self.Hazard then
			self.Drinking = true
			timer.Simple(0,function() self:SetParent(obj) end)
			self:EmitSound("pikmin/suck.wav")
			obj:PikTrigger()
			return true
		end
	end
	if (self.Target == obj or (IsValid(self.Leader) and self.Leader.SwarmVec)) and CanPikminGrab(obj) then
		self:LatchOn(obj)
	end
	return
end

--//Used to detect a collision when thrown; stopping the spin animation
function ENT:PhysicsCollide(data,phys)
	--if data.HitEntity.Breakable and (self.Target == data.HitEntity or self.Thrown) then timer.Simple(0,function() self:LatchOn(data.HitEntity) end) return end
	--if data.HitEntity:GetClass() == "prop_physics" and data.TheirOldVelocity.Z <= -300 then timer.Simple(0,function() self:Die() end) return end
	if self.Thrown then
		if CanPikminGrab(data.HitEntity) then self:LatchOn(data.HitEntity) return end
		if data.HitEntity:IsWorld() or not self:PikInteract(data.HitEntity) then
			if (self.PikPly and self.Leader ~= self.PikPly) or not self.PikPly then
				self:Disband()
			end
		end
		self.Thrown = false
		--local validcarry = IsCarryObject(data.HitEntity)
		--if data.HitEntity:IsWorld() or (not data.HitEntity:IsNPC() and not data.HitEntity:IsPlayer()) or validcarry then
			--if validcarry then self:Charge(data.HitEntity) self.NextHop = CurTime()+1 end
			--if table.KeyFromValue(ValidEnemyList,data.HitEntity:GetClass()) and data.HitEntity:Health() > 0 then return end
			--if not self.PikPly and not data.HitEntity.PikInteract and not self.Target then self:Disband() end
			--self:Disband()
			--self.Thrown = false
		--end
	end
end

function ENT:StartTouch(obj)
	if obj:IsPlayer() then
		if self.Dismissed and obj:GetVelocity():Length() >= 120 then self:Call(obj) end
	end
	self:PikInteract(obj)
	if (obj:GetClass() == "prop_combine_ball") then
		if IsValid(self) and not self.Dissolving and not (self.Color == 2 or self.Color == 6) then
			self.Dissolving = true
			self:EmitSound("pikmin/pikmin_die.wav", 100, math.random(95, 110))
			local mdl = self:CreatePikRagdoll(true)
			local dissolve = ents.Create("env_entity_dissolver")
			dissolve:SetPos(mdl:GetPos())
			mdl:SetName(tostring(mdl))
			dissolve:SetKeyValue("target", mdl:GetName())
			dissolve:SetKeyValue("dissolvetype", "0")
			dissolve:Spawn()
			dissolve:Fire("Dissolve", "", 0)
			dissolve:Fire("kill", "", 1)
			dissolve:EmitSound(Sound("NPC_CombineBall.KillImpact"))
			mdl:Fire("sethealth", "0", 0)
			self:Remove()
		end
	end
end

function ENT:CreatePikRagdoll(dis)
	local mdl = self.PikMdl
	--w00t at TetaBonita for the ragdoll code!
	local rag = ents.Create("prop_ragdoll")
	rag:SetModel(mdl:GetModel())
	rag:SetPos(mdl:GetPos())
	rag:SetAngles(mdl:GetAngles())
	rag:Spawn()
	if not IsValid(rag) then
		return
	end
	rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	local entvel = self:GetVelocity()
	local entphys = self.Phys
	if IsValid(entphys) then entvel = entphys:GetVelocity() end
	for i = 1, rag:GetPhysicsObjectCount() do
		local bone = rag:GetPhysicsObjectNum(i)
		if IsValid(bone) then
			local bonepos,boneang = mdl:GetBonePosition(rag:TranslatePhysBoneToBone(i))
			bone:SetPos(bonepos)
			bone:SetAngles(boneang)
			if (dis) then --is this for the dissolve effect?
				bone:ApplyForceOffset(self:GetVelocity() * 0.04, self:GetPos())
				bone:AddVelocity(entvel * 0.05)
				bone:AddVelocity(Vector(0,0,10))
				bone:EnableGravity(false)
			else
				bone:ApplyForceOffset(self:GetVelocity(), self:GetPos())
				bone:AddVelocity(entvel)
			end
		end
	end
	rag:SetSkin(mdl:GetSkin())
	rag:SetColor(mdl:GetColor())
	rag:SetMaterial(mdl:GetMaterial())
	rag:Activate()
	return rag
end

local DeathSounds = {"pikmin/pikmin_die2.wav","pikmin/pikmin_die3.wav","pikmin/pikmin_die3.wav","pikmin/pikmin_shock.wav"}

local function DeathRagdoll(ent)
	if IsValid(ent) then
		local pos = ent:GetPos()
		local effectdata = EffectData()
		effectdata:SetOrigin(ent:GetPos() + Vector(0,0,15))
		effectdata:SetStart(PIKMIN_SOUL_COLORS[ent.Color]/2)
		if ent.Color == 6 then
			effectdata:SetScale(1)
			util.Effect("pikmin_tekisoul",effectdata)
		else
			util.Effect("pikmin_deathsoul",effectdata)
		end
		ent:EmitSound("pikmin/pikmin_pop.wav",100,math.random(95,110))
	end
end

function ENT:Die(FakeDeath)
	if self.Dead then return end
	self.Dead = true
	self.Thrown = false
	
	self.Leader = nil
	self:StopSound("pikmin/drowning.wav")
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	
	self:EmitSound(DeathSounds[self.Hazard] or "pikmin/pikmin_die.wav")
	
	self.PikMdl:DrawShadow(false)
	self.PikMdl:SetRenderMode(RENDERMODE_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self.Phys:EnableMotion(false)
	
	if FakeDeath then return end
	
	if self.Hazard == HAZARD_SHOCK then
		self.PikMdl:Remove()
		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		util.Effect("pikmin_shock",effectdata)
		timer.Simple(0.25,function() if not IsValid(self) then return end DeathRagdoll(self) self:Remove() end)
		return
	end
	
	local rag = self:CreatePikRagdoll(false)
	if self.BurnTick then rag:Ignite(math.Rand(8,10),0) end
	rag.Color = self.Color
	timer.Simple(math.Rand(1.6, 2.5),function() if not IsValid(rag) then return end DeathRagdoll(rag) rag:Remove() end) --Give it some random-ness, so they don't die in order so much
	self:Remove()
end

function ENT:OnRemove()
	self:StopSound("pikmin/drowning.wav")
end

function ENT:OnTakeDamage(DMGInfo)
	if self.Dead then return end
	local dmg,dmgType = DMGInfo:GetDamage(),DMGInfo:GetDamageType()
	
	if DMGInfo:IsDamageType(DMG_BURN) then if not (self.Color == 1 or self.Color == 6) then self:Ignite(1000,0) end return end
	
	if DMGInfo:IsDamageType(DMG_SHOCK) or DMGInfo:IsDamageType(DMG_ENERGYBEAM) then
		if self.Color == 2 or self.Color == 6 then return end
		self:SetHazard(HAZARD_SHOCK)
		return
	end
	
	local inflict = DMGInfo:GetInflictor()
	if DMGInfo:IsDamageType(DMG_POISON) and (inflict:GetClass() == "pikmin_gas" or inflict:GetClass() == "pikmin") then
		if not (self.Color == 5 or self.Color == 6) then self:SetHazard(HAZARD_POISON) end
		return
	end
	
	self.PikHP = self.PikHP - dmg
	if self.PikHP <= 0 then
		self:Die()
	else
		if self.Level > 1 then
			self:SetLevel(self.Level-1)
			local effectdata = EffectData()
			effectdata:SetFlags(self.Level)
			effectdata:SetEntity(self.PikMdl)
			effectdata:SetStart(PIKMIN_FLOWER_COLORS[self.Color])
			util.Effect("pikmin_leveldown", effectdata)
		end
	end
end

--Duplicator/Save support
function ENT:PreEntityCopy()
	local data = {
		Drinking=self.Drinking,
		Dead=self.Dead,
		Color=self.Color,
		Level=self.Level,
		params=self.params
	}
	if not self.PikPly then
		if IsValid(self.Leader) then
			if self.Leader:IsPlayer() then
				data.Leader = self.Leader:SteamID()
			else
				data.LeaderEnt = self.Leader:EntIndex()
			end
		end
	else
		data.Dead = true
	end
	if not self.Dead then
		data.Cycle=self.PikMdl:GetCycle()
		local parent = self:GetParent()
		if IsValid(parent) then data.Parent = parent:EntIndex() data.ppos = self:GetPos()-parent:GetPos() end
		if self.CarryObject and IsValid(self.CarryObject) then data.CarryObject = self.CarryObject:EntIndex() end
		if self.Target and IsValid(self.Target) then data.Target = self.Target:EntIndex() end
	end
	duplicator.StoreEntityModifier(self,"PikInfo",data)
end

function ENT:PostEntityPaste(ply,ent,created)
	local pikinfo = ent.EntityMods.PikInfo
	if pikinfo then
		if self.PikPly then self:Remove() return end
		if pikinfo.Dead then self:Remove() return end
		
		self.Color = pikinfo.Color
		self.Level = pikinfo.Level
		self.PikMdl.Cycle = pikinfo.Cycle
		self:Initialize()
		
		if pikinfo.Leader then
			local ply = player.GetBySteamID(pikinfo.Leader)
			if IsValid(ply) then
				self.Dismissed = false
				self.Leader = ply
				self:SetNWEntity("Leader",ply)
				self.PikMdl:SetNWBool("Dismissed",false)
			end
		end
		
		if pikinfo.LeaderEnt then
			local ent = created[pikinfo.LeaderEnt]
			if IsValid(ent) then
				self.Dismissed = false
				self.Leader = ent
				self:SetNWEntity("Leader",ent)
				self.PikMdl:SetNWBool("Dismissed",false)
			end
		end
		
		self.params = pikinfo.params
		
		if pikinfo.CarryObject then
			self.Carrying = false
			timer.Simple(0.1,function()
				local find = constraint.Find(self,created[pikinfo.CarryObject],"Weld",0,0)
				if find then find:Remove() end
				self:Charge(created[pikinfo.CarryObject])
			end)
		end
		
		if pikinfo.Target then
			self.Target = created[pikinfo.Target]
			if self.Attacking then
				self:SetPos(self.Target:GetPos()+pikinfo.ppos)
				self:SetParent(self.Target)
			else
				self:Charge(self.Target)
			end
		end
		
		if pikinfo.Drinking and pikinfo.Parent then
			local parent = created[pikinfo.Parent]
			parent:StartTouch(self)
		end
	end
	ent.EntityMods = nil
end