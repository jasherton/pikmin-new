AddCSLuaFile()
ENT.Base = "base_nextbot"
ENT.Spawnable = false

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetModel("models/pikmin/pikmin_collision.mdl")
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

function ENT:Draw()
end

function ENT:BehaveStart()
end

function ENT:RunBehaviour()
end

function ENT:WaterPathFunc(area,from,ladder,elevator,length)
	if not IsValid(from) then
		return 0
	else
		if not self.loco:IsAreaTraversable(area) then
			return -1
		end
		
		local dist = 0
		
		if IsValid(ladder) then
			return -1
		elseif length > 0 then
			dist = length
		else
			dist = ( area:GetCenter() - from:GetCenter() ):GetLength()
		end

		local cost = dist + from:GetCostSoFar()
		
		local deltaZ = from:ComputeAdjacentConnectionHeightChange(area)
		if deltaZ >= self.loco:GetStepHeight() then
			if deltaZ >= self.loco:GetMaxJumpHeight() then
				return -1
			end
			cost = cost + 5 * dist
		end
		
		return cost
	end
end

function ENT:PathFunc(area,from,ladder,elevator,length)
	if not IsValid(from) then
		return 0
	else
		if not self.loco:IsAreaTraversable(area) or area:IsUnderwater() then
			return -1
		end
		
		local dist = 0

		if IsValid(ladder) then
			return -1
		elseif length > 0 then
			dist = length
		else
			dist = ( area:GetCenter() - from:GetCenter() ):GetLength()
		end

		local cost = dist + from:GetCostSoFar()
		
		local deltaZ = from:ComputeAdjacentConnectionHeightChange(area)
		if deltaZ >= self.loco:GetStepHeight() then
			if deltaZ >= self.loco:GetMaxJumpHeight() then
				return -1
			end
			cost = cost + 5 * dist
		elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
			return -1
		end
		
		return cost
	end
end