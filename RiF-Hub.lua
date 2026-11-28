--[[
RiF Hub - Auto & Perfect Throw
Created by: Youssef Elabidy (RiF Hub)
GitHub: github.com/Youssefelabidy-collab
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local Controllers = player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")
local ThrowMeter = require(Controllers:WaitForChild("ThrowMeter"))
local ClientState = require(Controllers:WaitForChild("ClientState"))

local autoThrowEnabled = false
local perfectThrowEnabled = true
local gen = 0
local spotX = nil
local tapDelay = 0.8
local stats = { done = 0, failed = 0 }

if not ThrowMeter.__SNOrig then
ThrowMeter.__SNOrig = ThrowMeter.Run
end

local origRun = ThrowMeter.__SNOrig
ThrowMeter.Run = function(self, ...)
if perfectThrowEnabled and (autoThrowEnabled or self ~= nil) then
self.Locked = true
ThrowMeter.TestAutoTap = tapDelay
else
if type(self) == "table" then
self.Locked = false
end
ThrowMeter.TestAutoTap = nil
end
return origRun(self, ...)
end

local function getChar()
local char = player.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChildOfClass("Humanoid")
if root and hum and hum.Health > 0 then
return char, root, hum
end
end

local function groundUnder(pos, ignore)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = ignore
local hit = workspace:Raycast(pos + Vector3.new(0, 50, 0), Vector3.new(0, -300, 0), params)
return hit and hit.Position or nil
end

local function crossLine()
local char, root, hum = getChar()
if not root then return false end

local area = workspace:FindFirstChild("StarterArea")
local line = area and area:FindFirstChild("CrossLine")
if not area or not line then return false end

if hum.SeatPart then
hum.Sit = false
task.wait(0.2)
end

local halfX = area.Size.X / 2
local x = math.clamp(spotX or root.Position.X, area.Position.X - halfX + 2, area.Position.X + halfX - 2)
local z = line.Position.Z - 1.5
local ground = groundUnder(Vector3.new(x, area.Position.Y + area.Size.Y / 2, z), { char })
if not ground then return false end

local pos = ground + Vector3.new(0, hum.HipHeight + root.Size.Y / 2 + 0.1, 0)
local ok = pcall(function()
char:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1)))
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero
end)
return ok
end

local function makeDraggable(dragHandle, targetFrame)
local dragging = false
local dragInput, dragStart, startPos

dragHandle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = targetFrame.Position

input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
dragging = false
end
end)
end
end)

dragHandle.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)

UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
targetFrame.Position = UDim2.new(
startPos.X.Scale,
startPos.X.Offset + delta.X,
startPos.Y.Scale,
startPos.Y.Offset + delta.Y
)
end
end)
end

local function createRiFGui()
local parentGui = (type(gethui) == "function" and pcall(gethui)) and gethui() or game:GetService("CoreGui")
local old = parentGui:FindFirstChild("RiFHub_ThrowGUI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "RiFHub_ThrowGUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = parentGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(315, 255)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
main.BorderSizePixel = 0
main.Parent = sg

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(185, 28, 46)
stroke.Thickness = 1.6

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(16, 32, 62)
topBar.BorderSizePixel = 0
topBar.Parent = main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -80, 0, 20)
titleLbl.Position = UDim2.fromOffset(12, 4)
titleLbl.BackgroundTransparency = 1
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.Text = "RiF Hub | Throw Food"
titleLbl.Parent = topBar

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(1, -80, 0, 16)
subLbl.Position = UDim2.fromOffset(12, 22)
subLbl.BackgroundTransparency = 1
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 11
subLbl.TextColor3 = Color3.fromRGB(220, 70, 90)
subLbl.Text = "By Youssef (RiF Hub)"
subLbl.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(28, 28)
minBtn.Position = UDim2.new(1, -36, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(150, 22, 38)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Text = "-"
minBtn.Parent = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local container = Instance.new("ScrollingFrame")
container.Size = UDim2.new(1, -16, 1, -52)
container.Position = UDim2.fromOffset(8, 46)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 4
container.ScrollBarImageColor3 = Color3.fromRGB(185, 28, 46)
container.CanvasSize = UDim2.fromOffset(0, 0)
container.AutomaticCanvasSize = Enum.AutomaticSize.Y
container.Parent = main

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local minimized = false
local fullSize = main.Size
minBtn.MouseButton1Click:Connect(function()
minimized = not minimized
container.Visible = not minimized
main.Size = minimized and UDim2.fromOffset(fullSize.X.Offset, 42) or fullSize
minBtn.Text = minimized and "+" or "-"
end)
makeDraggable(topBar, main)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 28)
statusLbl.BackgroundColor3 = Color3.fromRGB(15, 24, 42)
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 11
statusLbl.TextColor3 = Color3.fromRGB(235, 240, 255)
statusLbl.Text = "Status: Idle"
statusLbl.TextWrapped = true
statusLbl.Parent = container
Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 6)

local function setStatus(txt)
statusLbl.Text = txt
end

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(1, 0, 0, 32)
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextSize = 12
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.Parent = container
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 6)

local perfBtn = Instance.new("TextButton")
perfBtn.Size = UDim2.new(1, 0, 0, 32)
perfBtn.Font = Enum.Font.GothamBold
perfBtn.TextSize = 12
perfBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
perfBtn.Parent = container
Instance.new("UICorner", perfBtn).CornerRadius = UDim.new(0, 6)

