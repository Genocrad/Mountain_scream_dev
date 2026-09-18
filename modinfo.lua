local MS_LANGUAGE = 'en'
name = "Mountain Scream"
description = [[

󰀛Find the mountain totem and explore the mountain
󰀛featuring new content and conquer Mount Wumpet
]]
if locale == "zh" or locale == "zht" or locale == "zhr" then
    MS_LANGUAGE = 'ch'
    name = "Mountain Scream-山啸"
    description = [[

󰀛寻找山之图腾，探索群山
󰀛体验全新内容，征服温佩特山！
]]
elseif locale == "ru" then
    MS_LANGUAGE = 'ru'
    name = "Mountain Scream-Горный крик"
    description = [[

󰀛Найти горный тотем и исследовать горы
󰀛предлагает новые возможности и покорить гору Вумпет
]]
end

author = "Milanjorim, luigi.m.mario, 你要帮帮威吊"
version = "1.0.2"
forumthread = "/"

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

client_only_mod = false
all_clients_require_mod = true
server_only_mod = false
dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true
api_version = 10
server_filter_tags = {"ms", "mountain"}


local function get_lang_text(text_map, lang)
    return (text_map and text_map[lang]) or (text_map and text_map.en) or ""
end
local function make_title(label)
    return { name = "Title", label = label or "", options = {{description = "", data = ""}}, default = "" }
end
local CONFIG_TEXT = {
    sections = {
        game = { ch = "游戏设置", ru = "Настройки игры", en = "Game Settings" },    },
    labels = {
        language = { ch = "游戏语言", ru = "Язык игры", en = "Game Language" },
        enable_collision_for_player = { ch = "山体边缘碰撞", ru = "Столкновение на краю горы", en = "Enable edge collision for players" },
    },
    hovers = {
        language = { ch = "设置游戏内的语言", ru = "Устанавливает язык игры", en = "Sets the in-game language." },
        enable_collision_for_player = { ch = "防止玩家从山体边缘坠落", ru = "Предотвращает падение с горы", en = "Prevents falling from the mountain" },
    },
}
local CONFIG_SCHEMA = {
    { type = "section", key = "game" },
    { type = "setting", name = "language", default = { ch = "ch", en = "en", ru = "ru" }, options = {
        { data = "en", text = { ch = "英文", ru = "Английский", en = "English" } },
        { data = "ch", text = { ch = "中文", ru = "Китайский", en = "Chinese" } },
        { data = "ru", text = { ch = "俄文", ru = "Русский", en = "Russian" } },
    }},
    { type = "setting", name = "enable_collision_for_player", default = false, options = {
        { data = false, text = { ch = "禁用", ru = "Отключить", en = "Disable" } },
        { data = true, text = { ch = "启用", ru = "Включить", en = "Enable" } },
    }},
}
local function build_configuration_options(lang)
    local options = {}
    for i = 1, #CONFIG_SCHEMA do
        local item = CONFIG_SCHEMA[i]
        if item.type == "spacer" then
            options[#options + 1] = make_title("")
        elseif item.type == "section" then
            options[#options + 1] = make_title(get_lang_text(CONFIG_TEXT.sections[item.key], lang))
        elseif item.type == "setting" then
            local setting_options = {}
            local raw_opts = item.options or {}
            for j = 1, #raw_opts do
                local opt = raw_opts[j]
                setting_options[#setting_options + 1] = {
                    description = get_lang_text(opt.text, lang),
                    data = opt.data,
                }
            end
            local default_value = (item.name == "language") and (item.default[lang] or item.default.en) or item.default
            options[#options + 1] = {
                name = item.name,
                label = get_lang_text(CONFIG_TEXT.labels[item.name], lang),
                hover = get_lang_text(CONFIG_TEXT.hovers[item.name], lang),
                options = setting_options,
                default = default_value,
            }
        end
    end
    return options
end

configuration_options = build_configuration_options(MS_LANGUAGE)
game_modes = {
	{
        name = "ms_survival",
      	label = "Survive",
      	description = "The Hunt is a game mode where you have to defend against endless waves of monsters!",
      	settings = {
			level_type = "MOUNTAIN_SCREAM_DUNGEON",
			spawn_mode = "fixed",
		},
	}
}