--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local p = Players.LocalPlayer

if CoreGui:FindFirstChild("ROLANCE_WALANG_BITAW_AFK_Timer") then
    CoreGui.YAMEN_RAKB_AFK_Timer:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ROLANCE_WALANG_BITAW_AFK_Timer"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 185)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -92)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(100, 15, 15)
MainStroke.Thickness = 1.5

local RainContainer = Instance.new("Frame", MainFrame)
RainContainer.Size = UDim2.new(1, 0, 1, 0)
RainContainer.BackgroundTransparency = 1

local function SpawnRainDrop()
    local drop = Instance.new("Frame")
    local startX = math.random(0, 260)
    local dropLength = math.random(10, 20)
    local dropSpeed = math.random(6, 12) / 10

    drop.Size = UDim2.new(0, 2, 0, dropLength)
    drop.Position = UDim2.new(0, startX, 0, -dropLength)
    drop.BackgroundColor3 = Color3.fromRGB(220, 20, 40)
    drop.BackgroundTransparency = math.random(3, 6) / 10
    drop.BorderSizePixel = 0
    drop.Parent = RainContainer

    local gradient = Instance.new("UIGradient", drop)
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 0))
    }

    local tween = TweenService:Create(drop, TweenInfo.new(dropSpeed, Enum.EasingStyle.Linear), {
        Position = UDim2.new(0, startX - math.random(8, 15), 1, dropLength)
    })
    tween:Play()
    tween.Completed:Connect(function() drop:Destroy() end)
end

task.spawn(function()
    while MainFrame and MainFrame.Parent do
        SpawnRainDrop()
        task.wait(0.05)
    end
end)

local Header = Instance.new("Frame", MainFrame)
Header.BackgroundTransparency = 1
Header.Position = UDim2.new(0, 0, 0, 10)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.ZIndex = 2

local UserImage = Instance.new("ImageLabel", Header)
UserImage.BackgroundTransparency = 1
UserImage.Position = UDim2.new(0, 12, 0, 0)
UserImage.Size = UDim2.new(0, 26, 0, 26)
UserImage.ZIndex = 2
Instance.new("UICorner", UserImage).CornerRadius = UDim.new(1, 0)
pcall(function()
    UserImage.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)

local TitleLabel = Instance.new("TextLabel", Header)
TitleLabel.Size = UDim2.new(1, -45, 1, 0)
TitleLabel.Position = UDim2.new(0, 45, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ROLANCE_MAHENA AFK"
TitleLabel.TextColor3 = Color3.fromRGB(255, 40, 40)
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.FredokaOne
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 2

local TimerLabel = Instance.new("TextLabel", MainFrame)
TimerLabel.Size = UDim2.new(1, 0, 0, 30)
TimerLabel.Position = UDim2.new(0, 0, 0, 45)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "000:00:00"
TimerLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
TimerLabel.TextSize = 22
TimerLabel.Font = Enum.Font.Code
TimerLabel.ZIndex = 2

local DayLabel = Instance.new("TextLabel", MainFrame)
DayLabel.Size = UDim2.new(1, 0, 0, 20)
DayLabel.Position = UDim2.new(0, 0, 0, 75)
DayLabel.BackgroundTransparency = 1
DayLabel.Text = "day : 0"
DayLabel.TextColor3 = Color3.fromRGB(220, 150, 150)
DayLabel.TextSize = 14
DayLabel.Font = Enum.Font.SourceSansBold
DayLabel.ZIndex = 2

local SavesLabel = Instance.new("TextLabel", MainFrame)
SavesLabel.Size = UDim2.new(1, 0, 0, 20)
SavesLabel.Position = UDim2.new(0, 0, 0, 105)
SavesLabel.BackgroundTransparency = 1
SavesLabel.Text = "Kicks Prevented: 0"
SavesLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
SavesLabel.TextSize = 13
SavesLabel.Font = Enum.Font.SourceSansBold
SavesLabel.ZIndex = 2

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0, 135)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Anti-AFK: Active"
StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.ZIndex = 2

local kicksSaved = 0

p.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
    pcall(function()
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    kicksSaved = kicksSaved + 1
    SavesLabel.Text = "Kicks Prevented: " .. kicksSaved
end)

local startTime = tick()
task.spawn(function()
    while true do
        local elapsedTime = tick() - startTime
        local hours = math.floor(elapsedTime / 3600)
        local minutes = math.floor((elapsedTime % 3600) / 60)
        local seconds = math.floor(elapsedTime % 60)
        local days = math.floor(elapsedTime / 86400)
        
        TimerLabel.Text = string.format("%03d:%02d:%02d", hours, minutes, seconds)
        DayLabel.Text = "day : " .. days
        
        task.wait(1)
    end
end)
