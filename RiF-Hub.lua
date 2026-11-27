local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("RiFHubGui")
if oldGui then oldGui:Destroy() end

local cfg = {
train = false,
throwFood = false,
collect = false,
events = false,
speed = false,
jump = false,
speedVal = 48,
jumpVal = 72,
biomeIndex = 1
}

local biomes = {
"Forest", "Savanna", "Desert", "Jungle", "Ocean",
"Mountains", "Winter", "Hell", "Mythical", "Shadow", "Nuclear"
}

local cache = {
remotes = {},
collectParts = {},
prompts = {},
clicks = {},
animals = {},
lastScan = 0
}

local function getRig()
local char = player.Character
if not char then return nil, nil, nil end
local hrp = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
return char, hrp, hum
end

local function getPartPos(inst)
if not inst then return nil end
if inst:IsA("BasePart") then return inst.Position end
if inst:IsA("Model") then
if inst.PrimaryPart then return inst.PrimaryPart.Position end
local p = inst:FindFirstChildWhichIsA("BasePart", true)
if p then return p.Position end
end
return nil
end

local function scanWorldCache(force)
if not force and (os.clock() - cache.lastScan < 2.5) then return end
cache.lastScan = os.clock()

table.clear(cache.remotes)
table.clear(cache.collectParts)
table.clear(cache.prompts)
table.clear(cache.clicks)
table.clear(cache.animals)

for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
table.insert(cache.remotes, r)
end
end

local char = player.Character
for _, obj in ipairs(workspace:GetDescendants()) do
if char and obj:IsDescendantOf(char) then continue end

if obj:IsA("ProximityPrompt") and obj.Enabled and obj.Parent then
table.insert(cache.prompts, obj)
elseif obj:IsA("ClickDetector") and obj.Parent and obj.Parent:IsA("BasePart") then
table.insert(cache.clicks, obj)
elseif obj:IsA("TouchTransmitter") and obj.Parent and obj.Parent:IsA("BasePart") then
local part = obj.Parent
local n = part.Name:lower()
local pn = part.Parent and part.Parent.Name:lower() or ""
if n:find("cash") or n:find("coin") or n:find("money") or n:find("collect")
or n:find("drop") or n:find("orb") or n:find("gem") or n:find("reward")
or pn:find("cash") or pn:find("coin") or pn:find("money") or pn:find("collect") or pn:find("drop") then
table.insert(cache.collectParts, part)
end
elseif obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
local pos = getPartPos(obj)
if pos then
table.insert(cache.animals, { model = obj, pos = pos })
end
end
end
end

local function equipTool()
local char = player.Character
if not char then return nil end

local tool = char:FindFirstChildOfClass("Tool")
if tool then return tool end

local bp = player:FindFirstChild("Backpack")
if bp then
for _, item in ipairs(bp:GetChildren()) do
if item:IsA("Tool") then
item.Parent = char
return item
end
end
end
return nil
end

local function fireRemotesMatching(keywords)
for _, rem in ipairs(cache.remotes) do
local rn = rem.Name:lower()
for _, kw in ipairs(keywords) do
if rn:find(kw, 1, true) then
if rem:IsA("RemoteEvent") then
pcall(function() rem:FireServer() end)
elseif rem:IsA("RemoteFunction") then
pcall(function() rem:InvokeServer() end)
end
break
end
end
end
end

local function findNearestAnimal(originPos)
local best = nil
local bestDist = math.huge
for _, entry in ipairs(cache.animals) do
if entry.model and entry.model.Parent then
local pos = getPartPos(entry.model)
if pos then
local d = (originPos - pos).Magnitude
if d < bestDist then
bestDist = d
best = { pos = pos, dist = d }
end
end
end
end
return best
end

local function doRealCollect(char, hrp)
if not char or not hrp then return end

for i = #cache.collectParts, 1, -1 do
local part = cache.collectParts[i]
if not part or not part.Parent or part:IsDescendantOf(char) then
table.remove(cache.collectParts, i)
else
local touched = false
if firetouchinterest then
local ok = pcall(function()
firetouchinterest(hrp, part, 0)
task.wait(0.015)
firetouchinterest(hrp, part, 1)
end)
touched = ok
end

