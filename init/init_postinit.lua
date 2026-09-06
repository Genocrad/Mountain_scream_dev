modimport("postinit/standartcomponents")
modimport("postinit/containers")

modimport("postinit/prefabs/player_common")
modimport("postinit/prefabs/wortox")
modimport("postinit/prefabs/wolfgang")
modimport("postinit/prefabs/caves")
modimport("postinit/prefabs/goldnugget")

modimport("postinit/stategraphs/wilson")
modimport("postinit/stategraphs/wilson_client")


modimport("postinit/components/builder")
modimport("postinit/components/camera")
modimport("postinit/components/drownable")
modimport("postinit/components/stewer")
modimport("postinit/components/temperature")
modimport("postinit/components/playervision")
modimport("postinit/components/teleporter")
modimport("postinit/components/savedrotation")
modimport("postinit/components/dynamicmusic")

modimport("postinit/widgets/mapwidget")
modimport("postinit/widgets/uiclock")

-- 全局控制：魔像/魔柱存在时锁定全部 mountain_golem_platform
local function EnsurePlatformCtrl(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.mountain_golem_platformctrl == nil then
		inst:AddComponent("mountain_golem_platformctrl")
	end
end
AddPrefabPostInit("forest", EnsurePlatformCtrl)
AddPrefabPostInit("cave", EnsurePlatformCtrl)
AddSimPostInit(function()
	if TheWorld ~= nil then
		EnsurePlatformCtrl(TheWorld)
	end
end)
