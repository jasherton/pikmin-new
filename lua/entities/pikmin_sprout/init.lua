AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Planted = false

function ENT:KeyValue(key,value)
	if key == "model" then
		local idx = tonumber(value) or 0
		self.Color = math.floor(idx/3)+1
		self.Level = idx%3+1
	end
	if string.Left(key,2) == "On" then
		self:StoreOutput(key,value)
	end
end

function ENT:Initialize()
	if #ents.FindByClass("pikmin") == 100 then self:Remove() return end
	if not self.Planted then
		local tr = util.QuickTrace(self:GetPos(), vector_up * -10000, ents.GetAll())
		if tr.HitWorld then
			self:SetPos(tr.HitPos + tr.HitNormal*-12)
		else
			self:Remove()
			return
		end
	end
	self.Color = self.Color or 1
	self.Level = 1
	self.NextBloom = CurTime()+math.random(6,10)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetModel(PIKMIN_PHYMDL[self.Color])
	self:DrawShadow(false)
	local mdl = ents.Create("pikmin_model")
	mdl.CurAnim = 11
	mdl:SetNWInt("Level",self.Level)
	mdl:SetNWInt("Color",self.Color)
	mdl:SetNWBool("Dismissed",true)
	mdl:SetModel(string.format(PIKMIN_COLMDL[self.Color],self.Level))
	mdl:SetPos(self:GetPos()-self:GetUp()*13)
	mdl:SetAngles(self:GetAngles())
	mdl:SetParent(self)
	if self.Color == 5 then self:SetPos(self:GetPos()+self:GetUp()*3.25) end
	mdl:Spawn()
	mdl:Activate()
	self.PikMdl = mdl
	if not self.SaveOnly then self:EmitSound("pikmin/burrow.wav", 100, math.random(98, 105)) end
end

function ENT:SpawnFunction(ply,tr)
	ply:ConCommand("pikmin_menu 1")
end

function ENT:Think()
	if self.Level < 3 then
		if CurTime() >= self.NextBloom then
			self.NextBloom = CurTime()+math.random(8,14)
			self.Level = self.Level + 1
			self.PikMdl:SetModel(string.format(PIKMIN_COLMDL[self.Color],self.Level))
			self.PikMdl:SetNWInt("Level",self.Level)
			self.PikMdl.LastAnim = nil
			self:EmitSound(self.Level == 3 and "pikmin/upgrade2.wav" or "pikmin/upgrade.wav", 100, math.random(98, 105))
			local effectdata = EffectData()
			effectdata:SetFlags(self.Level)
			effectdata:SetEntity(self.PikMdl)
			effectdata:SetStart(PIKMIN_FLOWER_COLORS[self.Color])
			util.Effect("pikmin_leveldown", effectdata)
		end
	end
	self:NextThink(CurTime())
	return true
end

function ENT:Pluck(owner,auto)
	if owner:IsPlayer() then
		self:TriggerOutput("OnPlucked",self)
		local args = {color=self.Color,level=self.Level}
		if auto then args.pos = self:GetPos()+Vector(0,0,28) end
		self:Remove()
		timer.Simple(0.05,function()
			local ent = PikminCreateServer(owner,args)
			if ent then ent:EmitSound("pikmin/pikmin_pluck.wav") end
		end)
	end
end

function ENT:StartTouch(thing)
	if thing:IsPlayer() then
		self:Pluck(thing)
	end
end

function ENT:OnTakeDamage(DamageInfo) end

--Duplicator/Save
function ENT:PreEntityCopy()
	local data = {
		Color=self.Color,
		Level=self.Level,
		Cycle=self.PikMdl:GetCycle(),
		BloomOffset=self.NextBloom-CurTime(),
		Pos=self:GetPos()
	}
	duplicator.StoreEntityModifier(self,"PikInfo",data)
end

function ENT:PostEntityPaste(ply,ent,created)
	local pikinfo = ent.EntityMods.PikInfo
	if pikinfo then
		self.Color = pikinfo.Color
		self.Level = pikinfo.Level
		self.NextBloom = CurTime()+pikinfo.BloomOffset
		self:SetModel(PIKMIN_PHYMDL[self.Color])
		self.PikMdl:SetNWInt("Color",self.Color)
		self.PikMdl:SetNWInt("Level",math.min(3,self.Level))
		self.PikMdl:SetModel(string.format(PIKMIN_COLMDL[self.Color],self.Level))
		self.PikMdl.Cycle = pikinfo.Cycle
		self:SetPos(pikinfo.Pos)
	end
	ent.EntityMods = nil
end