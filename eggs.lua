local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Mod = {}
local rng = Random.new()

local function randOffset(spread)
return Vector3.new(
rng:NextNumber(-spread, spread),
0,
rng:NextNumber(-spread, spread)
)
end

local function resolvePart(target)
if not target or not target.Parent then return nil end
if target:IsA("BasePart") then return target end
if target:IsA("Model") then
return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
end
return target:FindFirstChildWhichIsA("BasePart", true)
end

local function sanitizeMonster(monster)
if not monster or not monster.Parent then return end
for _, d in ipairs(monster:GetDescendants()) do
if d:IsA("BasePart") then
pcall(function()
d.CanCollide = false
d.CanTouch = false
d.AssemblyLinearVelocity = Vector3.zero
d.AssemblyAngularVelocity = Vector3.zero
end)
elseif d:IsA("TouchTransmitter") then
pcall(function() d:Destroy() end)
end
end
end

local function isNearAnyMonster(pos, cfg)
local folderName = (cfg and cfg.MonsterFolderName) or "Monsters"
local safeRadius = (cfg and cfg.MonsterSafeRadius) or 28
local folder = workspace:FindFirstChild(folderName)

local function checkContainer(container)
if not container then return false end
for _, m in ipairs(container:GetChildren()) do
if cfg and cfg.NoMonsterDamage then
sanitizeMonster(m)
end
local part = resolvePart(m)
if part and (part.Position - pos).Magnitude <= safeRadius then
return true
end
end
return false
end

if checkContainer(folder) then
return true
end

for _, obj in ipairs(workspace:GetDescendants()) do
if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LocalPlayer.Character then
local low = string.lower(obj.Name)
if string.find(low, "monster") or string.find(low, "enemy") or string.find(low, "boss") or string.find(low, "guard") then
if cfg and cfg.NoMonsterDamage then
sanitizeMonster(obj)
end
local part = resolvePart(obj)
if part and (part.Position - pos).Magnitude <= safeRadius then
return true
end
end
end
end

return false
end

local function moveSafely(root, targetCFrame, cfg)
if not root or not root.Parent then return end
local spread = (cfg and cfg.PositionJitter) or 0.35
local lift = (cfg and cfg.MonsterLiftHeight) or 14
local desiredPos = targetCFrame.Position + Vector3.new(0, 2.8, 0) + randOffset(spread)

if cfg and cfg.NoMonsterDamage and isNearAnyMonster(desiredPos, cfg) then
desiredPos = desiredPos + Vector3.new(0, lift, 0)
end

for _ = 1, 3 do
if not root or not root.Parent then break end
pcall(function()
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero
root.CFrame = CFrame.new(desiredPos, desiredPos + targetCFrame.LookVector)
end)
RunService.Heartbeat:Wait()
end
end

local function matchesTargetName(itemName, targetName)
if not targetName or targetName == "" or string.lower(targetName) == "all" then
return true
end
if itemName == targetName then
return true
end
return string.find(string.lower(itemName), string.lower(targetName), 1, true) ~= nil
end

local function fireEggRemotes(item, part)
local eggName = (item and item.Name) or (part and part.Name) or ""
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
local low = string.lower(obj.Name)
if string.find(low, "egg") or string.find(low, "steal") or string.find(low, "hatch")
or string.find(low, "open") or string.find(low, "buy") or string.find(low, "claim")
or string.find(low, "collect") or string.find(low, "home") or string.find(low, "base") then
if obj:IsA("RemoteEvent") then
pcall(function() obj:FireServer(eggName) end)
pcall(function() obj:FireServer(item) end)
pcall(function() obj:FireServer(eggName, part) end)
elseif obj:IsA("RemoteFunction") then
pcall(function() obj:InvokeServer(eggName) end)
pcall(function() obj:InvokeServer(item) end)
end
end
end
end
end

local function triggerInteractions(container, root, part)
if not container then return end

if typeof(fireproximityprompt) == "function" then
for _, d in ipairs(container:GetDescendants()) do
if d:IsA("ProximityPrompt") and d.Enabled then
pcall(function()
d.MaxActivationDistance = math.max(d.MaxActivationDistance, 30)
fireproximityprompt(d)
end)
end
end
end

