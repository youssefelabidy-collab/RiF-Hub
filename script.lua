local Players = game:GetService("Players")
local player = Players.LocalPlayer

local State = {
AutoLoop = false,
Recording = false,
TargetPosition = nil,
ThrowDuration = 1.5,
RecordStartTime = nil,
}

local function getRoot()
local char = player.Character or player.CharacterAdded:Wait()
return char:FindFirstChild("HumanoidRootPart")
end

local function teleportToTarget()
local root = getRoot()
if not root or not State.TargetPosition then return false end
local ok = pcall(function()
root.CFrame = CFrame.new(State.TargetPosition + Vector3.new(0, 3, 0))
end)
return ok
end

task.spawn(function()
while true do
if State.AutoLoop and not State.Recording and State.TargetPosition then
teleportToTarget()
task.wait(State.ThrowDuration)
task.wait(0.6)
else
task.wait(0.25)
end
end
end)

local function createControlGui()
local guiParent = (type(gethui) == "function" and pcall(gethui)) and gethui() or game:GetService("CoreGui")
local old = guiParent:FindFirstChild("ThrowRecorderGui")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "ThrowRecorderGui"
sg.ResetOnSpawn = false
sg.Parent = guiParent

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 145)
frame.Position = UDim2.fromScale(0.5, 0.2)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 46)
statusLabel.Position = UDim2.fromOffset(8, 8)
statusLabel.BackgroundTransparency = 1
statusLabel.TextWrapped = true
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Text = "اضغط Start لبدء التوجيه والرمي"
statusLabel.Parent = frame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.fromOffset(116, 34)
startBtn.Position = UDim2.fromOffset(8, 62)
startBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 220)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 13
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Text = "Start"
startBtn.Parent = frame

local doneBtn = Instance.new("TextButton")
doneBtn.Size = UDim2.fromOffset(116, 34)
doneBtn.Position = UDim2.fromOffset(136, 62)
doneBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
doneBtn.Font = Enum.Font.GothamBold
doneBtn.TextSize = 13
doneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
doneBtn.Text = "Done"
doneBtn.Parent = frame

local toggleLoopBtn = Instance.new("TextButton")
toggleLoopBtn.Size = UDim2.new(1, -16, 0, 32)
toggleLoopBtn.Position = UDim2.fromOffset(8, 104)
toggleLoopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleLoopBtn.Font = Enum.Font.GothamBold
toggleLoopBtn.TextSize = 12
toggleLoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLoopBtn.Text = "Auto Repeat: OFF"
toggleLoopBtn.Parent = frame

startBtn.MouseButton1Click:Connect(function()
State.AutoLoop = false
toggleLoopBtn.Text = "Auto Repeat: OFF"
State.Recording = true
State.RecordStartTime = os.clock()

local root = getRoot()
if State.TargetPosition and root then
pcall(function()
root.CFrame = CFrame.new(State.TargetPosition + Vector3.new(0, 3, 0))
end)
statusLabel.Text = "تم نقلك لمنطقة الرمي. ارمِ الآن ثم اضغط Done"
else
statusLabel.Text = "اذهب لمنطقة الرمي وارمِ الطعام، ثم اضغط Done"
end
end)

doneBtn.MouseButton1Click:Connect(function()
local root = getRoot()
if root then
State.TargetPosition = root.Position
end
if State.RecordStartTime then
local elapsed = os.clock() - State.RecordStartTime
State.ThrowDuration = math.clamp(elapsed, 0.5, 10)
end
State.Recording = false
State.AutoLoop = true
toggleLoopBtn.Text = "Auto Repeat: ON"
statusLabel.Text = ("تم الحفظ! يكرر كل %.1fs"):format(State.ThrowDuration)
end)

toggleLoopBtn.MouseButton1Click:Connect(function()
State.AutoLoop = not State.AutoLoop
if State.AutoLoop then
State.Recording = false
toggleLoopBtn.Text = "Auto Repeat: ON"
statusLabel.Text = "التكرار التلقائي يعمل الآن"
else
toggleLoopBtn.Text = "Auto Repeat: OFF"
statusLabel.Text = "تم إيقاف التكرار التلقائي"
end
end)
end

createControlGui()
