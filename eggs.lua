local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

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

local function moveSafely(root, targetCFrame, cfg)
    local spread = (cfg and cfg.PositionJitter) or 0.5
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = targetCFrame + Vector3.new(0, 2.6, 0) + randOffset(spread)
end

function Mod.FarmTarget(cfg)
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local container = workspace:FindFirstChild(cfg.EggsFolderName)
    if not root or not container then return end

    for _, item in ipairs(container:GetChildren()) do
        if not cfg.AutoFarmEgg then break end
        if item.Name == cfg.TargetEggName then
            local part = resolvePart(item)
            if part then
                moveSafely(root, part.CFrame, cfg)
                local jitter = rng:NextNumber(0, cfg.TimingJitter or 0.05)
                task.wait((cfg.EggTeleportDelay or 0.14) + jitter)
            end
        end
    end
end

function Mod.FarmBest(cfg)
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local container = workspace:FindFirstChild(cfg.EggsFolderName)
    if not root or not container then return end

    local bestPart, bestVal = nil, -math.huge
    for _, item in ipairs(container:GetChildren()) do
        local part = resolvePart(item)
        if part then
            local val = scoreEgg(item, cfg)
            if val > bestVal then
                bestVal = val
                bestPart = part
            end
        end
    end

    if bestPart then
        moveSafely(root, bestPart.CFrame, cfg)
    end
end

return Mod
