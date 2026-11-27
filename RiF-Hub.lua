local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("RiFHubGui")
if oldGui then
	oldGui:Destroy()
end

local autoTrain = false
local autoThrow = false
local autoCollect = false
local autoEvents = false
local speedBoost = false
local jumpBoost = false
local customSpeed = 52
local customJump = 75
local minimized = false
local activeTab = "Main"

local biomes = {
	"Forest", "Savanna", "Desert", "Jungle", "Ocean", "Mountains",
	"Taiga", "Winter", "Prehistoric", "Deep Waters", "Hell",
	"Ancient Ruins", "Mythical", "Shadow", "Harvest", "Phantom", "Nuclear"
}
local currentBiomeIndex = 1

local function getCharParts()
	local char = player.Character
	if not char then return nil, nil, nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	return char, root, hum
end

local function equipFoodTool()
	local char = player.Character
	if not char then return nil end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then return tool end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				item.Parent = char
				return item
			end
		end
	end
	return nil
end

local function findTrainingTarget(rootPos)
	local bestTarget = nil
	local bestDist = math.huge

	for _, desc in ipairs(workspace:GetDescendants()) do
		local n = desc.Name:lower()
		local parentName = desc.Parent and desc.Parent.Name:lower() or ""
		local isTrain = n:find("chin") or n:find("bar") or n:find("gym") or n:find("train") or n:find("lift")
			or parentName:find("chin") or parentName:find("bar") or parentName:find("gym") or parentName:find("train")

		if isTrain then
			if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
				local p = desc.Parent:IsA("BasePart") and desc.Parent.Position
					or (desc.Parent:IsA("Model") and desc.Parent.PrimaryPart and desc.Parent.PrimaryPart.Position)
				if p then
					local d = (rootPos - p).Magnitude
					if d < bestDist then
						bestDist = d
						bestTarget = { kind = "prompt", prompt = desc, pos = p, dist = d }
					end
				end
			elseif desc:IsA("ClickDetector") and desc.Parent and desc.Parent:IsA("BasePart") then
				local p = desc.Parent.Position
				local d = (rootPos - p).Magnitude
				if d < bestDist then
					bestDist = d
					bestTarget = { kind = "click", click = desc, part = desc.Parent, pos = p, dist = d }
				end
			end
		end
	end

	return bestTarget
end

local function teleportToBiome(biomeName)
	local char, root = getCharParts()
	if not char or not root then return false end

	local targetLower = biomeName:lower()
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("BasePart") or desc:IsA("Model") then
			local n = desc.Name:lower()
			if n:find(targetLower, 1, true) then
				local cf = desc:IsA("BasePart")
					and (desc.CFrame + Vector3.new(0, (desc.Size.Y / 2) + 4, 0))
					or (desc:GetPivot() + Vector3.new(0, 4, 0))
				root.CFrame = cf
				return true
			end
		end
	end
	return false
end

local function triggerEventActions(root, hum)
	for _, desc in ipairs(workspace:GetDescendants()) do
		local n = desc.Name:lower()
		local parentName = desc.Parent and desc.Parent.Name:lower() or ""
		local isEventObj = n:find("event") or n:find("holiday") or n:find("seasonal") or n:find("special")
			or n:find("boss") or n:find("spin") or n:find("gift") or n:find("crate") or n:find("chest")
			or parentName:find("event") or parentName:find("holiday") or parentName:find("seasonal") or parentName:find("special")

		if isEventObj then
			if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
				local pos = desc.Parent:IsA("BasePart") and desc.Parent.Position
					or (desc.Parent:IsA("Model") and desc.Parent.PrimaryPart and desc.Parent.PrimaryPart.Position)
				if pos then
					if (root.Position - pos).Magnitude > 10 and hum then
						hum:MoveTo(pos)
					else
						pcall(function() fireproximityprompt(desc) end)
					end
				end
			elseif desc:IsA("ClickDetector") and desc.Parent and desc.Parent:IsA("BasePart") then
				local pos = desc.Parent.Position
				if (root.Position - pos).Magnitude > 12 and hum then
					hum:MoveTo(pos)
				elseif fireclickdetector then
					pcall(function() fireclickdetector(desc) end)
				end
			elseif desc:IsA("BasePart") and desc:FindFirstChildOfClass("TouchTransmitter") then
				pcall(function()
					if firetouchinterest then
						firetouchinterest(root, desc, 0)
						task.wait(0.02)
						firetouchinterest(root, desc, 1)
					end
				end)
			end
		end
	end

	for _, container in ipairs({ ReplicatedStorage, workspace }) do
		for _, rem in ipairs(container:GetDescendants()) do
			if rem:IsA("RemoteEvent") then
				local rn = rem.Name:lower()
				if rn:find("event") or rn:find("claim") or rn:find("reward") or rn:find("spin") or rn:find("gift") or rn:find("holiday") then
					pcall(function() rem:FireServer() end)
				end
			end
		end
	end
