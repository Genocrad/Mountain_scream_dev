local containers = require("containers")
local cooking = require("cooking")
local params = containers.params


local oldfn = params.cookpot.itemtestfn
params.cookpot.itemtestfn = function(container, item, slot, ...)
  return not item:HasTag("ms_ore") and oldfn(container, item, slot, ...)
end

params.archive_cookpot = params.cookpot
params.portablecookpot = params.cookpot
