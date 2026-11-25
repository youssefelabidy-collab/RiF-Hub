local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local Mod = {}
local rng = Random.new()
local cachedPad = nil

local function getPad(name)
    if cachedPad and cachedPad.Parent then
        return cachedPad
    end
    local found = workspace:FindFirstChild(name, true)
    if found and found:IsA("BasePart") then
        cachedPad = found
        return found
    end
    return nil
end

function Mod.ProtectFromMonsters(cfg)
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local folder = workspace:FindFirstChild(cfg.MonsterFolderName)
    if not root or not folder then return end

    for _, entity in ipairs(folder:GetChildren()) do
        local body = entity:IsA("BasePart") and entity
            or (entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChildWhichIsA("BasePart", true))

        if body and body.Parent then
            local distance = (body.Position - root.Position).Magnitude
            if distance <= (cfg.MonsterSafeRadius or 20) then
                local lift = (cfg.MonsterLiftHeight or 10) + rng:NextNumber(-1.5, 2.5)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = root.CFrame + Vector3.new(0, lift, 0)
            end
        end
    end
end

function Mod.FarmTreadmill(cfg)
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local pad = getPad(cfg.TreadmillPartName)
    if pad then
        local jitterX = rng:NextNumber(-0.5, 0.5)
        local jitterZ = rng:NextNumber(-0.5, 0.5)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = pad.CFrame + Vector3.new(jitterX, 2.1, jitterZ)
    end
end

return Mod