end

local function teleportToNearestEvent()
	local char, root = getCharParts()
	if not char or not root then return false end

	for _, desc in ipairs(workspace:GetDescendants()) do
		local n = desc.Name:lower()
		if (n:find("event") or n:find("holiday") or n:find("seasonal") or n:find("special"))
			and (desc:IsA("BasePart") or desc:IsA("Model")) then
			local cf = desc:IsA("BasePart") and (desc.CFrame + Vector3.new(0, 5, 0)) or (desc:GetPivot() + Vector3.new(0, 5, 0))
			root.CFrame = cf
			return true
		end
	end
	return false
end

local function scanGameObjects()
	local foundEvents = {}
	local foundRemotes = {}

	for _, obj in ipairs(workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if n:find("event") or n:find("holiday") or n:find("seasonal") or n:find("special") or n:find("chin") or n:find("bar") then
			table.insert(foundEvents, obj.Name .. " [" .. obj.ClassName .. "]")
		end
	end

	for _, container in ipairs({ ReplicatedStorage, workspace }) do
		for _, rem in ipairs(container:GetDescendants()) do
			if rem:IsA("RemoteEvent") then
				table.insert(foundRemotes, rem.Name)
			end
		end
	end

	print("=== [RiF Hub Scanner] Targets ===")
	for i = 1, math.min(#foundEvents, 20) do
		print(" - " .. foundEvents[i])
	end

	print("=== [RiF Hub Scanner] Remotes ===")
	for i = 1, math.min(#foundRemotes, 20) do
		print(" - " .. foundRemotes[i])
	end
end

task.spawn(function()
	while true do
		if autoTrain then
			local char, root, hum = getCharParts()
			if char and root and hum then
				local target = findTrainingTarget(root.Position)
				if target then
					if target.dist > 9 then
						hum:MoveTo(target.pos)
					else
						root.CFrame = CFrame.lookAt(root.Position, Vector3.new(target.pos.X, root.Position.Y, target.pos.Z))
						if target.kind == "prompt" then
							pcall(function() fireproximityprompt(target.prompt) end)
						elseif target.kind == "click" and fireclickdetector then
							pcall(function() fireclickdetector(target.click) end)
						end
					end
				end

				for _, container in ipairs({ ReplicatedStorage, workspace }) do
					for _, rem in ipairs(container:GetDescendants()) do
						if rem:IsA("RemoteEvent") then
							local rn = rem.Name:lower()
							if rn:find("chin") or rn:find("train") or rn:find("lift") or rn:find("strength") or rn:find("power") then
								pcall(function() rem:FireServer() end)
							end
						end
					end
				end
			end
		end
		task.wait(0.22)
	end
end)

task.spawn(function()
	while true do
		if autoThrow then
			local char, root = getCharParts()
			if char and root then
				local tool = equipFoodTool()
				if tool then
					pcall(function() tool:Activate() end)
				end
				for _, container in ipairs({ ReplicatedStorage, workspace }) do
					for _, rem in ipairs(container:GetDescendants()) do
						if rem:IsA("RemoteEvent") then
							local rn = rem.Name:lower()
							if rn:find("throw") or rn:find("feed") or rn:find("food") then
								pcall(function() rem:FireServer() end)
							end
						end
					end
				end
			end
		end
		task.wait(0.14)
	end
end)

task.spawn(function()
	while true do
		if autoCollect then
			local char, root = getCharParts()
			if char and root then
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("TouchTransmitter") and obj.Parent and obj.Parent:IsA("BasePart") then
						local part = obj.Parent
						if not part:IsDescendantOf(char) then
							local n = part.Name:lower()
							if n:find("coin") or n:find("cash") or n:find("money") or n:find("gem") or n:find("drop") or n:find("reward") or n:find("orb") or part.Size.Magnitude < 12 then
								pcall(function()
									if firetouchinterest then
										firetouchinterest(root, part, 0)
										task.wait(0.02)
										firetouchinterest(root, part, 1)
									else
										part.CFrame = root.CFrame
									end
								end)
							end
						end
					end
				end
			end
		end
		task.wait(0.3)
	end
end)

task.spawn(function()
	while true do
		if autoEvents then
			local char, root, hum = getCharParts()
			if char and root then
				triggerEventActions(root, hum)
			end
		end
		task.wait(0.45)
	end
end)

RunService.Heartbeat:Connect(function()
	local _, _, hum = getCharParts()
	if hum then
		if speedBoost then
			hum.WalkSpeed = customSpeed
		end
		if jumpBoost then
			hum.UseJumpPower = true
			hum.JumpPower = customJump
		end
	end
end)

local function makeSmoothDraggable(frame, handle)
	local dragging = false
	local dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
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

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RiFHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local hubFrame = Instance.new("Frame")
hubFrame.Name = "HubWindow"
hubFrame.Size = UDim2.new(0, 340, 0, 245)
hubFrame.Position = UDim2.new(0.5, -170, 0.5, -122)
hubFrame.BackgroundColor3 = Color3.fromRGB(11, 15, 25)
hubFrame.BorderSizePixel = 0
hubFrame.Parent = screenGui

local hubCorner = Instance.new("UICorner")
hubCorner.CornerRadius = UDim.new(0, 12)
hubCorner.Parent = hubFrame

local hubStroke = Instance.new("UIStroke")
hubStroke.Color = Color3.fromRGB(37, 99, 235)
hubStroke.Thickness = 1.8
hubStroke.Parent = hubFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(16, 22, 36)
topBar.BorderSizePixel = 0
topBar.Parent = hubFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBar

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 10)
topFix.Position = UDim2.new(0, 0, 1, -10)
topFix.BackgroundColor3 = Color3.fromRGB(16, 22, 36)
topFix.BorderSizePixel = 0
topFix.Parent = topBar

local accentDot = Instance.new("Frame")
accentDot.Size = UDim2.new(0, 8, 0, 8)
accentDot.Position = UDim2.new(0, 12, 0.5, -4)
accentDot.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
accentDot.BorderSizePixel = 0
accentDot.Parent = topBar

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = accentDot

local hubTitle = Instance.new("TextLabel")
hubTitle.Size = UDim2.new(0, 130, 1, 0)
hubTitle.Position = UDim2.new(0, 26, 0, 0)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = "RiF Hub"
hubTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
hubTitle.Font = Enum.Font.GothamBold
hubTitle.TextSize = 15
hubTitle.TextXAlignment = Enum.TextXAlignment.Left
hubTitle.Parent = topBar

local hubBadge = Instance.new("TextLabel")
hubBadge.Size = UDim2.new(0, 56, 0, 20)
hubBadge.Position = UDim2.new(0, 92, 0.5, -10)
hubBadge.BackgroundColor3 = Color3.fromRGB(29, 78, 216)
hubBadge.Text = "PRO"
hubBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
hubBadge.Font = Enum.Font.GothamBold
hubBadge.TextSize = 10
hubBadge.Parent = topBar

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 5)
badgeCorner.Parent = hubBadge

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 24)
minBtn.Position = UDim2.new(1, -64, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 24)
closeBtn.Position = UDim2.new(1, -34, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(254, 226, 226)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 96, 1, -44)
sidebar.Position = UDim2.new(0, 8, 0, 40)
sidebar.BackgroundColor3 = Color3.fromRGB(15, 21, 36)
sidebar.BorderSizePixel = 0
sidebar.Parent = hubFrame

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 9)
sideCorner.Parent = sidebar

