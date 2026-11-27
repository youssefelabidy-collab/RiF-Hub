--========================================
--              RiF HUB
--          STEAL AN EGG
--             VERSION 4.0
--========================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- COLORS

local Blue = Color3.fromRGB(0,140,255)
local Dark = Color3.fromRGB(10,12,20)
local Light = Color3.fromRGB(20,28,42)
local Green = Color3.fromRGB(0,220,130)
local Red = Color3.fromRGB(220,55,65)

-- SETTINGS

local Settings = {
    AutoRefresh = true,
    EggScanner = false,
    MonsterScanner = false,
    SelectedRarity = "Divine"
}

local Rarities = {
    "Common",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Cosmic",
    "Secret",
    "Eternal",
    "Divine"
}

local EggData = {}
local MonsterData = {}

-- GUI

local GUI = Instance.new("ScreenGui")
GUI.Name = "RiFHub"
GUI.ResetOnSpawn = false

local success = pcall(function()
    GUI.Parent = gethui()
end)

if not success then
    GUI.Parent = game:GetService("CoreGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(330,470)
Main.Position = UDim2.new(0.5,-165,0.5,-235)
Main.BackgroundColor3 = Dark
Main.BorderSizePixel = 0
Main.Parent = GUI

Instance.new("UICorner",Main).CornerRadius =
    UDim.new(0,14)

local Stroke = Instance.new("UIStroke",Main)
Stroke.Color = Blue
Stroke.Thickness = 2

-- HEADER

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,75)
Header.BackgroundColor3 = Color3.fromRGB(15,25,42)
Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new("UICorner",Header).CornerRadius =
    UDim.new(0,14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,42)
Title.BackgroundTransparency = 1
Title.Text = "RiF HUB"
Title.TextColor3 = Blue
Title.TextSize = 27
Title.Font = Enum.Font.GothamBold
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Position = UDim2.new(0,0,0,40)
Subtitle.Size = UDim2.new(1,0,0,22)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "STEAL AN EGG | V4.0"
Subtitle.TextColor3 = Color3.fromRGB(170,190,215)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = Header

-- CLOSE

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(28,28)
Close.Position = UDim2.new(1,-35,0,8)
Close.BackgroundColor3 = Red
Close.Text = "X"
Close.TextColor3 = Color3.new(1,1,1)
Close.Font = Enum.Font.GothamBold
Close.Parent = Header

Close.MouseButton1Click:Connect(function()
    GUI:Destroy()
end)

-- STATUS

local Status = Instance.new("TextLabel")
Status.Position = UDim2.new(0,12,0,84)
Status.Size = UDim2.new(1,-24,0,28)
Status.BackgroundColor3 = Light
Status.Text = "● RiF Hub Ready"
Status.TextColor3 = Green
Status.Font = Enum.Font.GothamBold
Status.TextSize = 12
Status.Parent = Main

Instance.new("UICorner",Status).CornerRadius =
    UDim.new(0,7)

local function SetStatus(msg)
    Status.Text = "● "..msg
end

-- CONTENT

local Content = Instance.new("ScrollingFrame")
Content.Position = UDim2.new(0,12,0,122)
Content.Size = UDim2.new(1,-24,1,-135)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Blue
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new(0,0,0,0)
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0,8)
Layout.Parent = Content

-- SECTION

local function Section(name)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1,0,0,30)
    Label.BackgroundColor3 = Color3.fromRGB(0,65,130)
    Label.Text = name
    Label.TextColor3 = Color3.new(1,1,1)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Content

    Instance.new("UICorner",Label).CornerRadius =
        UDim.new(0,7)
end

-- ACTION

local function Action(name,callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1,0,0,40)
    Button.BackgroundColor3 = Light
    Button.Text = name
    Button.TextColor3 = Color3.new(1,1,1)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Content

    Instance.new("UICorner",Button).CornerRadius =
        UDim.new(0,8)

    Button.MouseButton1Click:Connect(callback)

    return Button
end

-- TOGGLE

local function Toggle(name,default,callback)
    local enabled = default or false

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1,0,0,42)
    Button.BackgroundColor3 = Light
    Button.TextColor3 = Color3.new(1,1,1)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Content

    Instance.new("UICorner",Button).CornerRadius =
        UDim.new(0,8)

    local function Update()
        Button.Text = name.." : "..(enabled and "ON" or "OFF")
        Button.BackgroundColor3 = enabled and
            Color3.fromRGB(0,75,145) or Light
    end

    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Update()

        if callback then
            callback(enabled)
        end
    end)

    Update()

    return Button
end

-- RARITY SELECTOR

local RarityFrame = Instance.new("Frame")
RarityFrame.Size = UDim2.fromOffset(245,355)
RarityFrame.Position = UDim2.new(0.5,-122,0.5,-177)
RarityFrame.BackgroundColor3 = Dark
RarityFrame.Visible = false
RarityFrame.Parent = GUI

Instance.new("UICorner",RarityFrame).CornerRadius =
    UDim.new(0,12)

local RarityStroke = Instance.new("UIStroke",RarityFrame)
RarityStroke.Color = Blue
RarityStroke.Thickness = 2