if not touched then
local dist = (hrp.Position - part.Position).Magnitude
if dist < 45 then
pcall(function()
part.CFrame = hrp.CFrame
end)
end
end
end
end

fireRemotesMatching({ "collect", "claim", "cash", "coin", "money", "pick" })
end

local function doRealThrow(char, hrp)
if not char or not hrp then return end

local tool = equipTool()
local nearestAnimal = findNearestAnimal(hrp.Position)
if nearestAnimal and nearestAnimal.dist < 60 then
pcall(function()
hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(nearestAnimal.pos.X, hrp.Position.Y, nearestAnimal.pos.Z))
end)
end

if tool then
pcall(function() tool:Activate() end)
end

if VirtualInputManager then
pcall(function()
VirtualInputManager:SendMouseButtonEvent(400, 400, 0, true, game, 0)
task.wait(0.02)
VirtualInputManager:SendMouseButtonEvent(400, 400, 0, false, game, 0)
end)
end

fireRemotesMatching({ "throw", "feed", "food", "toss", "launch", "shoot" })
end

local function doRealTrain(char, hrp, hum)
if not char or not hrp then return end

local bestPrompt = nil
local bestDist = math.huge

for _, p in ipairs(cache.prompts) do
if p and p.Parent and p.Enabled then
local pn = p.Parent.Name:lower()
local ppn = p.Parent.Parent and p.Parent.Parent.Name:lower() or ""
if pn:find("chin") or pn:find("bar") or pn:find("gym") or pn:find("train") or pn:find("lift")
or ppn:find("chin") or ppn:find("bar") or ppn:find("gym") or ppn:find("train") then
local pos = getPartPos(p.Parent)
if pos then
local d = (hrp.Position - pos).Magnitude
if d < bestDist then
bestDist = d
bestPrompt = { prompt = p, pos = pos, dist = d }
end
end
end
end
end

if bestPrompt then
if bestPrompt.dist > 10 then
pcall(function()
hrp.CFrame = CFrame.new(bestPrompt.pos + Vector3.new(0, 3, 4))
end)
end
pcall(function()
fireproximityprompt(bestPrompt.prompt)
end)
end

for _, cd in ipairs(cache.clicks) do
if cd and cd.Parent and cd.Parent:IsA("BasePart") then
local cn = cd.Parent.Name:lower()
if cn:find("chin") or cn:find("bar") or cn:find("gym") or cn:find("train") or cn:find("lift") then
local d = (hrp.Position - cd.Parent.Position).Magnitude
if d < 20 and fireclickdetector then
pcall(function() fireclickdetector(cd) end)
end
end
end
end

fireRemotesMatching({ "chin", "train", "lift", "strength", "power", "rep" })
end

local function tpBiome(name)
local _, hrp = getRig()
if not hrp then return end
local needle = name:lower()

for _, obj in ipairs(workspace:GetDescendants()) do
if (obj:IsA("BasePart") or obj:IsA("Model")) and obj.Name:lower():find(needle, 1, true) then
local pos = getPartPos(obj)
if pos then
hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
return
end
end
end
end

