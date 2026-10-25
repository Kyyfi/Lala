--[[
    Tap Simulator Reborn - Auto Farm (Rayfield UI)
    Fixed & Optimized: Hatch Animation Bypass & Proper Trigger Reset Logic
    Author: Rolance Mahena / KYY (Fixed Edition)
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
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
    RebirthIndex   = 18,
}

local Islands = {"Spawn", "Sky Island", "Autumn", "Mushroom", "Desert", "Crystal Cave", "Shadow Realm", "Volcano", "Heaven"}

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
    remotes.Egg:FireServer({Auto = true, Count = Config.HatchCount, Egg = Config.HatchEgg, Seq = 1})
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

-- ═══════════ ROBUST HATCH ANIMATION BYPASS & RESET CONTROLLER ═══════════
local HatchHider = {
    Connections = {},
    HiddenInstances = {}, -- Maps instance -> {prop = "Enabled" | "Visible", original = boolean}
    Keywords = {
        "hatch", "eggopen", "egg_open", "eggopening", "egganim",
        "hatchanim", "openanim", "eggcutscene", "hatchgui", "hatchscreen"
    }
}

local function IsHatchElement(obj)
    if not obj or not obj.Name then return false end
    local name = obj.Name:lower()
    for _, kw in ipairs(HatchHider.Keywords) do
        if name:find(kw) then
            return true
        end
    end
    return false
end

local function SuppressElement(obj)
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
            HatchHider.HiddenInstances[obj] = {prop = "Visible", original = obj.Visible}
        end
        obj.Visible = false

        local id = tostring(obj) .. "_Visible"
        if not HatchHider.Connections[id] then
            HatchHider.Connections[id] = obj:GetPropertyChangedSignal("Visible"):Connect(function()
                if Toggles.HideHatchAnim and obj.Visible then
                    obj.Visible = false
                end
            end)
        end
    end
end

function HatchHider.Enable()
    HatchHider.Reset(false)

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if playerGui then
        for _, descendant in ipairs(playerGui:GetDescendants()) do
            if IsHatchElement(descendant) then
                pcall(SuppressElement, descendant)
            end
        end

        HatchHider.Connections["DescendantAdded"] = playerGui.DescendantAdded:Connect(function(descendant)
            if not Toggles.HideHatchAnim then return end
            if IsHatchElement(descendant) then
                task.defer(function()
                    pcall(SuppressElement, descendant)
                end)
            end
        end)
    end

    HatchHider.Connections["Watchdog"] = task.spawn(function()
        local camera = Workspace.CurrentCamera
        while Toggles.HideHatchAnim do
            if camera and camera.CameraType == Enum.CameraType.Scriptable then
                camera.CameraType = Enum.CameraType.Custom
            end

            if playerGui then
                for _, child in ipairs(playerGui:GetChildren()) do
                    if child:IsA("ScreenGui") and IsHatchElement(child) and child.Enabled then
                        child.Enabled = false
                    end
                end
            end

            task.wait(0.1)
        end
    end)
end

function HatchHider.Reset(restoreUI)
    if restoreUI == nil then restoreUI = true end

    -- 1. Disconnect and clear all event listeners
    for key, conn in pairs(HatchHider.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(HatchHider.Connections)

    -- 2. Restore all previously hidden GUIs to their proper state
    if restoreUI then
        for obj, data in pairs(HatchHider.HiddenInstances) do
            pcall(function()
                if obj and obj.Parent then
                    if data.prop == "Enabled" and obj:IsA("ScreenGui") then
                        obj.Enabled = true
                    elseif data.prop == "Visible" and obj:IsA("GuiObject") then
                        obj.Visible = true
                    end
                end
            end)
        end
        table.clear(HatchHider.HiddenInstances)
    end

    -- 3. Guarantee camera returns to player control
    local camera = Workspace.CurrentCamera
    if camera and camera.CameraType == Enum.CameraType.Scriptable then
        camera.CameraType = Enum.CameraType.Custom
    end
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
    Options = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18"},
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
    PlaceholderText = "Heaven",
    RemoveTextAfterFocusLost = false,
    Flag = "EggName",
    Callback = function(Text)
        Config.HatchEgg = Text
        Rayfield:Notify({Title = "Config", Content = "Egg set to: " .. Text, Duration = 2})
    end,
})

-- FIXED: Hide Egg Hatch Animation with complete trigger state reset logic
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
                Content = "Hatch animation hidden (Instant skip active)",
                Duration = 2,
            })
        else
            HatchHider.Reset(true)
            Rayfield:Notify({
                Title = "Egg Animation",
                Content = "Hatch animation restored & reset",
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
