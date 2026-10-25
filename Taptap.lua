--[[
    Tap Simulator Reborn - Auto Farm (Rayfield UI)
    Fixed & Complete Edition: 100% Invisible Hatch Animation (3D Models, 2D GUI, Audio, Blur)
    Author: Rolance Mahena / KYY (Fixed Edition)
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════ REMOTES ═══════════
local RS = ReplicatedStorage:WaitForChild("RemoteServices")
local remotes = {
    Tap     = RS.TapService.RE.TapRequested,
    Egg     = RS.EggService.RE.EggHatchRequested,
    Rebirth = RS.RebirthService.RE.RebirthRequested,
    Island  = RS.IslandService.RF.Travel,
}

-- ═══════════ CONFIG ═══════════
local Config = {
    HatchEgg       = "Void",
    HatchCount     = 3,
    TeleportIsland = "Spawn",
    RebirthIndex   = 14,
}

local Islands = {"Spawn", "Sky Island", "Autumn", "Mushroom", "Desert", "Crystal Cave", "Shadow Realm"}

-- ═══════════ STATE ═══════════
local Toggles = {
    AutoTap       = false,
    AutoRebirth   = false,
    AutoHatch     = false,
    HideHatchAnim = false,
}

-- ═══════════ FUNCTIONS ═══════════
local tapSeq = 0

local function DoTap()
    tapSeq = tapSeq + 1
    remotes.Tap:FireServer({Auto = false, ClientSequence = tapSeq})
end

local function DoRebirth()
    remotes.Rebirth:FireServer({Index = Config.RebirthIndex})
end

local function DoHatch()
    -- Forward Skip & SkipAnimation flags directly to the server remote as well
    remotes.Egg:FireServer({
        Auto = true,
        Count = Config.HatchCount,
        Egg = Config.HatchEgg,
        Seq = 1,
        Skip = Toggles.HideHatchAnim,
        SkipAnimation = Toggles.HideHatchAnim
    })
end

local function DoTeleport(island)
    remotes.Island:InvokeServer({Island = island or Config.TeleportIsland, Source = "Portal"})
end

local function RunLoop(name, fn, delay)
    task.spawn(function()
        while Toggles[name] do
            pcall(fn)
            task.wait(delay or 0.1)
        end
    end)
end

-- ═══════════ ADVANCED HATCH ANIMATION BYPASS CONTROLLER ═══════════
-- Complete 3D + 2D + RenderStepped + Attribute + Blur Suppression System
local HatchHider = {
    Connections = {},
    HiddenInstances = {}, -- Maps instance -> original state record
    Keywords = {
        "hatch", "egg", "unbox", "opening", "open", "anim",
        "cutscene", "cinematic", "draw", "roll", "pethatch", "petopen", "egg_open"
    }
}

local function IsHatchElement(obj)
    if not obj or not obj.Name then return false end
    local name = obj.Name:lower()

    -- Do not hide player HUD action buttons
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        local pName = obj.Parent and obj.Parent.Name:lower() or ""
        if pName:find("hud") or pName:find("bar") or pName:find("menu") then
            return false
        end
    end

    local match = false
    for _, kw in ipairs(HatchHider.Keywords) do
        if name:find(kw) then
            match = true
            break
        end
    end
    if not match then return false end

    -- Verify it is a visual container or cutscene object
    if obj:IsA("ScreenGui") or obj:IsA("ViewportFrame") or obj:IsA("CanvasGroup") then
        return true
    end
    if obj:IsA("Frame") or obj:IsA("ImageLabel") then
        if name:find("hatch") or name:find("open") or name:find("cutscene") or name:find("anim") or name:find("unbox") then
            return true
        end
        if name:find("egg") and not (name:find("btn") or name:find("button") or name:find("shop")) then
            return true
        end
    end
    if obj:IsA("Model") or obj:IsA("BasePart") then
        return true
    end

    return false
end

local function Suppress3D(obj)
    if not Toggles.HideHatchAnim or not obj then return end
    pcall(function()
        if obj:IsA("Model") then
            if obj.PrimaryPart then
                obj:PivotTo(CFrame.new(0, -9999, 0))
            end
            for _, descendant in ipairs(obj:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Transparency = 1
                    descendant.CanCollide = false
                elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail") or descendant:IsA("Highlight") or descendant:IsA("Light") then
                    descendant.Enabled = false
                elseif descendant:IsA("Sound") then
                    descendant:Stop()
                    descendant.Volume = 0
                end
            end
        elseif obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CanCollide = false
            obj.CFrame = CFrame.new(0, -9999, 0)
        end
    end)
end

local function Suppress2D(obj)
    if not Toggles.HideHatchAnim or not obj then return end

    if obj:IsA("ScreenGui") then
        if not HatchHider.HiddenInstances[obj] then
            HatchHider.HiddenInstances[obj] = {prop = "Enabled", original = obj.Enabled}
        end
        obj.Enabled = false

        local id = tostring(obj) .. "_Enabled"
        if not HatchHider.Connections[id] then
            HatchHider.Connections[id] = obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                if Toggles.HideHatchAnim and obj.Enabled then
                    obj.Enabled = false
                end
            end)
        end

    elseif obj:IsA("GuiObject") then
        if not HatchHider.HiddenInstances[obj] then
            HatchHider.HiddenInstances[obj] = {
                prop = "GuiObject",
                visible = obj.Visible,
                position = obj.Position,
                groupTrans = obj:IsA("CanvasGroup") and obj.GroupTransparency or nil
            }
        end

        -- Triple invisibility safeguard:
        -- 1. Visible = false
        obj.Visible = false
        -- 2. Position = (100, 0, 100, 0) far offscreen (prevents tweens from forcing on-screen display)
        obj.Position = UDim2.new(100, 0, 100, 0)
        -- 3. Transparent if CanvasGroup
        if obj:IsA("CanvasGroup") then
            obj.GroupTransparency = 1
        end

        local id = tostring(obj) .. "_Visible"
        if not HatchHider.Connections[id] then
            HatchHider.Connections[id] = obj:GetPropertyChangedSignal("Visible"):Connect(function()
                if Toggles.HideHatchAnim and obj.Visible then
                    obj.Visible = false
                    obj.Position = UDim2.new(100, 0, 100, 0)
                end
            end)
        end
    end
end

function HatchHider.Enable()
    HatchHider.Reset(false)

    -- 1. Set fast-hatch attributes on LocalPlayer
    pcall(function()
        LocalPlayer:SetAttribute("SkipAnimation", true)
        LocalPlayer:SetAttribute("SkipEggAnimation", true)
    end)

    -- 2. Scan and suppress existing PlayerGui elements
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if playerGui then
        for _, descendant in ipairs(playerGui:GetDescendants()) do
            if IsHatchElement(descendant) then
                pcall(Suppress2D, descendant)
            end
        end

        -- Frame-0 hook for any newly created UI
        HatchHider.Connections["DescendantAdded"] = playerGui.DescendantAdded:Connect(function(descendant)
            if not Toggles.HideHatchAnim then return end
            if IsHatchElement(descendant) then
                task.defer(function()
                    pcall(Suppress2D, descendant)
                end)
            end
        end)
    end

    -- 3. Hook Workspace & Camera for 3D egg models
    local camera = Workspace.CurrentCamera
    if camera then
        for _, child in ipairs(camera:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                Suppress3D(child)
            end
        end
        HatchHider.Connections["CameraChild"] = camera.ChildAdded:Connect(function(child)
            if not Toggles.HideHatchAnim then return end
            task.defer(function()
                Suppress3D(child)
            end)
        end)
    end

    HatchHider.Connections["WorkspaceChild"] = Workspace.ChildAdded:Connect(function(child)
        if not Toggles.HideHatchAnim then return end
        if IsHatchElement(child) then
            task.defer(function()
                Suppress3D(child)
            end)
        end
    end)

    -- 4. Lighting blur & effect suppression
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
            if not HatchHider.HiddenInstances[effect] then
                HatchHider.HiddenInstances[effect] = {prop = "Effect", original = effect.Enabled}
            end
            effect.Enabled = false
        end
    end

    -- 5. RenderStepped Guard: runs every frame before rendering (locks camera & mutes cutscenes)
    HatchHider.Connections["RenderStepped"] = RunService.RenderStepped:Connect(function()
        if not Toggles.HideHatchAnim then return end

        local cam = Workspace.CurrentCamera
        if cam then
            if cam.CameraType == Enum.CameraType.Scriptable then
                cam.CameraType = Enum.CameraType.Custom
            end
        end

        for _, effect in ipairs(Lighting:GetChildren()) do
            if (effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect")) and effect.Enabled then
                effect.Enabled = false
            end
        end
    end)
end

function HatchHider.Reset(restoreUI)
    if restoreUI == nil then restoreUI = true end

    -- 1. Disconnect all listeners
    for key, conn in pairs(HatchHider.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(HatchHider.Connections)

    -- 2. Restore all 2D Guis, CanvasGroups, and Lighting Effects
    if restoreUI then
        for obj, data in pairs(HatchHider.HiddenInstances) do
            pcall(function()
                if obj and obj.Parent then
                    if data.prop == "Enabled" and obj:IsA("ScreenGui") then
                        obj.Enabled = true
                    elseif data.prop == "GuiObject" and obj:IsA("GuiObject") then
                        obj.Visible = (data.visible ~= nil) and data.visible or true
                        if data.position then
                            obj.Position = data.position
                        end
                        if data.groupTrans ~= nil and obj:IsA("CanvasGroup") then
                            obj.GroupTransparency = data.groupTrans
                        end
                    elseif data.prop == "Effect" then
                        obj.Enabled = (data.original ~= nil) and data.original or true
                    end
                end
            end)
        end
        table.clear(HatchHider.HiddenInstances)
    end

    -- 3. Reset Camera
    local camera = Workspace.CurrentCamera
    if camera and camera.CameraType == Enum.CameraType.Scriptable then
        camera.CameraType = Enum.CameraType.Custom
    end

    -- 4. Clean attributes
    pcall(function()
        LocalPlayer:SetAttribute("SkipAnimation", nil)
        LocalPlayer:SetAttribute("SkipEggAnimation", nil)
    end)
end

-- ═══════════ ANTI-AFK ═══════════
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ═══════════ AUTO RE-EXECUTE ═══════════
if queue_on_teleport then
    pcall(function()
        queue_on_teleport(game:HttpGet("PASTE_YOUR_SCRIPT_URL_OR_RAW_LINK_HERE"))
    end)
end

-- ═══════════ RAYFIELD GUI ═══════════
local Window = Rayfield:CreateWindow({
    Name = "Tap Simulator Reborn - Rolance Mahena",
    LoadingTitle = "TapSim Auto Farm",
    LoadingSubtitle = "by KYY [Hatch Bypass Fixed]",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TSR",
        FileName = "TSR_Config",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ─── Main Tab ───
local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Tap",
    CurrentValue = false,
    Flag = "AutoTap",
    Callback = function(Value)
        Toggles.AutoTap = Value
        if Value then
            task.spawn(function()
                while Toggles.AutoTap do
                    for _ = 1, 5 do
                        if not Toggles.AutoTap then break end
                        pcall(DoTap)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

MainTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(Value)
        Toggles.AutoRebirth = Value
        if Value then RunLoop("AutoRebirth", DoRebirth, 1) end
    end,
})

MainTab:CreateDropdown({
    Name = "Rebirth Index",
    Options = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14"},
    CurrentOption = {"14"},
    MultipleOptions = false,
    Flag = "RebirthIndex",
    Callback = function(Option)
        Config.RebirthIndex = tonumber(Option[1]) or 14
    end,
})

MainTab:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = false,
    Flag = "AutoHatch",
    Callback = function(Value)
        Toggles.AutoHatch = Value
        if Value then RunLoop("AutoHatch", DoHatch, 1) end
    end,
})

MainTab:CreateInput({
    Name = "Egg Name",
    PlaceholderText = "Void",
    RemoveTextAfterFocusLost = false,
    Flag = "EggName",
    Callback = function(Text)
        Config.HatchEgg = Text
        Rayfield:Notify({Title = "Config", Content = "Egg set to: " .. Text, Duration = 2})
    end,
})

-- FIXED: Hide Egg Hatch Animation (Complete 3D & 2D Invisible Bypass)
MainTab:CreateToggle({
    Name = "Hide Egg Hatch Animation",
    CurrentValue = false,
    Flag = "HideHatchAnim",
    Callback = function(Value)
        Toggles.HideHatchAnim = Value
        if Value then
            HatchHider.Enable()
            Rayfield:Notify({
                Title = "Egg Animation",
                Content = "Hatch animation 100% hidden (3D, 2D, Blur & Audio bypassed)",
                Duration = 2,
            })
        else
            HatchHider.Reset(true)
            Rayfield:Notify({
                Title = "Egg Animation",
                Content = "Hatch animation restored & state reset",
                Duration = 2,
            })
        end
    end,
})

-- ─── Misc Tab ───
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateDropdown({
    Name = "Teleport Island",
    Options = Islands,
    CurrentOption = {"Spawn"},
    MultipleOptions = false,
    Flag = "TeleportIsland",
    Callback = function(Option)
        Config.TeleportIsland = Option[1]
    end,
})

MiscTab:CreateButton({
    Name = "🚀 Teleport",
    Callback = function()
        local ok, err = pcall(DoTeleport)
        Rayfield:Notify({
            Title = ok and "Teleport" or "Error",
            Content = ok and "Travelling to " .. Config.TeleportIsland or tostring(err),
            Duration = 3,
        })
    end,
})

Rayfield:Notify({
    Title = "TSR Auto Farm",
    Content = "Script loaded! Anti-AFK active & Hatch Bypass ready ✅",
    Duration = 3,
})

print("✅ TSR AutoFarm (Rayfield - Hatch Bypass Fixed) loaded!")
