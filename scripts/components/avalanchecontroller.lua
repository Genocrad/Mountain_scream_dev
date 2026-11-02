local AvalancheController = Class(function(self, inst)
    self.inst = inst
    self.lastlevel = nil
    self.level = nil
    self.avalanche_counter = 0
    self.dist_between = 1.5
    self.avalance_grid = {}
    self.wavetask = {}
    self.fx_wavetask = {}
    inst:AddTag("avalanchecontroller")    
    self.inst:StartUpdatingComponent(self)
end)

function AvalancheController:DoDelta(nmb)
  self.avalanche_counter = self.avalanche_counter + nmb
end

function AvalancheController:OnUpdate()
  for k,v in pairs(AllPlayers) do
    if v.components.dungeonplayertracker and v.components.dungeonplayertracker:GetLevel() then
      local level = v.components.dungeonplayertracker:GetLevel()
      self.avalanche_counter = self.avalanche_counter + TUNING.MS_LEVEL_AVALANCHE[level].player_causes
    end
  end
  if self.avalanche_counter > 10000 then
    for k,v in pairs(AllPlayers) do
      local x,y,z = v.Transform:GetWorldPosition()
      if v.components.dungeonplayertracker and v.components.dungeonplayertracker:GetLevel() then
        local level = v.components.dungeonplayertracker:GetLevel()
        local ents = TheSim:FindEntities(x, 0, z, 50, {"ms_wall"})
        if ents[1] then
          local x1,y1,z1 = ents[1].Transform:GetWorldPosition()
          local dirx, dirz = x - x1, z - z1
          self:SpawnAvalancheAtPoint(k, x1 + (dirx)/math.abs(dirx) * self.dist_between, z1 + (dirz)/math.abs(dirz) * self.dist_between, TUNING.MS_LEVEL_AVALANCHE[level].size, (dirx)/(self.dist_between * math.max(math.abs(dirx), math.abs(dirz))), (dirz)/(2*math.max(math.abs(dirx), math.abs(dirz))))
          self.avalanche_counter = - math.random(0, 3000)
        end
      end
    end
  end
end

local SNOWPILE_TAGS = { "snowpile" }

local function IsMsTechnicalTile(tile)
  return tile == WORLD_TILES.VOID_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
  tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL or 
  tile == WORLD_TILES.MS_BRIDGE or 
  (not tile == 1 and not TileGroupManager:IsLandTile(tile))
end

function AvalancheController:SpawnWave(playernmb, srs_x,srs_z, amount, wave_amount, dirx, diry)
    --Build table of weighted options. 
    local weighted_spaces = {}
    table.insert(weighted_spaces, {0 +  self.avalance_grid[playernmb][0][0], 0, 0})
    for i=-30, 30 do
      for j=-30, 30 do
        if self.avalance_grid[playernmb][math.min(i+1, 30)][j] + self.avalance_grid[playernmb][math.max(i-1, -30)][j] + self.avalance_grid[playernmb][i][math.min(j+1, 30)] + self.avalance_grid[playernmb][i][math.max(j-1, -30)] > 0 then
          table.insert(weighted_spaces, {1 + math.sqrt((i)*(i)*(i>0 and 1-dirx or dirx+1) + (j)*(j)*(j>0 and 1-diry or diry+1)) * (0.3 + self.avalance_grid[playernmb][i][j]*0.12), i, j})
        end
      end
    end
    -- Sort the table.
    table.sort(weighted_spaces, function(a, b)
      return a[1] < b[1]
    end)
  
    
  
  -- choose first options.
    for i=1, wave_amount do
      if self.avalance_grid[playernmb][weighted_spaces[i][2]][weighted_spaces[i][3]] == 0 then
        local pile = SpawnPrefab("avalanche_snowpile")
        pile._skip_fall = true
        pile.Transform:SetPosition(srs_x + weighted_spaces[i][2] * self.dist_between + math.random()*self.dist_between*0.75-self.dist_between/1.5, 0, srs_z + weighted_spaces[i][3] * self.dist_between+ math.random()*self.dist_between*0.75 - self.dist_between/1.5)
        pile.pile_stage = 1
        local hyp = math.ceil(math.sqrt(weighted_spaces[i][2] * weighted_spaces[i][2] * self.dist_between * self.dist_between + weighted_spaces[i][3] * weighted_spaces[i][3] * self.dist_between * self.dist_between)/4)*4
        
        for j=4, hyp, 4 do
          local fx_x, fx_y, fx_z = srs_x +  self.dist_between * weighted_spaces[i][2]*(j / hyp), math.abs(weighted_spaces[i][2]*(j / hyp))/4, srs_z + self.dist_between *  weighted_spaces[i][3]*(j / hyp)  
          pile:DoTaskInTime(0.2 * weighted_spaces[i][1]*(j / hyp), function(inst, data) local fx_x, fx_y, fx_z = data[1], data[2], data[3] inst:SpawnFxAtPoint(fx_x, fx_y, fx_z) end, {fx_x, fx_y, fx_z})
        end
        pile:DoTaskInTime(0.2 * weighted_spaces[i][1], pile.BreakAndAbsorb)
        self.avalance_grid[playernmb][weighted_spaces[i][2]][weighted_spaces[i][3]] = 1
      elseif self.avalance_grid[playernmb][weighted_spaces[i][2]][weighted_spaces[i][3]] > 0 and self.avalance_grid[playernmb][weighted_spaces[i][2]][weighted_spaces[i][3]] < 9 then
        local pile = TheSim:FindEntities(srs_x + weighted_spaces[i][2] * self.dist_between, 0, srs_z + weighted_spaces[i][3] * self.dist_between, 5, nil, nil, SNOWPILE_TAGS)[1]
        
        
        local hyp = math.ceil(math.sqrt(weighted_spaces[i][2] * weighted_spaces[i][2] * self.dist_between * self.dist_between + weighted_spaces[i][3] * weighted_spaces[i][3] * self.dist_between * self.dist_between)/4)*4
        
        for j=4, hyp, 4 do
          local fx_x, fx_y, fx_z = srs_x +  self.dist_between * weighted_spaces[i][2]*(j / hyp), math.abs(weighted_spaces[i][2]*(j / hyp))/4, srs_z + self.dist_between *  weighted_spaces[i][3]*(j / hyp)  
          print("timefx", 0.2 * weighted_spaces[i][1]*(j / hyp))
          pile:DoTaskInTime(0.2 * weighted_spaces[i][1]*(j / hyp), function(inst, data) local fx_x, fx_y, fx_z = data[1], data[2], data[3] inst:SpawnFxAtPoint(fx_x, fx_y, fx_z) end, {fx_x, fx_y, fx_z})
        end
        
        pile._skip_fall = true
        pile.pile_stage = math.min(pile.pile_stage + 1, 9) 
        pile:DoTaskInTime(0.2 * weighted_spaces[i][1], pile.BeginTransition)
        self.avalance_grid[playernmb][weighted_spaces[i][2]][weighted_spaces[i][3]] = pile.pile_stage
      end
      
      
    end
    if wave_amount>amount then
      self.wavetask[playernmb]:Cancel()
      self.fx_wavetask[playernmb]:Cancel()
    end

