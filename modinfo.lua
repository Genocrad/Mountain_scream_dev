name = "MS ZEROGUZOK"
description = "..."
author = "luigi.m.mario"
version = "1.1"
forumthread = "/"
icon_atlas = "modicon.xml"
icon = "modicon.tex"
client_only_mod = false
all_clients_require_mod = true
server_only_mod = false
dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true
api_version = 10
server_filter_tags = {"archipelago","islands"}
configuration_options = {
	
}
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