local RarityTitle = Instance.new("TextLabel")
RarityTitle.Size = UDim2.new(1,0,0,42)
RarityTitle.BackgroundTransparency = 1
RarityTitle.Text = "RiF | BEST EGG"
RarityTitle.TextColor3 = Blue
RarityTitle.TextSize = 19
RarityTitle.Font = Enum.Font.GothamBold
RarityTitle.Parent = RarityFrame

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Position = UDim2.new(0,5,0,40)
SelectedLabel.Size = UDim2.new(1,-10,0,28)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Selected: "..Settings.SelectedRarity
SelectedLabel.TextColor3 = Color3.new(1,1,1)
SelectedLabel.TextSize = 13
SelectedLabel.Parent = RarityFrame

local RarityList = Instance.new("ScrollingFrame")
RarityList.Position = UDim2.new(0,10,0,75)
RarityList.Size = UDim2.new(1,-20,1,-85)
RarityList.BackgroundTransparency = 1
RarityList.ScrollBarThickness = 3
RarityList.AutomaticCanvasSize = Enum.AutomaticSize.Y
RarityList.CanvasSize = UDim2.new(0,0,0,0)
RarityList.Parent = RarityFrame

local RarityLayout = Instance.new("UIListLayout")
RarityLayout.Padding = UDim.new(0,5)
RarityLayout.Parent = RarityList

for _,rarity in ipairs(Rarities) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1,0,0,27)
    Button.BackgroundColor3 = Light
    Button.Text = rarity
    Button.TextColor3 = Color3.new(1,1,1)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.Parent = RarityList

    Instance.new("UICorner",Button).CornerRadius =
        UDim.new(0,6)

    Button.MouseButton1Click:Connect(function()
        Settings.SelectedRarity = rarity
        SelectedLabel.Text = "Selected: "..rarity

        for _,item in ipairs(RarityList:GetChildren()) do
            if item:IsA("TextButton") then
                item.BackgroundColor3 = Light
            end
        end

        Button.BackgroundColor3 = Blue
        SetStatus("Selected Rarity: "..rarity)
    end)
end

-- EGG SCANNER

local function ScanEggs()
    EggData = {}

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Tool") then
            local name = string.lower(obj.Name)

            if string.find(name,"egg") then
                table.insert(EggData,obj.Name)
            end
        end
    end

    SetStatus("Egg Scanner: "..#EggData.." objects found")
end

-- MONSTER SCANNER

local function ScanMonsters()
    MonsterData = {}

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = string.lower(obj.Name)

            if string.find(name,"monster")
            or string.find(name,"beast") then
                table.insert(MonsterData,obj.Name)
            end
        end
    end

    SetStatus("Monster Scanner: "..#MonsterData.." found")
end

-- EGG FARM

Section("🥚 EGG FARM")

Action("Open Rarity Selector",function()
    RarityFrame.Visible = not RarityFrame.Visible
end)

Action("Scan Eggs",ScanEggs)

Toggle("Auto Refresh",true,function(state)
    Settings.AutoRefresh = state
    SetStatus(state and "Auto Refresh Enabled" or "Auto Refresh Disabled")
end)

Toggle("Egg Scanner",false,function(state)
    Settings.EggScanner = state
    SetStatus(state and "Egg Scanner Enabled" or "Egg Scanner Disabled")
end)

-- MONSTER

Section("👹 MONSTER")

Action("Scan Monsters",ScanMonsters)

Toggle("Monster Scanner",false,function(state)
    Settings.MonsterScanner = state
    SetStatus(state and "Monster Scanner Enabled" or "Monster Scanner Disabled")
end)

-- STEAL PANEL

Section("💎 STEAL PANEL")

Action("Show Egg Information",function()
    SetStatus("Egg Objects Found: "..#EggData)
end)

Action("Refresh Egg Data",ScanEggs)

-- PLAYER

Section("⚙️ PLAYER")

Action("Refresh Character",function()
    if Player.Character then
        SetStatus("Character Found")
    else
        SetStatus("Character Not Found")
    end
end)

Action("Hide RiF Hub",function()
    Main.Visible = false
end)

-- SHOW BUTTON

local ShowButton = Instance.new("TextButton")
ShowButton.Size = UDim2.fromOffset(100,38)
ShowButton.Position = UDim2.new(0,15,0.5,0)
ShowButton.BackgroundColor3 = Blue
ShowButton.Text = "RiF HUB"
ShowButton.TextColor3 = Color3.new(1,1,1)
ShowButton.TextSize = 13
ShowButton.Font = Enum.Font.GothamBold
ShowButton.Visible = false
ShowButton.Parent = GUI

Instance.new("UICorner",ShowButton).CornerRadius =
    UDim.new(0,8)

ShowButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    ShowButton.Visible = false
end)

Main:GetPropertyChangedSignal("Visible"):Connect(function()
    ShowButton.Visible = not Main.Visible
end)

-- DRAG SYSTEM

local Dragging = false
local DragStart
local StartPosition

Header.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.Touch
    or Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = Input.Position
        StartPosition = Main.Position
    end
end)

UIS.InputChanged:Connect(function(Input)
    if Dragging and (
        Input.UserInputType == Enum.UserInputType.Touch
        or Input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local Delta = Input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.Touch
    or Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

-- AUTO REFRESH

task.spawn(function()
    while GUI.Parent do
        task.wait(5)

        if Settings.AutoRefresh then
            if Settings.EggScanner then
                ScanEggs()
            end

            if Settings.MonsterScanner then
                ScanMonsters()
            end
        end
    end
end)

print("================================")
print("       RiF HUB V4 LOADED")
print("       STEAL AN EGG")
print("================================")
