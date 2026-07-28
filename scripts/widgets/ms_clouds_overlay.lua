local UIAnim = require("widgets/uianim")

local MsCloudsOverlay = Class(UIAnim, function(self, owner)
    self.owner = owner
    UIAnim._ctor(self)

    self:SetClickable(false)

    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_TOP)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)

    local animstate = self:GetAnimState()
    animstate:SetBank("cloud_overlay")
    animstate:SetBuild("clouds_overlay")
        animstate:SetDefaultEffectHandle("shaders/ui_anim_cc.ksh")
    animstate:PlayAnimation("idle2", true)
    animstate:UseColourCube(true)
    animstate:SetUILightParams(2.0, 4.0, 4.0, 20.0)

   --animstate:SetScale(0.5,0.5,0.5)
    --[[self:Hide()

    self.inst:ListenForEvent("roseglassesvision", function(owner, data)
        self:Toggle(data.enabled)
    end, owner)

    if owner ~= nil and owner.components.playervision ~= nil and owner.components.playervision:HasRoseGlassesVision() then
        self:Toggle(true)
    end
    --]]
end)

function MsCloudsOverlay:Toggle(show)
    if show and not self.shown then
        self:Enable()
    elseif not show and self.shown then
        self:Disable()
    end
    self.shown = show
end

function MsCloudsOverlay:Enable()
    if self.hidetask ~= nil then
        self.hidetask:Cancel()
        self.hidetask = nil
    end
    self:Show()

    local animstate = self:GetAnimState()
    animstate:PlayAnimation("over_pre")
    animstate:PushAnimation("over_idle", true)
end

function MsCloudsOverlay:Disable()
    local animstate = self:GetAnimState()
    animstate:PlayAnimation("over_pst")

    local duration = self.inst.AnimState:GetCurrentAnimationLength() + FRAMES
    if self.hidetask ~= nil then
        self.hidetask:Cancel()
        self.hidetask = nil
    end
    self.hidetask = self.inst:DoTaskInTime(duration, function(inst) self:Hide() end)
end

return MsCloudsOverlay