local function printDebugInfo()
scanWorldCache(true)
print("=== [RiF Hub Real Scan] ===")
print("Remotes found:", #cache.remotes)
for i = 1, math.min(#cache.remotes, 25) do
print(" - Remote:", cache.remotes[i].Name, "[" .. cache.remotes[i].ClassName .. "]")
end
print("Collect parts found:", #cache.collectParts)
for i = 1, math.min(#cache.collectParts, 15) do
print(" - Collect:", cache.collectParts[i]:GetFullName())
end
print("Animals found:", #cache.animals)
end

-- Loops
task.spawn(function()
while true do
if cfg.train or cfg.throwFood or cfg.collect or cfg.events then
scanWorldCache(false)
local char, hrp, hum = getRig()
if char and hrp then
if cfg.collect then
doRealCollect(char, hrp)
end
if cfg.throwFood then
doRealThrow(char, hrp)
end
if cfg.train then
doRealTrain(char, hrp, hum)
end
if cfg.events then
fireRemotesMatching({ "event", "claim", "reward", "gift", "spin", "holiday", "seasonal" })
end
end
end
task.wait(0.25)
end
end)

RunService.Heartbeat:Connect(function()
if not cfg.speed and not cfg.jump then return end
local _, _, hum = getRig()
if not hum then return end
if cfg.speed then hum.WalkSpeed = cfg.speedVal end
if cfg.jump then
hum.UseJumpPower = true
hum.JumpPower = cfg.jumpVal
end
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
local d = input.Position - dragStart
frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end
end)
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "RiFHubGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 330, 0, 235)
win.Position = UDim2.new(0.5, -165, 0.5, -117)
win.BackgroundColor3 = Color3.fromRGB(13, 18, 30)
win.BorderSizePixel = 0
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)

local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(37, 99, 235)
winStroke.Thickness = 1.5
winStroke.Parent = win

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 34)
top.BackgroundColor3 = Color3.fromRGB(20, 28, 46)
top.BorderSizePixel = 0
top.Parent = win
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 10)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 150, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "RiF Hub - Real Farm"
titleLbl.TextColor3 = Color3.fromRGB(240, 246, 255)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = top

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 22)
minBtn.Position = UDim2.new(1, -56, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(35, 48, 74)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 15
minBtn.Parent = top
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(153, 27, 27)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.Parent = top
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

local nav = Instance.new("Frame")
nav.Size = UDim2.new(0, 88, 1, -42)
nav.Position = UDim2.new(0, 6, 0, 38)
nav.BackgroundColor3 = Color3.fromRGB(18, 25, 41)
nav.BorderSizePixel = 0
nav.Parent = win
Instance.new("UICorner", nav).CornerRadius = UDim.new(0, 8)

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 5)
navLayout.Parent = nav

local navPad = Instance.new("UIPadding")
navPad.PaddingTop = UDim.new(0, 6)
navPad.PaddingLeft = UDim.new(0, 5)
navPad.PaddingRight = UDim.new(0, 5)
navPad.Parent = nav

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -104, 1, -42)
body.Position = UDim2.new(0, 98, 0, 38)
body.BackgroundColor3 = Color3.fromRGB(18, 25, 41)
body.BorderSizePixel = 0
body.Parent = win
Instance.new("UICorner", body).CornerRadius = UDim.new(0, 8)

local function makePage()
local sf = Instance.new("ScrollingFrame")
sf.Size = UDim2.new(1, -10, 1, -10)
sf.Position = UDim2.new(0, 5, 0, 5)
sf.BackgroundTransparency = 1
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 3
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
sf.Visible = false
sf.Parent = body

local ll = Instance.new("UIListLayout")
ll.Padding = UDim.new(0, 5)
ll.Parent = sf
return sf
end

local pageMain = makePage()
local pageEvents = makePage()
local pageBiomes = makePage()
local pagePlayer = makePage()

local function addRow(parent, label, badgeText, callback)
local b = Instance.new("TextButton")
b.Size = UDim2.new(1, 0, 0, 30)
b.BackgroundColor3 = Color3.fromRGB(27, 38, 62)
b.BorderSizePixel = 0
b.Text = ""
b.Parent = parent
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

local t = Instance.new("TextLabel")
t.Size = UDim2.new(1, -64, 1, 0)
t.Position = UDim2.new(0, 8, 0, 0)
t.BackgroundTransparency = 1
t.Text = label
t.TextColor3 = Color3.fromRGB(235, 240, 250)
t.Font = Enum.Font.GothamBold
t.TextSize = 11
t.TextXAlignment = Enum.TextXAlignment.Left
t.Parent = b

local s = Instance.new("TextLabel")
s.Size = UDim2.new(0, 52, 0, 20)
s.Position = UDim2.new(1, -56, 0.5, -10)
s.BackgroundColor3 = Color3.fromRGB(39, 53, 84)
s.Text = badgeText
s.TextColor3 = Color3.fromRGB(180, 195, 220)
s.Font = Enum.Font.GothamBold
s.TextSize = 10
s.Parent = b
Instance.new("UICorner", s).CornerRadius = UDim.new(0, 4)

