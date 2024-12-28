--//Duplicator
duplicator.Allow("pikmin")
duplicator.Allow("pikmin_onion")
duplicator.Allow("pikmin_bud")
duplicator.RegisterEntityClass("pikmin_model", function(ply,data) return end, "Data")
duplicator.RegisterEntityClass("pikmin_logic", function(ply,data) return end, "Data")
duplicator.RegisterEntityClass("pikmin_player", function(ply,data) return end, "Data")
duplicator.RegisterEntityClass("pikmin_bud", function(ply,data)
	data.CurAnim = 1
	data.LastAnim = nil
	data.SpitNext = nil
	local ent = ents.Create("pikmin_bud")
	duplicator.DoGeneric(ent,data)
	--[[if data.CurPiki ~= 0 then
		ent.SpitNext = CurTime()+2 ent.CurPiki = data.CurPiki
	end--]]
	if data.EntityMods and data.EntityMods.PikInfo then
		ent.Cycle = data.EntityMods.PikInfo.Cycle
	end
	ent:Spawn()
	ent:Activate()
	return ent
end, "Data")
duplicator.RegisterEntityClass("pikmin_nectar", function(ply,data)
	data.Debounce = false
	return duplicator.GenericDuplicatorFunction(ply,data)
end, "Data")
duplicator.RegisterEntityClass("pikmin_sprout", function(ply,data)
	local ent = ents.Create("pikmin_sprout")
	duplicator.DoGeneric(ent,data)
	ent.Planted = true
	ent.SaveOnly = true
	ent:Spawn()
	ent:Activate()
	return ent
end, "Data")


--//Physgun Restrictions
local NoPickupList = {
"pikmin_fire",
"pikmin_gas",
"pikmin_wire",
"pikmin_model",
"pikmin_sprout",
"pikmin_bud"
}

hook.Add("PhysgunPickup","PikiPhys",function(ply,ent)
	if ent.PikIgnore or table.KeyFromValue(NoPickupList,ent:GetClass()) then return false end
	return GAMEMODE:PhysgunPickup(ply,ent)
end)