end

function AvalancheController:SpawnAvalancheAtPoint(playernmb, srs_x,srs_z, amount, dirx, diry)
  --initialising
  if not amount then amount = 50 end
  self.avalance_grid[playernmb] = {}
  for i=-30, 30 do
    self.avalance_grid[playernmb][i] = {}
    for j=-30, 30 do
      if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(srs_x + self.dist_between * i + dirx/2, 0, srs_z + self.dist_between * j+ diry/2)) then
        self.avalance_grid[playernmb][i][j] = 999
      else
        self.avalance_grid[playernmb][i][j] = 0
      end
    end
  end
  
  -- locate existing piles
  local existing_piles = TheSim:FindEntities(srs_x, 0, srs_z, 30, nil, nil, SNOWPILE_TAGS)
  for k, v in pairs(existing_piles) do
    local x1, _, z1 = v.Transform:GetWorldPosition()
    if v.pile_stage == 9 or v.prefab == "mountain_snowpile" then -- Ignore the height of conventional pile...
      self.avalance_grid[playernmb][math.ceil((x1-srs_x)/self.dist_between)][math.ceil((z1-srs_z)/self.dist_between)] = 999
    else
      self.avalance_grid[playernmb][math.ceil((x1-srs_x)/self.dist_between)][math.ceil((z1-srs_z)/self.dist_between)] = v.pile_stage
    end
  end
  local wave_amount = 1
  
  self.fx_wavetask[playernmb] = self.inst:DoPeriodicTask(0.1+ math.random()*0.1, function()
    for i = 1, wave_amount/2 do 
      local fx = SpawnPrefab("ms_snowpile_fall_fx")
      local shift_x, shift_z = math.random(-1+dirx,1+dirx), math.random(-1+diry,1+diry)
      if self.avalance_grid[playernmb][shift_x][shift_z] < 10 then
        fx.Transform:SetPosition(srs_x+shift_x, self.avalance_grid[playernmb][shift_x][shift_z] * 0.2, srs_z+shift_z)
      end
    end
  end)
  
  self.wavetask[playernmb] = self.inst:DoPeriodicTask(0.1 + math.random()*0.2, function() self:SpawnWave(playernmb, srs_x, srs_z, amount, wave_amount, dirx, diry) amount = amount - wave_amount wave_amount = wave_amount + 3 end)
end

function AvalancheController:OnSave()
  return {
    avalanche_counter = self.avalanche_counter,
  }
end

function AvalancheController:OnLoad(data)
  if data and data.avalanche_counter then
    self.avalanche_counter = data.avalanche_counter
  end
end

return AvalancheController