local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 5)
sideList.Parent = sidebar

local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 6)
sidePad.PaddingBottom = UDim.new(0, 6)
sidePad.PaddingLeft = UDim.new(0, 6)
sidePad.PaddingRight = UDim.new(0, 6)
sidePad.Parent = sidebar

local contentHolder = Instance.new("Frame")
contentHolder.Name = "Content"
contentHolder.Size = UDim2.new(1, -116, 1, -44)
contentHolder.Position = UDim2.new(0, 110, 0, 40)
contentHolder.BackgroundColor3 = Color3.fromRGB(15, 21, 36)
contentHolder.BorderSizePixel = 0
contentHolder.Parent = hubFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 9)
contentCorner.Parent = contentHolder

local sectionTitle = Instance.new("TextLabel")
sectionTitle.Size = UDim2.new(1, -16, 0, 24)
sectionTitle.Position = UDim2.new(0, 10, 0, 4)
sectionTitle.BackgroundTransparency = 1
sectionTitle.Text = "MAIN FARM"
sectionTitle.TextColor3 = Color3.fromRGB(96, 165, 250)
sectionTitle.Font = Enum.Font.GothamBold
sectionTitle.TextSize = 12
sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
sectionTitle.Parent = contentHolder

local function createTabPage(name)
	local sf = Instance.new("ScrollingFrame")
	sf.Name = name .. "Page"
	sf.Size = UDim2.new(1, -12, 1, -32)
	sf.Position = UDim2.new(0, 6, 0, 28)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 3
	sf.ScrollBarImageColor3 = Color3.fromRGB(59, 130, 246)
	sf.CanvasSize = UDim2.new(0, 0, 0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.Visible = false
	sf.Parent = contentHolder

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = sf

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 2)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = sf

	return sf
