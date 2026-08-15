local UIAnim = require("widgets/uianim")

local MinimapCloudOverlay = Class(UIAnim, function(self, owner)
    self.owner = owner
    UIAnim._ctor(self)

    self:SetClickable(false)
    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)

    local animstate = self:GetAnimState()
    animstate:SetBank("minimap_cloud_overlay")
    animstate:SetBuild("minimap_cloud_overlay")
    --animstate:SetDefaultEffectHandle("shaders/ui_anim_cc.ksh")
    animstate:PlayAnimation("idle", true)
    animstate:UseColourCube(true)
    animstate:SetSymbolLightOverride("minimap_cloud_overlay", 1)
    --animstate:SetMultColour(0.2, 0.2, 0.3, 1)
    
    self:Disable()
end)

function MinimapCloudOverlay:Toggle(show)
    if show and not self.shown then
        self:Enable()
    elseif not show and self.shown then
        self:Disable()
    end
    self.shown = show
end

function MinimapCloudOverlay:Enable()
    if self.hidetask ~= nil then
        self.hidetask:Cancel()
        self.hidetask = nil
    end
    self:Show()

    local animstate = self:GetAnimState()
    animstate:PushAnimation("idle", true)
end

function MinimapCloudOverlay:Disable()
    self:Hide() 
end

return MinimapCloudOverlay