if typeof(fireclickdetector) == "function" then
for _, d in ipairs(container:GetDescendants()) do
if d:IsA("ClickDetector") then
pcall(function() fireclickdetector(d) end)
end
end
end

if root and part and part:IsA("BasePart") and typeof(firetouchinterest) == "function" then
pcall(function()
firetouchinterest(root, part, 0)
task.wait(0.03)
firetouchinterest(root, part, 1)
end)
end
end

local function interactWithEgg(item, part, root)
if not part or not part.Parent then return end
triggerInteractions(item, root, part)
if part.Parent and part.Parent ~= item then
triggerInteractions(part.Parent, root, part)
end
fireEggRemotes(item, part)
end

local function findHomeCFrame(root)
local playerName = string.lower(LocalPlayer.Name)
local displayName = string.lower(LocalPlayer.DisplayName)

local keywords = { "home", "base", "plot", "slot", "stand", "tycoon", "camp" }
for _, obj in ipairs(workspace:GetDescendants()) do
local low = string.lower(obj.Name)
local ownerMatch = string.find(low, playerName, 1, true) ~= nil or string.find(low, displayName, 1, true) ~= nil
local isHomeWord = false
for _, kw in ipairs(keywords) do
if string.find(low, kw, 1, true) then
isHomeWord = true
break
end
end

if (ownerMatch and isHomeWord) or (ownerMatch and (obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart"))) then
local p = resolvePart(obj)
if p then
return p.CFrame, obj
end
end
end

if root then
return root.CFrame, nil
end
return nil, nil
end

local function returnHome(root, cfg)
local homeCF, homeObj = findHomeCFrame(root)
if not homeCF then return end

moveSafely(root, homeCF, cfg)
if homeObj then
local homePart = resolvePart(homeObj)
triggerInteractions(homeObj, root, homePart)
end
end

local function scoreEgg(egg, cfg)
local total = 0
for _, attr in ipairs((cfg and cfg.EggAttributePriority) or {}) do
local v = egg:GetAttribute(attr)
if type(v) == "number" and v > total then
total = v
end
end
for _, obj in ipairs(egg:GetDescendants()) do
if obj:IsA("NumberValue") or obj:IsA("IntValue") then
local lowerName = string.lower(obj.Name)
if string.find(lowerName, "power") or string.find(lowerName, "value") or string.find(lowerName, "mult") then
if obj.Value > total then
total = obj.Value
end
end
end
end
return total
end

local function collectEggs(cfg)
local results = {}
local folderName = (cfg and cfg.EggsFolderName) or "Eggs"
local container = workspace:FindFirstChild(folderName)

if container then
for _, item in ipairs(container:GetChildren()) do
table.insert(results, item)
end
end

if #results == 0 then
for _, obj in ipairs(workspace:GetDescendants()) do
if (obj:IsA("Model") or obj:IsA("BasePart")) and string.find(string.lower(obj.Name), "egg") then
table.insert(results, obj)
end
end
end

return results
end

function Mod.FarmTarget(cfg)
local char = LocalPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
if not root then return end

local eggs = collectEggs(cfg)
for _, item in ipairs(eggs) do
if not cfg.AutoFarmEgg then break end
if matchesTargetName(item.Name, cfg.TargetEggName) then
local part = resolvePart(item)
if part then
moveSafely(root, part.CFrame, cfg)
interactWithEgg(item, part, root)
task.wait(0.15)
returnHome(root, cfg)

local jitter = rng:NextNumber(0, (cfg and cfg.TimingJitter) or 0.05)
task.wait(((cfg and cfg.EggTeleportDelay) or 0.14) + jitter)
end
end
end
end

function Mod.FarmBest(cfg)
local char = LocalPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
if not root then return end

local eggs = collectEggs(cfg)
local bestItem, bestPart, bestVal = nil, nil, -math.huge
for _, item in ipairs(eggs) do
local part = resolvePart(item)
if part then
local val = scoreEgg(item, cfg)
if val > bestVal then
bestVal = val
bestPart = part
bestItem = item
end
end
end

if bestPart and bestItem then
moveSafely(root, bestPart.CFrame, cfg)
interactWithEgg(bestItem, bestPart, root)
task.wait(0.15)
returnHome(root, cfg)
end
end

return Mod