end

local pageMain = createTabPage("Main")
local pageEvents = createTabPage("Events")
local pageBiomes = createTabPage("Biomes")
local pagePlayer = createTabPage("Player")

local function createHubButton(parent, titleText, badgeText, onClick)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = Color3.fromRGB(22, 31, 52)
	row.BorderSizePixel = 0
	row.AutoButtonColor = true
	row.Text = ""
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 7)
	rCorner.Parent = row

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(30, 44, 74)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -68, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleText
	lbl.TextColor3 = Color3.fromRGB(226, 232, 240)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local pill = Instance.new("TextLabel")
	pill.Size = UDim2.new(0, 52, 0, 20)
	pill.Position = UDim2.new(1, -58, 0.5, -10)
	pill.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	pill.Text = badgeText
	pill.TextColor3 = Color3.fromRGB(148, 163, 184)
	pill.Font = Enum.Font.GothamBold
	pill.TextSize = 10
	pill.Parent = row

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 5)
	pCorner.Parent = pill

	row.MouseButton1Click:Connect(function()
		onClick(row, pill, rStroke)
	end)

	return row, pill, rStroke
end

local function setToggleStyle(row, pill, stroke, state)
	if state then
		pill.Text = "ON"
		pill.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
		pill.TextColor3 = Color3.fromRGB(255, 255, 255)
		stroke.Color = Color3.fromRGB(59, 130, 246)
	else
		pill.Text = "OFF"
		pill.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		pill.TextColor3 = Color3.fromRGB(148, 163, 184)
		stroke.Color = Color3.fromRGB(30, 44, 74)
	end
end

local _, trainPill, trainStroke = createHubButton(pageMain, "Auto Chin-Up", "OFF", function(row, pill, stroke)
	autoTrain = not autoTrain
	setToggleStyle(row, pill, stroke, autoTrain)
end)

local _, throwPill, throwStroke = createHubButton(pageMain, "Auto Throw", "OFF", function(row, pill, stroke)
	autoThrow = not autoThrow
	setToggleStyle(row, pill, stroke, autoThrow)
end)

local _, collectPill, collectStroke = createHubButton(pageMain, "Auto Collect", "OFF", function(row, pill, stroke)
	autoCollect = not autoCollect
	setToggleStyle(row, pill, stroke, autoCollect)
end)

local _, fullPill, fullStroke = createHubButton(pageMain, "Full Auto Farm", "OFF", function(row, pill, stroke)
	local nextState = not (autoTrain and autoThrow and autoCollect and autoEvents)
	autoTrain = nextState
	autoThrow = nextState
	autoCollect = nextState
	autoEvents = nextState

	setToggleStyle(row, trainPill, trainStroke, autoTrain)
	setToggleStyle(row, throwPill, throwStroke, autoThrow)
	setToggleStyle(row, collectPill, collectStroke, autoCollect)
	setToggleStyle(row, fullPill, fullStroke, nextState)
end)

local _, evPill, evStroke = createHubButton(pageEvents, "Auto Events", "OFF", function(row, pill, stroke)
	autoEvents = not autoEvents
	setToggleStyle(row, pill, stroke, autoEvents)
end)

