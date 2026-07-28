local Teleporter = require("components/teleporter")
local old_Teleport = Teleporter.Teleport


local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function NoPlayersOrHoles(pt)
    return not (IsAnyPlayerInRange(pt.x, 0, pt.z, 2) or TheWorld.Map:IsPointNearHole(pt))
end

function Teleporter:Teleport(obj, ...)
  -- Klei, fix you teleporters. They should not teleport you on void. Like what is this, seriously?
  
  local targetDesination = self.targetTeleporterTemporary or self.targetTeleporter -- Do not adjust destination for selfmanaged.
  local targetTeleporter = self.targetTeleporterTemporary or (self.selfmanaged and self.inst) or self.targetTeleporter
  if targetDesination.components.teleporter.teleport_offset then
      local notself = targetDesination.components.teleporter
      print("HEY, IM TELEPORTING ALL OVER YOUR SCREEN")
    if targetTeleporter ~= nil then
        local target_x, target_y, target_z = targetDesination.Transform:GetWorldPosition()
        if obj.Physics ~= nil then
            obj.Physics:Teleport(target_x + notself.teleport_offset.x, target_y + notself.teleport_offset.y, target_z + notself.teleport_offset.z)
        elseif obj.Transform ~= nil then
            obj.Transform:SetPosition(target_x + notself.teleport_offset.x, target_y + notself.teleport_offset.y, target_z + notself.teleport_offset.z)
        end
    end
  else
    old_Teleport(self, obj, ...)
  end
end