b.MouseButton1Click:Connect(function()
callback(b, s)
end)
return b, s
end

local function paintState(badge, active)
badge.Text = active and "ON" or "OFF"
badge.BackgroundColor3 = active and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(39, 53, 84)
badge.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local _, bTrain = addRow(pageMain, "Auto Chin-Up", "OFF", function(_, s)
cfg.train = not cfg.train
paintState(s, cfg.train)
end)

local _, bThrow = addRow(pageMain, "Auto Throw", "OFF", function(_, s)
cfg.throwFood = not cfg.throwFood
paintState(s, cfg.throwFood)
end)

local _, bCollect = addRow(pageMain, "Auto Collect", "OFF", function(_, s)
cfg.collect = not cfg.collect
paintState(s, cfg.collect)
end)

local _, bFull = addRow(pageMain, "Full Farm", "OFF", function(_, s)
local nextV = not (cfg.train and cfg.throwFood and cfg.collect)
cfg.train = nextV
cfg.throwFood = nextV
cfg.collect = nextV
paintState(bTrain, cfg.train)
paintState(bThrow, cfg.throwFood)
paintState(bCollect, cfg.collect)
paintState(s, nextV)
end)

addRow(pageEvents, "Auto Events", "OFF", function(_, s)
cfg.events = not cfg.events
paintState(s, cfg.events)
end)

addRow(pageEvents, "Scan Game", "F9", function()
printDebugInfo()
end)

addRow(pageBiomes, "Cycle Biome", biomes[cfg.biomeIndex], function(_, s)
tpBiome(biomes[cfg.biomeIndex])
cfg.biomeIndex = (cfg.biomeIndex % #biomes) + 1
s.Text = biomes[cfg.biomeIndex]
end)

for _, bn in ipairs({ "Forest", "Savanna", "Desert", "Jungle", "Ocean", "Hell", "Mythical", "Shadow", "Nuclear" }) do
addRow(pageBiomes, bn, "TP", function()
tpBiome(bn)
end)
end

addRow(pagePlayer, "Speed (" .. cfg.speedVal .. ")", "OFF", function(_, s)
cfg.speed = not cfg.speed
paintState(s, cfg.speed)
if not cfg.speed then
local _, _, hum = getRig()
if hum then hum.WalkSpeed = 16 end
end
end)

addRow(pagePlayer, "Jump (" .. cfg.jumpVal .. ")", "OFF", function(_, s)
cfg.jump = not cfg.jump
paintState(s, cfg.jump)
if not cfg.jump then
local _, _, hum = getRig()
if hum then hum.JumpPower = 50 end
end
end)

local tabMap = {}
local function makeTab(txt, pg)
local tb = Instance.new("TextButton")
tb.Size = UDim2.new(1, 0, 0, 28)
tb.BackgroundColor3 = Color3.fromRGB(27, 38, 62)
tb.Text = txt
tb.TextColor3 = Color3.fromRGB(220, 230, 245)
tb.Font = Enum.Font.GothamBold
tb.TextSize = 11
tb.Parent = nav
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)
tabMap[txt] = { btn = tb, page = pg }

tb.MouseButton1Click:Connect(function()
for k, item in pairs(tabMap) do
local active = (k == txt)
item.page.Visible = active
item.btn.BackgroundColor3 = active and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(27, 38, 62)
end
end)
end

makeTab("Main", pageMain)
makeTab("Events", pageEvents)
makeTab("Biomes", pageBiomes)
makeTab("Player", pagePlayer)
pageMain.Visible = true
tabMap["Main"].btn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)

local bubble = Instance.new("TextButton")
bubble.Size = UDim2.new(0, 52, 0, 52)
bubble.Position = win.Position
bubble.BackgroundColor3 = Color3.fromRGB(13, 18, 30)
bubble.Text = "RiF"
bubble.TextColor3 = Color3.fromRGB(96, 165, 250)
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 13
bubble.Visible = false
bubble.Parent = gui
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)

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
cfg.train = false
cfg.throwFood = false
cfg.collect = false
cfg.events = false
cfg.speed = false
cfg.jump = false
gui:Destroy()
end)

makeDraggable(win, top)
makeDraggable(bubble, bubble)
