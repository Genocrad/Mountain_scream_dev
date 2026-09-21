--------------------------------------------------------
-- A: dungeon / forging / collision
TOOLACTIONS.TOSS = true
COLLISION.MS_CLOUDS = 32768
FALLOFF_IDS.CLOUDS_FALLOFF = 5

TUNING.MS_LEVEL_TO_TEMP = {
  [1] = {delta = 0, max = 70, min = -20}, 
  [2] = {delta = 0, max = 70, min = -20}, -- caves are colder then surface, so a higher temperature to be closer to surface. 
  [3] = {delta = -5, max = 70, min = -20},
  [4] = {delta = -10, max = 40, min = -50},
  [5] = {delta = -10, max = 40, min = -50},
  [6] = {delta = -20, max = 30, min = -50},
  [7] = {delta = -30, max = 0, min = -50},
  [8] = {delta = -30, max = 0, min = -50},
  [9] = {delta = -30, max = 0, min = -50},
  [10] = {delta = 0, max = 70, min = -50}, -- caves should match caves
  [11] = {delta = 0, max = 70, min = -50},
  [12] = {delta = 0, max = 70, min = -50},
  [13] = {delta = 0, max = 70, min = -50},
  [14] = {delta = 0, max = 70, min = -50},
}

-- terraformer offsets: index 0 unused conceptually; values for levels 1..
TUNING.MS_TERRAFORMER_OFFSET_X = {0, 140, 140, 140, 140, 0,     0,    0,  0,   0,    -140,   -140,  -140}
TUNING.MS_TERRAFORMER_OFFSET_Y = {0, 0,   0,   0,   0,   140  , 140 , 70, 70,  140,  0,       0,    0}

TUNING.MS_CAVES_START = 10

TUNING.MS_TERRAFORMER_SIZE = {50, 35, 25, 22, 20, 20, 20, 20, 20, 20}

local function IsPointClear(x, z, radius)
	local ents = TheSim:FindEntities(x, 0, z, radius, nil, nil)
	return ents == nil or #ents == 0
end

local function IsSpawnableMountainTile(tile)
	return tile == WORLD_TILES.MS_MOUNTAIN_LOW
		or tile == WORLD_TILES.MS_MOUNTAIN_LOW_2
		or tile == WORLD_TILES.MS_MOUNTAIN_HIGH
		or tile == WORLD_TILES.MS_PERMAFROST
		or tile == WORLD_TILES.MS_SNOW
end

-- Group name in distributeprefabs → real numbered prefabs (equal random pick).
TUNING.MS_VARIANT_GROUPS = {
	mountain_green_stone = { "mountain_green_stone_1", "mountain_green_stone_2", "mountain_green_stone_3" },
	mountain_plants_bush = { "mountain_plants_bush_1", "mountain_plants_bush_2", "mountain_plants_bush_3" },
	mountain_cold_rock = { "mountain_cold_rock_1", "mountain_cold_rock_2", "mountain_cold_rock_3" },
	mountain_stalagmite = { "mountain_stalagmite_1", "mountain_stalagmite_2", "mountain_stalagmite_3" },
	mountain_cockroach_nest = { "mountain_cockroach_nest_1", "mountain_cockroach_nest_2", "mountain_cockroach_nest_3" },
	mountain_stalactite = { "mountain_stalactite_1", "mountain_stalactite_2", "mountain_stalactite_3" },
	mountain_snowpeak_stone = { "mountain_snowpeak_stone_1", "mountain_snowpeak_stone_2", "mountain_snowpeak_stone_3" },
}

