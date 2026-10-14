--[[
    Tap Simulator Reborn - Auto Farm (Rayfield UI)
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
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

-- ═══════════ HIDE HATCH ANIMATION ═══════════
local function TryHideHatchGui()
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("GuiObject") and gui.Name:lower():find("hatch") then
                gui.Visible = false
            end
        end
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
    LoadingSubtitle = "by KYY",
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

MainTab:CreateToggle({
    Name = "Hide Egg Hatch Animation",
    CurrentValue = false,
    Flag = "HideHatchAnim",
    Callback = function(Value)
        Toggles.HideHatchAnim = Value
        if Value then
            task.spawn(function()
                while Toggles.HideHatchAnim do
                    TryHideHatchGui()
                    task.wait(0.5)
                end
            end)
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
    Content = "Script loaded! Anti-AFK active ✅",
    Duration = 3,
})

print("✅ TSR AutoFarm (Rayfield) loaded!")
