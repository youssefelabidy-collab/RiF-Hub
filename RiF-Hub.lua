local environment = getgenv()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function() loadstring(game:HttpGet("https://scriptblox.com/ingest/clientv2.lua"))("proj_c44378984b4d", "1.0.0", false) end)

environment.RiFHubFeatures = environment.RiFHubFeatures or {}
local features = environment.RiFHubFeatures
if features.PerfectThrow then
features.PerfectThrow:Stop()
end

local controllers = player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")
local meter = require(controllers:WaitForChild("ThrowMeter"))
local original = meter.Run

local existingGui = playerGui:FindFirstChild("RiFHubThrowGui")
if existingGui then
existingGui:Destroy()
end

local feature = {Name = "RiF Hub", Enabled = true, Status = "Enabled"}
local wrapper

local gui = Instance.new("ScreenGui")
gui.Name = "RiFHubThrowGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(250, 136)
win.Position = UDim2.new(0.5, -125, 0.2, 0)
win.BackgroundColor3 = Color3.fromRGB(14, 19, 33)
win.BorderSizePixel = 0
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 12)

local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(59, 130, 246)
winStroke.Thickness = 1.5
winStroke.Parent = win

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 34)
top.BackgroundColor3 = Color3.fromRGB(22, 31, 52)
top.BorderSizePixel = 0
top.Parent = win
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -72, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "RiF Hub • Perfect Throw"
title.TextColor3 = Color3.fromRGB(241, 245, 249)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(24, 22)
minBtn.Position = UDim2.new(1, -56, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(36, 51, 82)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 15
minBtn.Parent = top
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(24, 22)
closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.Parent = top
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -24, 0, 22)
statusLbl.Position = UDim2.fromOffset(12, 42)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: Enabled (Tap: 0.6)"
statusLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
statusLbl.Font = Enum.Font.GothamMedium
statusLbl.TextSize = 12
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = win

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -24, 0, 46)
toggleBtn.Position = UDim2.fromOffset(12, 72)
toggleBtn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
toggleBtn.Text = "PERFECT THROW : ON"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Parent = win
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 9)

local bubble = Instance.new("TextButton")
bubble.Size = UDim2.fromOffset(54, 54)
bubble.Position = win.Position
bubble.BackgroundColor3 = Color3.fromRGB(14, 19, 33)
bubble.Text = "RiF"
bubble.TextColor3 = Color3.fromRGB(96, 165, 250)
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 14
bubble.Visible = false
bubble.Parent = gui
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)

local bubbleStroke = Instance.new("UIStroke")
bubbleStroke.Color = Color3.fromRGB(59, 130, 246)
bubbleStroke.Thickness = 1.5
bubbleStroke.Parent = bubble

local function refreshUI()
if feature.Enabled then
toggleBtn.Text = "PERFECT THROW : ON"
toggleBtn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
statusLbl.Text = "Status: Enabled (Tap: 0.6)"
statusLbl.TextColor3 = Color3.fromRGB(134, 239, 172)
else
toggleBtn.Text = "PERFECT THROW : OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
statusLbl.Text = "Status: Stopped"
statusLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
end
end

function feature:Stop()
if not self.Enabled then
return
end
self.Enabled = false
self.Status = "Stopped"
if meter.Run == wrapper then
meter.Run = original
end
if features.PerfectThrow == self then
features.PerfectThrow = nil
end
refreshUI()
end

function feature:Start()
if self.Enabled then
return
end
self.Enabled = true
self.Status = "Enabled"
if meter.Run ~= wrapper then
meter.Run = wrapper
end
features.PerfectThrow = self
refreshUI()
end

wrapper = function(instance, ...)
if not feature.Enabled then
return original(instance, ...)
end
local previousTap = meter.TestAutoTap
meter.TestAutoTap = 0.6
instance:SetLocked(true)
local result = table.pack(pcall(original, instance, ...))
if meter.TestAutoTap == 0.6 then
meter.TestAutoTap = previousTap
end
if not result[1] then
error(result[2], 0)
end
return table.unpack(result, 2, result.n)
end

meter.Run = wrapper
features.PerfectThrow = feature

toggleBtn.MouseButton1Click:Connect(function()
if feature.Enabled then
feature:Stop()
else
feature:Start()
end
end)

minBtn.MouseButton1Click:Connect(function()
bubble.Position = win.Position
win.Visible = false
bubble.Visible = true
end)

bubble.MouseButton1Click:Connect(function()
win.Position = bubble.Position
bubble.Visible = false
win.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
feature:Stop()
gui:Destroy()
end)

local function makeDraggable(frame, grip)
local dragging = false
local dragInput, dragStart, startPos

grip.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = frame.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
dragging = false
end
end)
end
end)

grip.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)

UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end)
end

makeDraggable(win, top)
makeDraggable(bubble, bubble)
refreshUI()

return feature