local function ResolveVariantPrefab(name)
	local variants = TUNING.MS_VARIANT_GROUPS[name]
	if variants ~= nil and #variants > 0 then
		return variants[math.random(#variants)]
	end
	return name
end

local function preplacekiki(x,z) 
  --Three variants: Pools only, Stone posts only, pools and posts
  local variant = math.random(1,3)
  print("VARIANT", variant)
  if variant == 1 or variant == 3 then
    for i = 1, math.random(2,3) do
      local pool = SpawnPrefab("mountain_crater_pool")
      local spawned
      for _ = 1, 10 do
        local x1, z1 = x + math.random() * 8, z + math.random() * 8
        if IsPointClear(x1, z1, 3) and IsSpawnableMountainTile(TheWorld.Map:GetTileAtPoint(x1, 0, z1)) then
          pool.Transform:SetPosition(x1,0,z1)
          spawned = true
        end
      end
      if not spawned then
        pool:Remove()
      end
    end
  end
  if variant == 2 or variant == 3 then
    local radius = 13 + math.random() * 6
    for i = 1, 18 do
      local x1, z1 = x + radius * math.sin(i*20), z + radius * math.cos(i*20)
      if IsPointClear(x1, z1, 3) and IsSpawnableMountainTile(TheWorld.Map:GetTileAtPoint(x1, 0, z1)) then
        local pool = SpawnPrefab(ResolveVariantPrefab("mountain_snowpeak_stone"))
        pool.Transform:SetPosition(x1,0,z1)
      end
    end
  end  
end

-- Runtime mountain-floor decoration (pseudo-Room distributeprefabs).
-- mob_spawn_points stores ~1–5 candidates per tile; POINT_SAMPLE scales
-- distributepercent down so effective density stays near vanilla rocky (~0.1/tile).
TUNING.MS_CONTENT_POINT_SAMPLE = 1 / 3
TUNING.MS_CONTENT_CLEAR_RADIUS = 2
TUNING.MS_LEVEL_CONTENTS = {
	-- Level 1–2: MS_MOUNTAIN_LOW / LOW_2 (green foothills)
	[1] = {
		distributepercent = 0.14,
		distributeprefabs = {
			any = {
				mountain_green_stone = 1.5,
				mountain_plants_grass = 0.25,
				mountain_plants_branches = 0.08,
			},
			ms_mountain_low = {
				rock1 = 0.5,
				rocks = 0.1,
				ms_copper_rock = 0.04,
				ms_coal_rock = 0.04,
				ms_giant_boulder_grass = 0.01,
			},
			ms_mountain_low_2 = {
				mountain_plants_bush = 0.55,
				mountain_plants_tree = 0.1,
				mountain_plants_flower = 0.8,
				mountain_bush = 0.1,
				mountain_plants_pomegranate = 0.2,
			},
			
			},
		herds = {
			{ prefab = "mountain_goat", size = 6, count = 1 },
		},
	},
	[2] = {
		distributepercent = 0.12,
		distributeprefabs = {
			any = {
				mountain_green_stone = 1.5,
				mountain_plants_grass = 0.20,
				mountain_plants_branches = 0.06,
			},
			ms_mountain_low = {
				rock1 = 0.5,
				rocks = 0.1,
				ms_copper_rock = 0.06,
				ms_coal_rock = 0.06,
				ms_giant_boulder_grass = 0.01,
			},
			ms_mountain_low_2 = {
				mountain_plants_bush = 0.55,
				mountain_plants_tree = 0.1,
				mountain_plants_flower = 0.8,
				mountain_bush = 0.1,
				mountain_plants_pomegranate = 0.2,
			},
		},
		herds = {
			{ prefab = "mountain_goat", size = 6, count = 1 },
		},
	},
	[3] = {
		distributepercent = 0.12,
		distributeprefabs = {
			any = {
				rock2 = 0.5,
				rock_flintless = 0.5,
				ms_copper_rock = 0.08,
				ms_alu_rock = 0.08,
				ms_coal_rock = 0.08,
				mountain_cold_rock = 3.0,
				mountain_gravel_pile = 1.0,
				mountain_plants_grass = 0.08,
				mountain_bush = 1.0,
				ms_giant_boulder_rock = 0.04,
			},
			rocky = {
				boneshard = 0.12,
				houndbone = 0.12,
				cutgrass = 0.08,
			}
		},
		-- Side cave rooms linked to this floor (SpawnCaveLayout level arg).
		cave = {
			distributepercent = 0.22,
			distributeprefabs = {
				mountain_stalagmite = 3.0,
				mountain_cockroach_nest = 2.1,
				mountain_stalactite = 3.0,
				mountain_gravel_pile = 1.0,
				mushtree_small = 1.0,
				ms_geode_rock = 0.6,
				ms_copper_rock = 0.6,
				ms_alu_rock = 0.6,
				ms_coal_rock = 0.6,
				rock2 = 1.0,
				ms_giant_boulder_rock = 0.5,
			},
		},
	},
	[4] = {
		distributepercent = 0.12,
		distributeprefabs = {
			any = { 
				rock2 = 0.5,
				rock_flintless = 0.5,
				mountain_snowpile = 1.0,
				mountain_cold_rock = 3.0,
				rock_ice = 1.0,
				mountain_gravel_pile = 1.0,
				ms_copper_rock = 0.1,
				ms_alu_rock = 0.1,
				ms_coal_rock = 0.1,
				mountain_plants_grass = 0.08,
				mountain_bush = 1.0,
				ms_giant_boulder_rock = 0.04,
				ms_barricade_spawner_gravel = 0.1,
			},
		},
    	communities = {
			{
				count = 1,
				radius = 10,
        		tile = WORLD_TILES.ROCKY,
        		tileradius = 3,
       			clear_radius = 1,
				members = {
					{ prefab = "mountain_falcon_base", min = 3, max = 4 },
					{ prefab = "houndbone", min = 7, max = 10 },
          			{ prefab = "boneshard", min = 7, max = 10 },
          			{ prefab = "cutgrass", min = 7, max = 10 },
				},
			},
		},
	},
	[5] = {
		distributepercent = 0.1,
		distributeprefabs = {
			any = {
				rock2 = 0.5,
				rock_flintless = 0.5,
				mountain_snowpile = 1.0,
				mountain_cold_rock = 3.0,
				rock_ice = 1.0,
				ms_copper_rock = 0.1,
				ms_alu_rock = 0.1,
				ms_coal_rock = 0.1,
				mountain_gravel_pile = 1.0,
				mountain_plants_grass = 0.08,
				mountain_bush = 1.0,
				ms_giant_boulder_rock = 0.04,
				ms_barricade_spawner_gravel = 0.1,
			},
		},
    	communities = {
			{
				count = 2,
				radius = 10,
        		tile = WORLD_TILES.ROCKY,
				tileradius = 3,
				clear_radius = 1,
				members = {
					{ prefab = "mountain_falcon_base", min = 2, max = 3 },
					{ prefab = "houndbone", min = 7, max = 10 },
					{ prefab = "boneshard", min = 7, max = 10 },
					{ prefab = "cutgrass", min = 7, max = 10 },
				},
			},
		},
		cave = {
			distributepercent = 0.22,
			distributeprefabs = {
				mountain_stalagmite = 3.0,
				mountain_cockroach_nest = 2.1,
				mountain_stalactite = 3.0,
				ms_copper_rock = 1,
				ms_alu_rock = 1,
				ms_coal_rock = 1,
				ms_geode_rock = 1,
				mountain_gravel_pile = 1.0,
				mushtree_small = 1.0,
				rock2 = 1.0,
				ms_giant_boulder_rock = 0.8,
			},
		},
	},
	[6] = {
		distributepercent = 0.1,
		distributeprefabs = {
			any = {
				mountain_snowpile = 1.0,
				rock_ice = 1.0,
				mountain_bush = 1.0,
				mandrake_planted = 0.04,
				mountain_snowpeak_stone = 3.0,
				cavein_boulder = 0.04,
				ms_apple_tree_snow = 0.7,
				ms_giant_boulder_snow = 0.08,
				ms_barricade_spawner_snow = 0.1,
			}
		},
		communities = {
			{
				count = 1,
				radius = 10,
        tile = WORLD_TILES.ROCKY,
        tileradius = 4,
				preplacefn = preplacekiki,
				members = {
					{ prefab = "mountain_kiki_house", min = 3, max = 4 },
					--{ prefab = "mountain_crater_pool", min = 3, max = 4 },
          { prefab = "cavein_boulder", min = 5, max = 8 },
				},
			},
		},
	},
	[7] = {
		distributepercent = 0.1,
		distributeprefabs = {
			any = {
				mountain_snowpile = 1.0,
				rock_ice = 1.0,
				mountain_bush = 1.0,
				mandrake_planted = 0.04,
				mountain_snowpeak_stone = 3.0,
				cavein_boulder = 0.04,
				ms_apple_tree_snow = 0.7,
				ms_giant_boulder_snow = 0.08,
				ms_barricade_spawner_snow = 0.1,
			}
		},
		communities = {
			{
				count = 1,
				radius = 10,
        tile = WORLD_TILES.ROCKY,
        tileradius = 4,
				preplacefn = preplacekiki,
				members = {
					{ prefab = "mountain_kiki_house", min = 3, max = 4 },
					--{ prefab = "mountain_crater_pool", min = 3, max = 4 },
          { prefab = "cavein_boulder", min = 5, max = 8 },
				},
			},
		},
	},
	[9] = {
		distributepercent = 0.3,
		distributeprefabs = {
      any = {
        mountain_sandspike_tall = 1.0,
        mountain_sandspike_med = 1.0,
        mountain_sandspike_short = 1.0,
      }
		},
	},
}

TUNING.MS_LEVEL_WALL_CONTENTS = {
  [1] = {
    distributepercent = 0.15,
		distributeprefabs = {
			ms_wall_stone = 0.1,
			ms_wall_bush = 0.5,
		},  
  },
  [2] = {
    distributepercent =  0.15,
		distributeprefabs = {
			ms_wall_stone = 0.2,
			ms_wall_bush = 0.5,
		},  
  },
  [3] = {
    distributepercent =  0.15,
		distributeprefabs = {
			ms_wall_stone = 0.4,
			ms_wall_bush = 0.5,
		},  
    cavedistributeprefabs = {
			ms_wall_stone = 1.0,
		},  
  },
  [4] = {
    distributepercent =  0.15,
		distributeprefabs = {
			ms_wall_stone = 1.0,
			ms_wall_bush = 0.5,
		},  
  },
  [5] = {
    distributepercent = 0.15,
		distributeprefabs = {
			ms_wall_stone = 1.0,
			ms_wall_bush = 0.5,
		},  
    cavedistributeprefabs = {
			ms_wall_stone = 1.0,
		},  
  },
  [6] = {
    distributepercent = 0.2,
		distributeprefabs = {
			ms_wall_stone = 1.0,
			ms_wall_bush = 0,
		},  
  },
  [7] = {
    distributepercent = 0.2,
		distributeprefabs = {
			ms_wall_stone = 1.0,
			ms_wall_bush = 0,
		},  
  },
  [9] = {
    distributepercent = 0.2,
		distributeprefabs = {
			ms_wall_stone = 1.0,
		},
  },
  [10] = {
    distributepercent = 0.2,
		distributeprefabs = {
			ms_wall_stone = 1.0,
		},  
  },
  [11] = {
    distributepercent = 0.2,
		distributeprefabs = {
			ms_wall_stone = 1.0,
		},  
  },
}

TUNING.MS_SMELT_TIME = {
    ms_iron = 1,
	ms_gold_ingot = 1,
    ms_copper_ingot = 1,
	ms_alu_ingot = 1,
	ms_bronze_ingot = 1,
    ms_gold_ingot_formless = 1,
    ms_copper_ingot_formless = 1,
	ms_alu_ingot_formless = 1,
	ms_bronze_ingot_formless = 1,
	ms_slag = 1,
}

TUNING.MS_SMELT_TEMP = {
	ms_iron = 600,
    ms_copper_ingot = 1000, -- Luigi: 1048? in reality, but 1000 is a nice number.
	ms_alu_ingot = 1000, -- Unless I want to make ms_coal superfuel with higher temperature, i cant make this value too high.
    ms_gold_ingot = 600,
	ms_bronze_ingot = 800,
    ms_copper_ingot_formless  = 1000, 
	ms_alu_ingot_formless  = 1000,
    ms_gold_ingot_formless  = 600,
	ms_bronze_ingot_formless  = 800,
    ms_copper_detail  = 1000, 
	ms_alu_detail  = 1000,
    ms_gold_detail  = 600,
	ms_bronze_detail  = 800,
	ms_ingot = 600,
    ms_slag = 1,
}

-- ms_bronze_detail 右键修复青铜装备：每次恢复的耐久比例
TUNING.MS_BRONZE_REPAIR_PERCENT = 0.5
FORGEMATERIALS.MS_BRONZE = "ms_bronze"

TUNING.MS_ANVIL_MINIMAL_HITS = 3

--------------------------------------------------------
-- XK: creatures / tools / foods

TUNING.MS_FALL_DAMAGE = 60

-- 山体上下层传送黑屏。原版 teleporter 默认：camera=3, arrive=4, 淡入 2 秒。
TUNING.MS_CLIMB_TRAVEL_CAMERA_TIME = 2
TUNING.MS_CLIMB_TRAVEL_ARRIVE_TIME = 2.5

-- mountain_top（山顶插旗）
TUNING.MOUNTAIN_TOP = {
	FLAG_SANITY = 50,           -- 插旗即时理智
	AURA_PER_MIN = 36,          -- 插旗后旁站每分钟理智
	AURA_PER_SECOND = 36 / 60,  -- 换算为每秒
	AURA_RANGE = 3,             -- 理智光环半径
}

-- mountain_frozen_meatballs（冻肉丸）
TUNING.MOUNTAIN_FROZEN_MEATBALLS = {
	WORK = 1, -- 镐击次数（每层堆叠）
}

-- mountain_kiki 数值（与官方 monkey 一致）

TUNING.MOUNTAIN_KIKI = {
	MELEE_DAMAGE = 40,
	HEALTH = 600,
	ATTACK_PERIOD = 2,
	MELEE_RANGE = 3,
	RANGED_DAMAGE = 0,
	RANGED_RANGE = 17,
	MOVE_SPEED = 7,
	AGGRO_RANGE = 6,        -- 靠近 kiki 时的主动索敌距离
	DEAGGRO_RANGE = 18,     -- 玩家远离 kiki 后脱战
	HOME_LEASH_RANGE = 28,  -- kiki 离巢穴超过此距离后脱战
	BATH_SEARCH_RANGE = 30, -- 寻找温泉的最大距离
	BATH_DURATION = 60,     -- 单次泡澡时长（秒）
	BATH_COOLDOWN = 180,    -- 泡完后的冷却（秒）
	BATH_CHANCE = 0.4,      -- 满足条件时尝试泡澡的概率
	BATH_DEST_RADIUS_MULT = 0.35, -- 泡澡落点：相对官方 dest 向温泉中心收缩（0=池心，1=官方落点）
	DEFAULT_AMMO_COUNT = 4, -- 出生时携带的通用弹药数量
	KNOCK_APPLE_RANGE = 10,     -- 寻找成熟苹果树的距离
	KNOCK_APPLE_COOLDOWN = 12,  -- 个人拍树冷却（秒），防空跑
}

TUNING.MOUNTAIN_FALCON_BASE = {
	HEALTH = 300,
	CHILDREN_MIN = 2,
	CHILDREN_MAX = 3,
	REGEN_PERIOD = TUNING.SEG_TIME * 6,
	SPAWN_PERIOD = TUNING.SEG_TIME, -- 洞穴白天放出间隔
}

-- mountain_falcon 山域追杀（Territory Pursuit）
TUNING.MOUNTAIN_FALCON = {
	MAX_CHASE_TIME = 8,            -- 同层 ChaseAndAttack 超时后仍由 pursuit tick 续追/跨层
	MAX_CHASE_DIST = 55,           -- 同层寻路追击上限；超过改走飞跃跨层
	DEAGGRO_TIMEOUT = 240,         -- 接战后最长追杀时间，到点强制回巢
	LOST_TARGET_TIME = 12,         -- 丢失有效目标后多久回巢
	CROSS_FLOOR_DIST = 45,         -- 与目标水平距离超过此值视为换层，触发飞跃追杀
	CROSS_FLOOR_COOLDOWN = 1.25,   -- 跨层飞跃冷却
	CROSS_FLOOR_LAND_RADIUS = 4,   -- 落点相对目标的搜索半径
	CROSS_FLOOR_LAND_ATTEMPTS = 8,
	CROSS_FLOOR_FLY_UP_TIME = 0.85,-- 旧层飞起多久后瞬移到新层高空
	CROSS_FLOOR_LAND_POST_READY_DELAY = 3.0,  -- 服务端过门就绪后的基准等待（对齐黑屏）
	CROSS_FLOOR_LAND_POST_READY_JITTER = 0.75, -- 每只猎隼额外随机 0~此值，避免群鹰同步降落
	CROSS_FLOOR_LAND_TIMEOUT = 8,             -- 高空待命超时强制降落，避免卡死
	HOUSE_MAX_DIST = 40,           -- 非追杀时拴巢
	HOUSE_RETURN_DIST = 50,
	MAX_WANDER_DIST = 8,
	SEE_FOOD_DIST = 30,
}

TUNING.MOUNTAIN_WINDHORN = {
	USES = 5,
	TORNADO_COUNT = 6,
	TORNADO_SPAWN_DIST = 1.5,   -- 生成点：贴近玩家
	TORNADO_TRAVEL_DIST = 5,   -- 目标点：向外飞出距离
	TORNADO_DAMAGE_MULT = 1.5,  -- 相对普通龙卷风的伤害倍率
	TORNADO_FREEZE_PERCENT = 0.5, -- 每次命中叠加的冻结进度（相对目标抗性）
}

TUNING.MOUNTAIN_KIKI_HOUSE = {
	MINE_WORK = 6,           -- 稿子敲击次数
	MAX_CHILDREN = 2,        -- 每个巢穴中的 mountain_kiki 数量
	SPAWN_PERIOD = 4,        -- 白天放出 mountain_kiki 的间隔（秒）
	REGEN_PERIOD = 60,       -- mountain_kiki 死亡后重新生成的间隔（秒）
}

-- Runtime kiki community placement (houses + crater pools) on mountain floors.
TUNING.MOUNTAIN_KIKI_COMMUNITY = {
	SPAWN_RADIUS = 10,
	CENTER_CLEAR_RADIUS = 8,
	CENTER_ATTEMPTS = 40,
	MEMBER_CLEAR_RADIUS = 1.75,
}

TUNING.MOUNTAIN_CRATER_POOL = {
	GLOW = {
		RADIUS = 2,
		INTENSITY = 0.75,
		FALLOFF = 0.75,
	},
	IDLE = {
		BASE = 3,
		DELAY = 4,
	},
	HEAT = 90,
	TICK_PERIOD = 1,
	SANITY_PER_SECOND = 1,
	HEALTH_PER_SECOND = 1,
	DEFEND_RANGE = 10,  -- 玩家进入此距离触发池区警报 / 泡澡 kiki 播放 bath 警戒动画
	ALERT_RANGE = 20,   -- 池区警报向此范围内的无仇恨 kiki 发出警报（泡澡中除外）
}

TUNING.MOUNTAIN_KIKI_PROJECTILE = {
	SPEED = 25,
	RANGE = 30,
	HIT_DIST = 1.5,
	ICE_SPIKE_DAMAGE = 50,
	KNOCKBACK_RADIUS = 2,
	KNOCKBACK_STRENGTH = 1,
	FREEZE_CHANCE = 0.25,
	FREEZE_TIME = 3,
	FREEZE_POWER = 4, -- 玩家 freezable 抗性为 4，需一次叠满才能进入 frozen 状态（月后巨鹿为 3，需两次命中）
	SANITY_SNOWBALL_SANITY_DAMAGE = 15,
	PROJECTILE_WEIGHTS = {
		{ prefab = "mountain_kiki_projectile1", weight = 0.20 },
		{ prefab = "mountain_kiki_projectile2", weight = 0.40 },
		{ prefab = "mountain_kiki_projectile3", weight = 0.40 },
	},
}

-- mountain_bush 数值（对齐 marsh_bush 再生周期）
TUNING.MOUNTAIN_BUSH = {
	REGROW_TIME = TUNING.MARSHBUSH_REGROW_TIME, -- 4 天
}

-- ms_apple_tree（普通短苹果树）
TUNING.MS_APPLE_TREE = {
	CHOPS = TUNING.EVERGREEN_CHOPS_SMALL, -- 5
	LOGS = 2,
	STUMP_LOOT = 1,
	APPLES = 3,
	BIG_APPLE_CHANCE = 0.1,
	SEED_TO_SHORT = { base = TUNING.TOTAL_DAY_TIME * 1, random = TUNING.TOTAL_DAY_TIME * 0.25 },
	SHORT_TO_FRUIT = { base = TUNING.TOTAL_DAY_TIME * 2, random = TUNING.TOTAL_DAY_TIME * 0.5 },
	FRUIT_TO_SEED = { base = TUNING.TOTAL_DAY_TIME * 2.5, random = TUNING.TOTAL_DAY_TIME * 0.5 },
}

TUNING.MS_APPLE = {
	HUNGER = 12.5,
	HEALTH = 12.5,
	SANITY = 0,
	PERISH_TIME = TUNING.TOTAL_DAY_TIME * 5,
}

TUNING.MS_APPLE_COOKED = {
	HUNGER = 25,
	HEALTH = 12.5,
	SANITY = 0,
	PERISH_TIME = TUNING.TOTAL_DAY_TIME * 4,
}

TUNING.MS_BIG_APPLE = {
	HUNGER = 25,
	HEALTH = 20,
	SANITY = 0,
	PERISH_TIME = TUNING.TOTAL_DAY_TIME * 5,
}

TUNING.MS_APPLE_DRIED = {
	HUNGER = 12.5,
	HEALTH = 20,
	SANITY = 0,
	PERISH_TIME = TUNING.PERISH_PRESERVED, -- 20 days
}

-- 金苹果：食用恢复 + 1 分钟 buff（1 HP/s、80% 减伤）；不腐烂
TUNING.MS_GOLDEN_APPLE = {
	HUNGER = 150,
	HEALTH = 1,
	SANITY = 0,
	-- PERISH_TIME omitted: does not spoil
	REGEN_PER_SECOND = 1,
	ABSORPTION = 0.8,
	BUFF_DURATION = 60,
}

TUNING.MS_APPLE_PIE = {
	HUNGER = 75,
	HEALTH = 40,
	SANITY = 15,
	PERISH_TIME = TUNING.TOTAL_DAY_TIME * 5,
}

TUNING.MS_APPLE_CARAMEL = {
	HUNGER = 12.5,
	HEALTH = 20,
	SANITY = 40,
	PERISH_TIME = TUNING.TOTAL_DAY_TIME * 10,
}

TUNING.MS_POISONED_APPLE = {
	HUNGER = 12.5,
	HEALTH = -150,
	SANITY = -50,
	PERISH_TIME = TUNING.TOTAL_DAY_TIME * 9,
}


TUNING.MS_MOUNTAIN_BUSH_REGEN_DURATION = TUNING.TOTAL_DAY_TIME * 3
TUNING.MS_MOUNTAIN_BUSH_REGEN_VARIATION = TUNING.TOTAL_DAY_TIME * 0.5

-- mountain_yoth_lance（伤害随耐久降低而减少）
TUNING.MOUNTAIN_YOTH_LANCE = {
	USES = 400,
	JOUST_SPEED = TUNING.YOTH_LANCE_JOUST_SPEED,           -- 10
	LENGTH = TUNING.YOTH_LANCE_LENGTH,                     -- 2
	RUNANIM_LOOP_COUNT = TUNING.YOTH_LANCE_RUNANIM_LOOP_COUNT, -- 2
	-- 按耐久百分比从高到低匹配（pct >= 阈值用该伤害）
	DAMAGE_PHASES = {
		{ PCT = 0.66, DAMAGE = 68 },
		{ PCT = 0.33, DAMAGE = 51 },
		{ PCT = 0,    DAMAGE = 38 },
	},
}

-- mountain_wathgrithr_shield（防御/格挡随耐久降低而减弱）
TUNING.MOUNTAIN_WATHGRITHR_SHIELD = {
	DAMAGE = TUNING.WATHGRITHR_SHIELD_DAMAGE,                         -- wilson_attack * 1.5
	ARMOR = 420,
	USEDAMAGE = TUNING.WATHGRITHR_SHIELD_USEDAMAGE,                   -- 攻击额外扣盾 3
	PARRY_ARC = TUNING.WATHGRITHR_SHIELD_PARRY_ARC,                   -- 178°
	COOLDOWN = TUNING.WATHGRITHR_SHIELD_COOLDOWN,                     -- 10s
	COOLDOWN_ONEQUIP = TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONEQUIP,     -- 装备至少 2s CD
	COOLDOWN_ONPARRY_REDUCTION = TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION, -- 成功格挡拉到 70%
	-- 按耐久百分比从高到低匹配（pct >= 阈值用该阶段）
	PHASES = {
		{ PCT = 0.66, ABSORPTION = 0.85, PARRY_ABSORPTION = 1.00, PARRY_DURATION = 4 },
		{ PCT = 0.33, ABSORPTION = 0.80, PARRY_ABSORPTION = 0.98, PARRY_DURATION = 3 },
		{ PCT = 0,	  ABSORPTION = 0.75, PARRY_ABSORPTION = 0.90, PARRY_DURATION = 2 },
	},
}

-- mountain_snowball（山地雪球）
TUNING.MOUNTAIN_SNOWBALL = {
	WATERSOURCE_FILL_USES = 0.6,                -- 填充浇水壶 / 水禽罐使用量
	ADD_COLDNESS = 0.4,                         -- 投掷命中施加冰冻层数
	EFFECTS_DIST = 1.25,                        -- 范围效果半径
	EXTINGUISH_HEAT_PERCENT = -1,               -- 扑灭火焰
	TEMP_REDUCTION = 2,
	PROTECTION_TIME = 15,
	PERISH_TIME = TUNING.PERISH_TWO_DAY,
	MELT_MOISTURE_ITEMS = 3,
	MELT_MOISTURE_GROUND = 10,
	WEAPON_RANGE = 8,
	WEAPON_HIT_RANGE = 10,
	PROJECTILE_SPEED = 15,
	PROJECTILE_RANGE = 30,
	HIT_DIST = 1.5,
}

-- mountain_suspicious_ore（可疑矿石；口袋物品，落地镐一下打开）
TUNING.MOUNTAIN_SUSPICIOUS_ORE = {
	WORK_LEFT = 1,
	-- 档位权重；敲开时固定掉 1 rocks，再按权重抽 1 项（档内均分）
	LOOT_TIERS = {
		{ weight = 60,    items = { "ms_geode_ore", "goldnugget", "ms_copper_ore", "ms_alu_ore", "ms_coal" } },
		{ weight = 30,    items = { "fossil_piece", "thulecite_pieces", "goldnugget", "marble", "flint", "ice", "nitre", "saltrock", "cutstone" } },
		{ weight = 10,    items = { "thulecite", "dreadstone", "heatrock" } },
		{ weight = 1,     items = { "ancienttree_seed" } },
		{ weight = 0.01,  items = { "trinket_4" } },
	},
}

-- XK, ill make those individual in case zeroguzok wants to adjust loots even more.
TUNING.MS_GEODE_ORE = {
  WORK_LEFT = 1,
  LOOTS = {
    greengem = 1,
    yellowgem = 1,
    orangegem = 1,
    purplegem = 2,
    ms_copper_ore = 2,
    ms_alu_ore = 2,
    redgem = 3,
    bluegem = 3,
  }
}

-- Chances for inside of ms_giant_boulder

TUNING.MS_GIANT_BOULDER = {
  WORK_LEFT = 300,
  VARIANTS = {
    empty = 2,
    metals = 2,
    minerals = 3,
    coal = 2,
    thulecite = 1,
  },
  LOOTS = {
    empty = {
      rocks = 1,
    },
    metals = {
      ms_alu_ore = 1,
      ms_copper_ore = 1,
      goldnugget = 1,
    },
    minerals = {
      rocks = 1,
      flint = 4,
      nitre = 15,
    },
    coal = {
      ms_coal = 1,
    },
    thulecite = {
      thulecite_pieces = 1,
    },
  },
  WORK_PER_DROP = {
    metals = 12,
    minerals = 6,
    coal = 12,
    thulecite = 24,
    empty = 10,
  }
}

-- mountain_green_stone（绿石；三种体型）
TUNING.MOUNTAIN_GREEN_STONE = {
	WORK_1 = TUNING.ROCKS_MINE,     -- 6：full → med → short
	WORK_2 = TUNING.ROCKS_MINE_MED, -- 4：full → short
	WORK_3 = TUNING.ROCKS_MINE_LOW, -- 2：仅 full
}

-- mountain_cold_rock（寒石；三种体型）
TUNING.MOUNTAIN_COLD_ROCK = {
	WORK_1 = TUNING.ROCKS_MINE,     -- 6：full → med → short
	WORK_2 = TUNING.ROCKS_MINE_MED, -- 4：full → short
	WORK_3 = TUNING.ROCKS_MINE_LOW, -- 2：仅 full
}

-- mountain_snowpeak_stone（雪峰石；三种体型）
TUNING.MOUNTAIN_SNOWPEAK_STONE = {
	WORK_1 = TUNING.ROCKS_MINE,     -- 6：full → med → short
	WORK_2 = TUNING.ROCKS_MINE_MED, -- 4：full → short
	WORK_3 = TUNING.ROCKS_MINE_LOW, -- 2：仅 full
}

-- mountain_snowpile（山岭雪堆）
TUNING.MOUNTAIN_SNOWPILE = {
	FALL_DAMAGE = 100, -- 坠落砸中玩家伤害
	FALL_LAND_TIME = 12 / 30, -- 坠落伤害/震屏时机（秒；相对 fall 动画开始）
}

-- mountain_transformation_cube（山岭转化方块）
TUNING.MOUNTAIN_TRANSFORMATION_CUBE = {
	USES = 1000, -- 用百分比扣耐久；1000 便于整除 5%/12.5%/33%/66%
}

-- mountain_icecream（雪山冰激凌）
TUNING.MOUNTAIN_ICECREAM = {
	HEALTH = 3,
	HUNGER = 12.5,
	SANITY = 10,
	PERISH_TIME = TUNING.PERISH_SUPERFAST,
	TEMP_DELTA = -30,                   -- 食用后降低体温
	TEMP_DURATION = 30,                 -- 降温持续 30s
	BUFF_DURATION = 60,                 -- 攻击附带冰冻持续 1 分钟
	FREEZE_PERCENT = 0.25,              -- 每次攻击施加 25% 冰冻
}

-- mountain_tornado_sorbet（龙卷风星酪）
TUNING.MOUNTAIN_TORNADO_SORBET = {
	HEALTH = 3,
	HUNGER = 12.5,
	SANITY = 10,
	PERISH_TIME = TUNING.PERISH_SUPERFAST,
	TEMP_DELTA = -30,
	TEMP_DURATION = 30,
	BUFF_DURATION = 120,                 -- 持有变身能力 120s
	FORM_DURATION = 10,                 -- 龙卷风持续 10s
	COOLDOWN = 15,                       -- 结束后 5s CD
	AOE_RADIUS = 2.5,
	AOE_DAMAGE = 20,
	FREEZE_PERCENT = 0.25,              -- 接触攻击施加 25% 冰冻
	MOVE_SPEED_MULT = 1.15,
}

-- mountain_monster_drumstick（怪物鸟腿 / 炸怪物鸟腿）
TUNING.MOUNTAIN_MONSTER_DRUMSTICK = {
	HEALTH = -15,
	HUNGER = 12.5,
	SANITY = -10,
	PERISH_TIME = TUNING.PERISH_FAST,   -- 6 天
}
TUNING.MOUNTAIN_MONSTER_DRUMSTICK_COOKED = {
	HEALTH = -5,
	HUNGER = 12.5,
	SANITY = -10,
	PERISH_TIME = TUNING.PERISH_MED,    -- 10 天
}

-- mountain_aluminum_axe（只能投掷；落地自捡）
TUNING.MOUNTAIN_ALUMINUM_AXE = {
	USES = 50,
	CHOP_EFFICIENCY = 2,
	CHOP_RADIUS = 1.5,
	THROW_SPEED = 30,
	THROW_RANGE = 15,
	HIT_DIST = 0.75,
	APPLE_TREE_THROW_OFFSET = 2, -- 左键投向结果期苹果树时的命中高度偏移
}

-- mountain_aluminum_pickaxe（只能投掷；落地自捡）
TUNING.MOUNTAIN_ALUMINUM_PICKAXE = {
	USES = 25,
	MINE_EFFICIENCY = 2,
	MINE_RADIUS = 1.5,
	THROW_SPEED = 30,
	THROW_RANGE = 15,
	HIT_DIST = 0.75,
}

-- mountain_aluminum_dagger（铝剑；只能投掷；落地自捡）
TUNING.MOUNTAIN_ALUMINUM_DAGGER = {
	USES = 25,
	THROW_DAMAGE = 100,
	THROW_SPEED = 30,
	THROW_RANGE = 15,
	HIT_DIST = 0.75,
}

-- mountain_copper_axe / mountain_copper_pickaxe（耐久越低效率越高）
TUNING.MOUNTAIN_COPPER_AXE = {
	USES = 300,
}

TUNING.MOUNTAIN_COPPER_PICKAXE = {
	USES = 99,
}

TUNING.MOUNTAIN_COPPER_TOOL = {
	-- 按耐久百分比从高到低匹配（pct >= 阈值用该效率）
	EFFICIENCY_PHASES = {
		{ PCT = 0.66, EFFICIENCY = 1 },
		{ PCT = 0.33, EFFICIENCY = 2 },
		{ PCT = 0,    EFFICIENCY = 3 },
	},
}

-- mountain_goapaca_horn（山羊角；propweapon，可击飞玩家，3 次）
TUNING.MOUNTAIN_GOAPACA_HORN = {
	USES = 3,
}

-- mountain_copper_bat（铝棒；耐久越低伤害越高，外观分三阶段）
TUNING.MOUNTAIN_COPPER_BAT = {
	USES = 200,
	-- 按耐久百分比从高到低匹配（pct >= 阈值用该阶段）
	DAMAGE_PHASES = {
		{ PCT = 0.66, DAMAGE = 38, STAGE = 1 },
		{ PCT = 0.33, DAMAGE = 51, STAGE = 2 },
		{ PCT = 0,    DAMAGE = 68, STAGE = 3 },
	},
}

-- mountain_armor_copper / mountain_helmet_copper（免疫击飞；防护随耐久降低）
TUNING.MOUNTAIN_ARMOR_COPPER = {
	CONDITION = 1050,
	-- 按耐久百分比从高到低匹配（pct >= 阈值用该防护）
	ABSORPTION_PHASES = {
		{ PCT = 0.66, ABSORPTION = 0.95 },
		{ PCT = 0.33, ABSORPTION = 0.80 },
		{ PCT = 0,    ABSORPTION = 0.70 },
	},
}

TUNING.MOUNTAIN_HELMET_COPPER = {
	CONDITION = 1050,
	WATERPROOFNESS = TUNING.WATERPROOFNESS_SMALL, -- 与橄榄球头盔相同
	ABSORPTION_PHASES = TUNING.MOUNTAIN_ARMOR_COPPER.ABSORPTION_PHASES,
}

TUNING.HAT_TINFOIL = {
  CONDITION = 100,
  ABSORTION = 0.6,
}

-- mountain_super_gildedaxe / pickaxe / shovel
TUNING.MOUNTAIN_SUPER_GILDEDTOOL = {
	EFFECTIVENESS = 1.5,
	DAMAGE = 35,
	AXE_USES = 1500,
	PICKAXE_USES = 600,
	SHOVEL_USES = 375,
}

-- mountain_cockroach 数值（参考 Hamlet weevole：短距索敌 + 冷却后拉开）

TUNING.MOUNTAIN_COCKROACH = {
	HEALTH = 150,
	DAMAGE = 6,
	ATTACK_PERIOD = 4.5,
	ATTACK_RANGE = 5,
	HIT_RANGE = 1.5,
	MELEE_RANGE = 1.5,
	WALK_SPEED = 5,
	TARGET_DIST = 6,
	SHARE_TARGET_DIST = 30,
	MAX_TARGET_SHARES = 10,
	DAMAGE_UNTIL_SHIELD = 100,
	SHIELD_TIME = 3,
	SEE_FOOD_DIST = 10,
}

-- mountain_cockroach_nest（蟑螂巢）
TUNING.MOUNTAIN_COCKROACH_NEST = {
	WORK_1 = TUNING.ROCKS_MINE,     -- 6：nest1 full → med → short
	WORK_2 = TUNING.ROCKS_MINE_MED, -- 4：nest2 full → short
	WORK_3 = TUNING.ROCKS_MINE_LOW, -- 2：nest3 仅 full
	MAX_CHILDREN_1 = 6,             -- 大巢
	MAX_CHILDREN_2 = 4,             -- 中巢
	MAX_CHILDREN_3 = 2,             -- 小巢
	SPAWN_PERIOD = 8,               -- 持续放出间隔（秒；洞穴巢无昼夜门禁）
	REGEN_PERIOD = 60,              -- 死亡后重新生成间隔（秒）
}

-- mountain_stalactite / mountain_stalagmite（纯岩石，不刷蟑螂；镐次与巢穴一致）
TUNING.MOUNTAIN_STALACTITE = {
	WORK_1 = TUNING.ROCKS_MINE,
	WORK_2 = TUNING.ROCKS_MINE_MED,
	WORK_3 = TUNING.ROCKS_MINE_LOW,
	THROW_HIT_HEIGHT = 15, -- 铝镐直线砸钟乳的目标高度（Y）
}

TUNING.MOUNTAIN_STALAGMITE = {
	WORK_1 = TUNING.ROCKS_MINE,
	WORK_2 = TUNING.ROCKS_MINE_MED,
	WORK_3 = TUNING.ROCKS_MINE_LOW,
}

-- mountain_goat 数值（对齐未充电电羊，攻击附带玩家击退）

TUNING.MOUNTAIN_GOATHERD = {
	MAX_SIZE = 6,
	GATHER_RANGE = 40,
	SPAWN_RADIUS = 4,
	CENTER_CLEAR_RADIUS = 6,
	CENTER_ATTEMPTS = 40,
}

TUNING.MOUNTAIN_GOAT = {
	HEALTH = 700,
	DAMAGE = 25,
	ATTACK_RANGE = 3,
	ATTACK_PERIOD = 2,
	WALK_SPEED = 4,
	RUN_SPEED = 8,
	CHASE_DIST = 30,           -- 相对 herd（无 herd 时用出生点）的追击距离
	KNOCKBACK_RADIUS = 2,
	KNOCKBACK_STRENGTH = 1,
}

TUNING.MOUNTAIN_ICEGOAT = {
	FREEZE_TIME = 5,                              -- 完全冰冻持续时间（秒）
	FULL_FREEZE_CHANCE = 0.3,                     -- 攻击完全冰冻概率
	PARTIAL_FREEZE_PERCENT = 0.3,                 -- 未完全冰冻时施加的冰冻进度（相对抗性）
	TARGET_DIST = 8,                              -- 主动索敌距离
	THAW_TIME = TUNING.TOTAL_DAY_TIME * 3,        -- 非冬天变身冰羊后，自动变回普通羊的时间
	SHARE_TARGET_DIST = 30,                       -- 集体仇恨分享距离
	MAX_TARGET_SHARES = 5,                        -- 最多拉多少只冰羊入战
}

-- mountain_golem 数值

TUNING.MOUNTAIN_GOLEM = {

	PILLAR_HAMMER_WORK = 5,      -- 山岭魔像柱所需镐子敲击次数

	HEALTH = 20000,              -- 最大生命
	DAMAGE = 300,                -- 基础攻击伤害
	ATTACK_PERIOD = 3,           -- 攻击间隔（秒）
	ATTACK_RANGE = 5,            -- 近战攻击距离
	HIT_RECOVERY = 2,            -- 受击硬直间隔（秒）
	SPEED = 2.85,                -- 基础移动速度
	-- 移速加速阶段（按当前血量百分比匹配，HP 从高到低排列；BOOST 为百分比加成）
	SPEED_BOOST_PHASES = {
		{ HP = 1,    BOOST = 0 },
		{ HP = 0.75, BOOST = 0.10 },
		{ HP = 0.5,  BOOST = 0.15 },
		{ HP = 0.25, BOOST = 0.40 },
	},
	MIN_STAGGER_TIME = 6,        -- 硬直最短持续时间（秒）
	MAX_STAGGER_TIME = 15,       -- 硬直最长持续时间（秒）
	STAGGER_DAMAGE_MULT = 1.5,   -- 硬直期间受伤倍率
	SPIN_CD = 16,                -- 旋转攻击冷却（秒）
	QUICKJUMP_CD = 12,           -- 快速跳砸冷却（秒）
	COMBAT_RANGE = 20,           -- 活动范围（距苏醒点）
	DEAGGRO_DIST = 35,           -- 脱战距离

	----------------------------- 山岭沙刺 -----------------------------
	SANDSPIKE_CD = 20,           -- 沙刺攻击冷却（秒）
	SANDSPIKE_LIFETIME = 10,     -- Boss 普通石刺存在时间（秒），读档后按剩余时间继续
	SANDSPIKE_RANGE = 20,        -- 沙刺目标搜索范围
	CHARGED_SANDSPIKE_EXPLODE_DELAY = { MIN = 0.5, MAX = 1.5 }, -- 充能沙刺爆炸倒计时（秒，随机）
	SANDSPIKE_MINE_WORK = {      -- 沙刺镐击次数（tall / med / short）
		TALL = 3,
		MED = 2,
		SHORT = 1,
	},
	SANDSPIKE_PHASES = {  -- 沙刺阶段配置（按当前血量百分比匹配，HP 从高到低排列）
		{ HP = 1,    COUNT = 1, CHARGED_CHANCE = 0.25 },  -- 初始（>75%）
		{ HP = 0.75, COUNT = 3, CHARGED_CHANCE = 0.30 },  -- 75% 血量
		{ HP = 0.5,  COUNT = 5, CHARGED_CHANCE = 0.50 },  -- 50% 血量
		{ HP = 0.25, COUNT = 8, CHARGED_CHANCE = 0.30 },  -- 25% 血量
	},
	CHARGED_SANDSPIKE_EXPLODE = {  -- 充能沙刺爆炸伤害与范围
		TALL = { DAMAGE = 300, RADIUS = 3.5 },
		MED = { DAMAGE = 200, RADIUS = 3.5 },
		SHORT = { DAMAGE = 100, RADIUS = 3.5 },
	},

	------------------------------ 山岭沙块 -----------------------------
	TOWER_CD = 50,               -- 沙块环技能冷却（秒）
	SANDBLOCK_LIFETIME = 30,     -- 普通石塔存在时间（秒），读档后按剩余时间继续
	SANDBLOCK_RING_RADIUS = 18,  -- 生成圈半径
	SANDBLOCK_RING_SPACING = 2.5, -- 相邻沙块最短弧长间距（数量 = 2π×半径÷间距）
	SANDBLOCK_RING_RADIUS_VAR = 1, -- 半径随机偏移（0~该值）
	SANDBLOCK_RING_SPAWN_DELAY = 0.5, -- 除首个外，其余沙块最大出现延迟（秒）
	TOWER_ABSORB = 0.1,          -- 每个充能沙块减伤比例（可叠加）
	TOWER_ABSORB_MAX = 1,        -- 沙块减伤叠加上限
	RING_MAX_LEVEL = 10,         -- 防护光圈最大显示层数
	RING_SCALE = 1.3,            -- 防护光圈尺寸
	RING_ANIM_SPEED = 0.7,       -- 防护光圈 idle 动画速度（SetDeltaTimeMultiplier）
	TOWER_HEAL = 20,             -- 每个充能沙块每次治疗量（可叠加）
	TOWER_HEAL_PERIOD = 2,       -- 充能沙块治疗间隔（秒）
	SANDBLOCK_MINE_WORK = {      -- 沙块镐击次数（tall / med / short）
		TALL = 3,
		MED = 2,
		SHORT = 1,
	},
	TOWER_SANDBLOCK_CHARGED_PHASES = {  -- 沙块环生成充能沙块概率（按当前血量百分比匹配，HP 从高到低排列）
		{ HP = 1,    CHANCE = 0.03 },  -- 初始（>75%）
		{ HP = 0.75, CHANCE = 0.08 },  -- 75% 血量
		{ HP = 0.5,  CHANCE = 0.15 },  -- 50% 血量
		{ HP = 0.25, CHANCE = 0.20 },  -- 25% 血量
	},

	------------------------------ 山岭激光 -----------------------------
	LASER_CD = 40,               -- 激光攻击冷却（秒）
	LASER_RANGE = 12,            -- 激光目标搜索范围
	LASER_MAX_TARGETS = 5,       -- 单次技能最多锁定目标数
	LASER_PLANAR_DAMAGE = 50,    -- 激光初始位面伤害
	LASER_DOT_DPS = 4,          -- 激光持续伤害（非月灼）
	LASER_DOT_HIT_INTERVAL = 0.4, -- 激光持续伤害受击反馈间隔（秒）

}