local laneBtn = Instance.new("TextButton")
laneBtn.Size = UDim2.new(1, 0, 0, 32)
laneBtn.BackgroundColor3 = Color3.fromRGB(24, 52, 98)
laneBtn.Font = Enum.Font.GothamBold
laneBtn.TextSize = 12
laneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
laneBtn.Text = "Set Throw Lane (Current X)"
laneBtn.Parent = container
Instance.new("UICorner", laneBtn).CornerRadius = UDim.new(0, 6)

local sliderHolder = Instance.new("Frame")
sliderHolder.Size = UDim2.new(1, 0, 0, 42)
sliderHolder.BackgroundColor3 = Color3.fromRGB(15, 24, 42)
sliderHolder.Parent = container
Instance.new("UICorner", sliderHolder).CornerRadius = UDim.new(0, 6)

local sliderLbl = Instance.new("TextLabel")
sliderLbl.Size = UDim2.new(1, -12, 0, 18)
sliderLbl.Position = UDim2.fromOffset(6, 2)
sliderLbl.BackgroundTransparency = 1
sliderLbl.TextXAlignment = Enum.TextXAlignment.Left
sliderLbl.Font = Enum.Font.GothamBold
sliderLbl.TextSize = 11
sliderLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
sliderLbl.Parent = sliderHolder

local barBg = Instance.new("TextButton")
barBg.Size = UDim2.new(1, -16, 0, 12)
barBg.Position = UDim2.fromOffset(8, 24)
barBg.BackgroundColor3 = Color3.fromRGB(30, 42, 68)
barBg.Text = ""
barBg.Parent = sliderHolder
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 6)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(190, 30, 50)
fill.BorderSizePixel = 0
fill.Parent = barBg
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)

local function refreshAutoBtn()
autoBtn.Text = ("Auto Throw : %s"):format(autoThrowEnabled and "ON" or "OFF")
autoBtn.BackgroundColor3 = autoThrowEnabled and Color3.fromRGB(165, 24, 42) or Color3.fromRGB(22, 34, 58)
end

local function refreshPerfBtn()
perfBtn.Text = ("Perfect Throw : %s"):format(perfectThrowEnabled and "ON" or "OFF")
perfBtn.BackgroundColor3 = perfectThrowEnabled and Color3.fromRGB(165, 24, 42) or Color3.fromRGB(22, 34, 58)
end

refreshAutoBtn()
refreshPerfBtn()

local function loop(myGen)
local function active()
return gen == myGen and autoThrowEnabled
end

while active() do
local t0 = os.clock()
while active() and ClientState.Busy and os.clock() - t0 < 60 do
task.wait(0.25)
end
if not active() then break end

local started = false
for _ = 1, 4 do
if not active() then break end
crossLine()
local t1 = os.clock()
while os.clock() - t1 < 3 do
if ClientState.Busy == "Throw" then
started = true
break
end
task.wait(0.1)
end
if started then break end
end

if started then
setStatus(("Throwing (Perfect: %s) | Done %d | Failed %d"):format(
perfectThrowEnabled and "ON" or "OFF",
stats.done,
stats.failed
))
local t2 = os.clock()
while ClientState.Busy == "Throw" and os.clock() - t2 < 60 do
task.wait(0.2)
end
stats.done += 1
setStatus(("Done %d | Failed %d"):format(stats.done, stats.failed))
task.wait(1)
else
stats.failed += 1
setStatus(("Didn't start (busy: %s) | Done %d | Failed %d"):format(
tostring(ClientState.Busy),
stats.done,
stats.failed
))
task.wait(2)
end
end

setStatus(("Stopped | Done %d | Failed %d"):format(stats.done, stats.failed))
end

autoBtn.MouseButton1Click:Connect(function()
gen += 1
autoThrowEnabled = not autoThrowEnabled
refreshAutoBtn()

if not autoThrowEnabled then
if not perfectThrowEnabled then
ThrowMeter.TestAutoTap = nil
end
setStatus(("Stopped | Done %d | Failed %d"):format(stats.done, stats.failed))
else
if not spotX then
local _, root = getChar()
if root then
spotX = root.Position.X
end
end
setStatus("Running...")
task.spawn(loop, gen)
end
end)

perfBtn.MouseButton1Click:Connect(function()
perfectThrowEnabled = not perfectThrowEnabled
refreshPerfBtn()
if not perfectThrowEnabled then
ThrowMeter.TestAutoTap = nil
end
end)

laneBtn.MouseButton1Click:Connect(function()
local _, root = getChar()
if root then
spotX = root.Position.X
laneBtn.Text = ("Lane Saved (X: %.1f)"):format(spotX)
end
end)

local minVal, maxVal, step = 0.4, 2.0, 0.1
local function setDelayFromAlpha(alpha)
alpha = math.clamp(alpha, 0, 1)
local raw = minVal + (maxVal - minVal) * alpha
local snapped = math.floor((raw / step) + 0.5) * step
snapped = math.clamp(snapped, minVal, maxVal)
tapDelay = tonumber(string.format("%.1f", snapped)) or snapped
local pct = (tapDelay - minVal) / (maxVal - minVal)
fill.Size = UDim2.fromScale(pct, 1)
sliderLbl.Text = ("Meter Tap Delay: %.1f s"):format(tapDelay)
end

setDelayFromAlpha((tapDelay - minVal) / (maxVal - minVal))

local sliding = false
barBg.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
sliding = true
local alpha = (input.Position.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1)
setDelayFromAlpha(alpha)
end
end)

UserInputService.InputChanged:Connect(function(input)
if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local alpha = (input.Position.X - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1)
setDelayFromAlpha(alpha)
end
end)

UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
sliding = false
end
end)
end

createRiFGui()
