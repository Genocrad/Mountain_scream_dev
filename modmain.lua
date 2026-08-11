
GLOBAL.MS_FOCALPOINT_FLOORS = {}
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- 测试命令
require("debugcommands")
-- 初始化文本
require("ms_strings/strings")
local characters = {
    "wilson", -- 需要补充更多人的描述文本
}
for i, character in ipairs(characters) do
    require("ms_strings/"..character)
end
local translation = GetModConfigData("language")
if translation ~= "en" then
    require("ms_strings/"..translation.."/strings")
    for i, character in ipairs(characters) do
        require("ms_strings/"..translation.."/"..character)
    end
end

-- Must load before postinit (COLLISION.MS_CLOUDS / TUNING.MS_*)
modimport("init/init_tuning")
modimport("init/init_postinit")
modimport("init/init_falloffs")
modimport("init/init_containers")
modimport("init/init_assets")
-- modimport("init/init_strings")
modimport("init/init_prefabs")
modimport("init/init_recipes")
modimport("init/init_actions")
modimport("init/init_cooking")
modimport("init/init_tornado_sorbet")
modimport("init/init_forging")
modimport("init/init_rpc")

if GLOBAL.rawget(GLOBAL, "MountainWalls") == nil then
	GLOBAL.rawset(GLOBAL, "MountainWalls", {})
end
