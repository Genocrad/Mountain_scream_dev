local Stackable = require("components/stackable")
local old_Get =  Stackable.Get


local ENV = env
GLOBAL.setfenv(1, GLOBAL)

function Stackable:Get(num, ...)
  -- Luigi: No components temperature but inventoryitem temperature? What? Why????? 
  if self.inst:HasTag("ms_temperature_states") then
    local num_to_get = num or 1
    -- If we have more than one item in the stack
    if self.stacksize > num_to_get then
        local instance = SpawnPrefab( self.inst.prefab, self.inst.skinname, self.inst.skin_id, nil )

        self:SetStackSize(self.stacksize - num_to_get)
        instance.components.stackable:SetStackSize(num_to_get)

        if self.ondestack ~= nil then
            self.ondestack(instance, self.inst)
        end

        if instance.components.perishable ~= nil then
            instance.components.perishable.perishremainingtime = self.inst.components.perishable.perishremainingtime
        end

        if instance.components.curseditem ~= nil and self.inst.components.curseditem ~= nil then
            self.inst.components.curseditem:CopyCursedFields(instance.components.curseditem)
            if self.inst:HasTag("applied_curse") then
                instance.skipspeech = true
                instance:AddTag("applied_curse")
            end
        end

        if instance.components.rechargeable ~= nil and self.inst.components.rechargeable ~= nil then
            if not self.inst.components.rechargeable:IsCharged() then
                instance.components.rechargeable:SetChargeTime(self.inst.components.rechargeable:GetChargeTime())
                instance.components.rechargeable:SetCharge(self.inst.components.rechargeable:GetCharge())
            end
        end

        if instance.components.inventoryitem ~= nil and self.inst.components.inventoryitem ~= nil then
            if self.inst.components.inventoryitem.owner then
                instance.components.inventoryitem:OnPutInInventory(self.inst.components.inventoryitem.owner)
            end
            instance.components.inventoryitem:InheritMoisture(self.inst.components.inventoryitem:GetMoisture(), self.inst.components.inventoryitem:IsWet())
            instance.components.inventoryitem:SetTemperature(self.inst.components.inventoryitem:GetTemperature())
        end
        
         if instance.components.temperature ~= nil and self.inst.components.temperature ~= nil then

            instance.components.temperature:SetTemperature(self.inst.components.temperature:GetCurrent())
        end
        
        return instance
    end

    return self.inst
  else
    return old_Get(self, num, ...)
  end
end