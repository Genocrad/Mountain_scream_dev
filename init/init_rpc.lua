AddClientModRPCHandler("MountainScream", "mountainWallData", function(id, wall_type, uv, void_x, void_z, rebuild, kind, rot, pos_x, pos_z)
	local walls = GLOBAL.rawget(GLOBAL, "MountainWalls")
	if walls == nil then
		walls = {}
		GLOBAL.rawset(GLOBAL, "MountainWalls", walls)
	end
	walls[id] = {
		type = wall_type,
		uv = uv,
		void_x = void_x,
		void_z = void_z,
		kind = (kind ~= nil and kind ~= "" and kind) or "straight",
		rot = rot or 0,
		x = pos_x,
		z = pos_z,
	}

	if rebuild and GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.components.mountainwallrenderer ~= nil then
		local renderer = GLOBAL.TheWorld.components.mountainwallrenderer
		renderer.rebuild = renderer.rebuild or {}
		renderer.rebuild[id] = true
		renderer:Rebuild()
	end
end)

AddClientModRPCHandler("MountainScream", "mountainWallsRebuild", function()
	if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.components.mountainwallrenderer ~= nil then
		GLOBAL.TheWorld.components.mountainwallrenderer:RebuildAll()
	end
end)