createHubButton(pageEvents, "TP Event Area", "GO", function()
	teleportToNearestEvent()
end)

createHubButton(pageEvents, "Claim Rewards", "RUN", function()
	local char, root, hum = getCharParts()
	if char and root then
		triggerEventActions(root, hum)
	end
end)

createHubButton(pageEvents, "Scan Remotes", "F9", function()
	scanGameObjects()
end)

createHubButton(pageBiomes, "Cycle Biome", biomes[currentBiomeIndex], function(_, pill)
	local name = biomes[currentBiomeIndex]
	teleportToBiome(name)
	currentBiomeIndex += 1
	if currentBiomeIndex > #biomes then
		currentBiomeIndex = 1
	end
	pill.Text = biomes[currentBiomeIndex]
	pill.BackgroundColor3 = Color3.fromRGB(29, 78, 216)
	pill.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

for _, bName in ipairs({ "Forest", "Savanna", "Desert", "Jungle", "Ocean", "Hell", "Mythical", "Shadow", "Nuclear" }) do
	createHubButton(pageBiomes, bName, "TP", function()
		teleportToBiome(bName)
	end)
end

createHubButton(pagePlayer, "Speed (" .. customSpeed .. ")", "OFF", function(row, pill, stroke)
	speedBoost = not speedBoost
	setToggleStyle(row, pill, stroke, speedBoost)
	if not speedBoost then
		local _, _, hum = getCharParts()
		if hum then hum.WalkSpeed = 16 end
	end
end)

createHubButton(pagePlayer, "Jump (" .. customJump .. ")", "OFF", function(row, pill, stroke)
	jumpBoost = not jumpBoost
	setToggleStyle(row, pill, stroke, jumpBoost)
	if not jumpBoost then
		local _, _, hum = getCharParts()
		if hum then hum.JumpPower = 50 end
	end
end)

local tabButtons = {}
local function createSideTab(label, tabKey, pageObj, headerText)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(22, 31, 52)
	btn.Text = label
	btn.TextColor3 = Color3.fromRGB(203, 213, 225)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = sidebar

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn

	tabButtons[tabKey] = { button = btn, page = pageObj, title = headerText }

	btn.MouseButton1Click:Connect(function()
		activeTab = tabKey
		for k, info in pairs(tabButtons) do
			local isActive = (k == activeTab)
			info.page.Visible = isActive
			info.button.BackgroundColor3 = isActive and Color3.fromRGB(37, 99, 235) or Color3.fromRGB(22, 31, 52)
			info.button.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(203, 213, 225)
		end
		sectionTitle.Text = headerText
	end)
end

createSideTab("Main", "Main", pageMain, "MAIN FARM")
createSideTab("Events", "Events", pageEvents, "EVENTS & REWARDS")
createSideTab("Biomes", "Biomes", pageBiomes, "BIOME TELEPORT")
createSideTab("Player", "Player", pagePlayer, "PLAYER BOOSTS")

pageMain.Visible = true
tabButtons["Main"].button.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
tabButtons["Main"].button.TextColor3 = Color3.fromRGB(255, 255, 255)

local floatBtn = Instance.new("TextButton")
floatBtn.Name = "RiFFloatBtn"
floatBtn.Size = UDim2.new(0, 58, 0, 58)
floatBtn.Position = hubFrame.Position
floatBtn.BackgroundColor3 = Color3.fromRGB(11, 15, 25)
floatBtn.Text = "RiF\nHub"
floatBtn.TextColor3 = Color3.fromRGB(96, 165, 250)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 12
floatBtn.Visible = false
floatBtn.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatBtn

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(59, 130, 246)
floatStroke.Thickness = 2
floatStroke.Parent = floatBtn

minBtn.MouseButton1Click:Connect(function()
	minimized = true
	floatBtn.Position = hubFrame.Position
	hubFrame.Visible = false
	floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
	if minimized then
		minimized = false
		hubFrame.Position = floatBtn.Position
		floatBtn.Visible = false
		hubFrame.Visible = true
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	autoTrain = false
	autoThrow = false
	autoCollect = false
	autoEvents = false
	speedBoost = false
	jumpBoost = false
	screenGui:Destroy()
end)

makeSmoothDraggable(hubFrame, topBar)
makeSmoothDraggable(floatBtn, floatBtn)

