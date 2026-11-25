-- RiF Hub | Black & Blue UI + Close (X) + Draggable Circle (-)
(function()
    local HUB_NAME = "RiF Hub"
    local DISCORD_URL = "https://discord.gg/mqfy9k5GF5"
    local YOUTUBE_URL = "https://www.youtube.com/@RiF_Hub1"
    local ICON_FILE = "rif_icon.jpg"
    local ICON_URL = "https://raw.githubusercontent.com/Youssefelabidy-collab/RiF-Hub/main/rif_icon.jpg"

    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")

    local C_BLACK_BG = Color3.fromRGB(8, 11, 18)
    local C_DARK_PANEL = Color3.fromRGB(12, 17, 28)
    local C_CARD_DARK = Color3.fromRGB(15, 22, 36)
    local C_BLUE_ACCENT = Color3.fromRGB(37, 99, 235)
    local C_BLUE_BRIGHT = Color3.fromRGB(59, 130, 246)
    local C_BLUE_ACTIVE = Color3.fromRGB(29, 78, 216)
    local C_OFF_STATE = Color3.fromRGB(13, 19, 31)
    local C_RED_CLOSE = Color3.fromRGB(185, 28, 28)
    local C_TEXT_WHITE = Color3.fromRGB(240, 246, 255)
    local C_TEXT_BLUE = Color3.fromRGB(147, 197, 253)

    local running = true
    local uiRefs = { gui = nil, statusLabel = nil, win = nil, circle = nil }

    local function getUiParent()
        local ok, res = pcall(function() return gethui and gethui() or CoreGui end)
        if ok and res then return res end
        local lp = Players.LocalPlayer
        return lp and lp:FindFirstChildOfClass("PlayerGui") or CoreGui
    end

    local function resolveIcon()
        local paths = {
            ICON_FILE,
            "RiF Hub/" .. ICON_FILE,
            "Download/RiF Hub/" .. ICON_FILE,
            "/sdcard/Download/RiF Hub/" .. ICON_FILE,
        }
        if getcustomasset and isfile then
            for _, path in ipairs(paths) do
                local okEx, ex = pcall(isfile, path)
                if okEx and ex then
                    local okAs, as = pcall(getcustomasset, path)
                    if okAs and as and as ~= "" then
                        return as
                    end
                end
            end
        end
        if ICON_URL ~= "" then
            return ICON_URL
        end
        return ""
    end

    local function setStatus(text)
        if uiRefs.statusLabel and uiRefs.statusLabel.Parent then
            uiRefs.statusLabel.Text = text
        end
    end

    local function destroyHub()
        running = false
        if uiRefs.gui and uiRefs.gui.Parent then
            uiRefs.gui:Destroy()
        end
    end

    local function openExternalLink(url, labelName)
        pcall(function() if setclipboard then setclipboard(url) end end)
        local opened = false
        pcall(function() if openUrl then openUrl(url); opened = true end end)
        setStatus(labelName .. (opened and " opened & copied" or " link copied"))
    end

    local function styleBox(inst, radius, strokeColor, thickness)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 8)
        c.Parent = inst
        if strokeColor then
            local s = Instance.new("UIStroke")
            s.Color = strokeColor
            s.Thickness = thickness or 1
            s.Parent = inst
        end
    end

    local function makeLabel(parent, props)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = props.bgTransp or 1
        l.Size = props.size
        l.Position = props.pos
        l.Text = props.text or ""
        l.TextColor3 = props.color or C_TEXT_WHITE
        l.Font = props.font or Enum.Font.Gotham
        l.TextSize = props.textSize or 12
        l.TextXAlignment = props.align or Enum.TextXAlignment.Left
        l.TextWrapped = props.wrapped or false
        if props.bgColor then l.BackgroundColor3 = props.bgColor end
        l.Parent = parent
        return l
    end

    local function makeButton(parent, props, onClick)
        local b = Instance.new("TextButton")
        b.Size = props.size
        b.Position = props.pos
        b.BackgroundColor3 = props.bgColor or C_BLUE_ACCENT
        b.Text = props.text or ""
        b.TextColor3 = props.color or C_TEXT_WHITE
        b.Font = props.font or Enum.Font.GothamBold
        b.TextSize = props.textSize or 12
        b.Parent = parent
        if props.radius then styleBox(b, props.radius, props.stroke, props.strokeThick) end
        if onClick then b.MouseButton1Click:Connect(onClick) end
        return b
    end

    local function makeLinkRow(parent, yPos, badgeText, badgeColor, titleText, subText, btnText, url, label)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -16, 0, 56)
        row.Position = UDim2.new(0, 8, 0, yPos)
        row.BackgroundColor3 = C_CARD_DARK
        row.BorderSizePixel = 0
        row.Parent = parent
        styleBox(row, 9, C_BLUE_ACCENT, 1)

        local icon = makeLabel(row, {
            bgTransp = 0, bgColor = badgeColor, size = UDim2.new(0, 42, 0, 42),
            pos = UDim2.new(0, 7, 0.5, -21), text = badgeText,
            font = Enum.Font.GothamBlack, textSize = 14, align = Enum.TextXAlignment.Center
        })
        styleBox(icon, 8)

        makeLabel(row, {
            size = UDim2.new(1, -135, 0, 20), pos = UDim2.new(0, 56, 0, 8),
            text = titleText, font = Enum.Font.GothamBold, textSize = 12
        })
        makeLabel(row, {
            size = UDim2.new(1, -135, 0, 18), pos = UDim2.new(0, 56, 0, 28),
            text = subText, color = C_TEXT_BLUE, textSize = 10
        })

        makeButton(row, {
            size = UDim2.new(0, 76, 0, 32), pos = UDim2.new(1, -84, 0.5, -16),
            bgColor = C_BLUE_BRIGHT, text = btnText, textSize = 11, radius = 8
        }, function()
            openExternalLink(url, label)
        end)
    end

    local function attachLongPressDrag(circleBtn, onTap)
        local holding = false
        local dragging = false
        local movedFar = false
        local holdToken = 0
        local dragStartPos = Vector2.zero
        local frameStartPos = UDim2.new()

        circleBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                holding = true
                dragging = false
                movedFar = false
                holdToken += 1
                local myToken = holdToken
                dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
                frameStartPos = circleBtn.Position

                task.delay(0.35, function()
                    if holding and myToken == holdToken and not movedFar then
                        dragging = true
                        circleBtn.BackgroundColor3 = C_BLUE_ACCENT
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not holding then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local cur = Vector2.new(input.Position.X, input.Position.Y)
                local delta = cur - dragStartPos
                if delta.Magnitude > 8 then
                    movedFar = true
                end
                if dragging then
                    circleBtn.Position = UDim2.new(
                        frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                        frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
                    )
                end
            end
        end)

        circleBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local wasDragging = dragging
                holding = false
                dragging = false
                holdToken += 1
                circleBtn.BackgroundColor3 = C_BLACK_BG
                if not wasDragging and not movedFar and onTap then
                    onTap()
                end
            end
        end)
    end

    local function buildInterface(cfg)
        pcall(function()
            local parent = getUiParent()
            if not parent then return end
            local old = parent:FindFirstChild("RiFHub_UI")
            if old then old:Destroy() end

            local gui = Instance.new("ScreenGui")
            gui.Name = "RiFHub_UI"
            gui.ResetOnSpawn = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = parent
            uiRefs.gui = gui

            local win = Instance.new("Frame")
            win.Size = UDim2.new(0, 400, 0, 245)
            win.Position = UDim2.new(0.5, -200, 0.5, -122)
            win.BackgroundColor3 = C_BLACK_BG
            win.BackgroundTransparency = 0.04
            win.BorderSizePixel = 0
            win.Parent = gui
            styleBox(win, 12, C_BLUE_ACCENT, 1.4)
            uiRefs.win = win

            -- Header with RiF Hub + (-) Minimize + (X) Close
            local header = Instance.new("Frame")
            header.Size = UDim2.new(1, -16, 0, 32)
            header.Position = UDim2.new(0, 8, 0, 6)
            header.BackgroundColor3 = C_DARK_PANEL
            header.BorderSizePixel = 0
            header.Parent = win
            styleBox(header, 8, Color3.fromRGB(30, 64, 175), 1)

            makeLabel(header, {
                size = UDim2.new(1, -76, 1, 0), pos = UDim2.new(0, 10, 0, 0),
                text = HUB_NAME, font = Enum.Font.GothamBold, textSize = 13
            })

            local circle = Instance.new("ImageButton")
            circle.Size = UDim2.new(0, 56, 0, 56)
            circle.Position = UDim2.new(0.5, -28, 0.5, -28)
            circle.BackgroundColor3 = C_BLACK_BG
            circle.BorderSizePixel = 0
            circle.Visible = false
            circle.ScaleType = Enum.ScaleType.Crop
            circle.Image = resolveIcon()
            circle.Parent = gui
            styleBox(circle, 28, C_BLUE_BRIGHT, 2)
            uiRefs.circle = circle

            local fallbackTag = makeLabel(circle, {
                size = UDim2.new(1, 0, 1, 0), pos = UDim2.new(0, 0, 0, 0),
                text = "RiF", font = Enum.Font.GothamBlack, textSize = 13,
                color = C_TEXT_BLUE, align = Enum.TextXAlignment.Center
            })
            fallbackTag.Visible = (circle.Image == "")

            attachLongPressDrag(circle, function()
                circle.Visible = false
                win.Visible = true
            end)

            makeButton(header, {
                size = UDim2.new(0, 24, 0, 22), pos = UDim2.new(1, -56, 0.5, -11),
                bgColor = C_BLUE_ACTIVE, text = "-", textSize = 14, radius = 6
            }, function()
                win.Visible = false
                circle.Position = UDim2.new(0.5, -28, 0.5, -28)
                circle.Visible = true
            end)

            makeButton(header, {
                size = UDim2.new(0, 24, 0, 22), pos = UDim2.new(1, -28, 0.5, -11),
                bgColor = C_RED_CLOSE, text = "×", textSize = 13, radius = 6
            }, function()
                destroyHub()
            end)

            local side = Instance.new("Frame")
            side.Size = UDim2.new(0, 112, 1, -54)
            side.Position = UDim2.new(0, 8, 0, 44)
            side.BackgroundColor3 = C_DARK_PANEL
            side.BorderSizePixel = 0
            side.Parent = win
            styleBox(side, 10, Color3.fromRGB(30, 64, 175), 1)

            local mainPanel = Instance.new("ScrollingFrame")
            mainPanel.Size = UDim2.new(1, -136, 1, -54)
            mainPanel.Position = UDim2.new(0, 128, 0, 44)
            mainPanel.BackgroundColor3 = C_DARK_PANEL
            mainPanel.BorderSizePixel = 0
            mainPanel.ScrollBarThickness = 3
            mainPanel.ScrollBarImageColor3 = C_BLUE_BRIGHT
            mainPanel.CanvasSize = UDim2.new(0, 0, 0, 190)
            mainPanel.Parent = win
            styleBox(mainPanel, 10, Color3.fromRGB(30, 64, 175), 1)

            local aboutPanel = Instance.new("Frame")
            aboutPanel.Size = UDim2.new(1, -136, 1, -54)
            aboutPanel.Position = UDim2.new(0, 128, 0, 44)
            aboutPanel.BackgroundColor3 = C_DARK_PANEL
            aboutPanel.BorderSizePixel = 0
            aboutPanel.Visible = false
            aboutPanel.Parent = win
            styleBox(aboutPanel, 10, Color3.fromRGB(30, 64, 175), 1)

            local mainTab, aboutTab
            mainTab = makeButton(side, {
                size = UDim2.new(1, -12, 0, 32), pos = UDim2.new(0, 6, 0, 8),
                bgColor = C_BLUE_ACCENT, text = "main", textSize = 13, radius = 8
            }, function()
                mainPanel.Visible = true; aboutPanel.Visible = false
                mainTab.BackgroundColor3 = C_BLUE_ACCENT; mainTab.TextColor3 = C_TEXT_WHITE
                aboutTab.BackgroundColor3 = C_OFF_STATE; aboutTab.TextColor3 = C_TEXT_BLUE
            end)

            aboutTab = makeButton(side, {
                size = UDim2.new(1, -12, 0, 32), pos = UDim2.new(0, 6, 0, 46),
                bgColor = C_OFF_STATE, color = C_TEXT_BLUE, text = "about us", textSize = 12, radius = 8
            }, function()
                mainPanel.Visible = false; aboutPanel.Visible = true
                aboutTab.BackgroundColor3 = C_BLUE_ACCENT; aboutTab.TextColor3 = C_TEXT_WHITE
                mainTab.BackgroundColor3 = C_OFF_STATE; mainTab.TextColor3 = C_TEXT_BLUE
            end)

            local st = makeLabel(side, {
                bgTransp = 0, bgColor = C_BLACK_BG, size = UDim2.new(1, -12, 0, 42),
                pos = UDim2.new(0, 6, 1, -48), text = "Ready", color = C_TEXT_BLUE,
                textSize = 10, align = Enum.TextXAlignment.Center, wrapped = true
            })
            styleBox(st, 8, Color3.fromRGB(30, 58, 138), 1)
            uiRefs.statusLabel = st

            local toggles = {
                { "Target Egg Farm", "AutoFarmEgg", 8 },
                { "Best Egg Farm", "AutoBestEgg", 50 },
                { "Monster Shield", "NoMonsterDamage", 92 },
                { "Speed Treadmill", "AutoTreadmill", 134 },
            }
            for _, item in ipairs(toggles) do
                local lbl, key, y = item[1], item[2], item[3]
                local btn
                local function paint()
                    local on = cfg and cfg[key] == true
                    btn.BackgroundColor3 = on and C_BLUE_ACTIVE or C_OFF_STATE
                    btn.Text = lbl .. ": " .. (on and "ON" or "OFF")
                end
                btn = makeButton(mainPanel, {
                    size = UDim2.new(1, -16, 0, 36), pos = UDim2.new(0, 8, 0, y),
                    textSize = 12, radius = 8, stroke = C_BLUE_BRIGHT, strokeThick = 1
                }, function()
                    if cfg then
                        cfg[key] = not (cfg[key] == true)
                        paint()
                        setStatus(lbl .. " -> " .. (cfg[key] and "ON" or "OFF"))
                    end
                end)
                paint()
            end

            makeLabel(aboutPanel, {
                size = UDim2.new(1, -16, 0, 24), pos = UDim2.new(0, 8, 0, 6),
                text = HUB_NAME .. " | Community & Links", font = Enum.Font.GothamBold, textSize = 12
            })
            makeLinkRow(aboutPanel, 38, "DC", C_BLUE_ACCENT, "Discord Server", "RiF Community", "Join", DISCORD_URL, "Discord")
            makeLinkRow(aboutPanel, 102, "YT", C_BLUE_ACTIVE, "YouTube Channel", "@RiF_Hub1", "subscribe", YOUTUBE_URL, "YouTube")
        end)
    end

    buildInterface(nil)
    setStatus("Loading...")

    local function pullModules()
        local baseUrl = "https://raw.githubusercontent.com/Youssefelabidy-collab/RiF-Hub/main/"
        if baseUrl:find("YOUR_USER") then return nil end
        local function loadPart(name) return loadstring(game:HttpGet(baseUrl .. name))() end
        return loadPart("config.lua"), loadPart("eggs.lua"), loadPart("combat_treadmill.lua")
    end

    local cfg, eggsMod, combatMod = pullModules()
    if not cfg or not eggsMod or not combatMod then
        setStatus("Set GitHub URL")
        warn("[" .. HUB_NAME .. "] Set GitHub baseUrl in main.lua before running.")
        return
    end

    buildInterface(cfg)
    setStatus("Active")

    local rng = Random.new()
    local function waitJitter(baseDelay, jitter)
        task.wait(math.max(0.03, (baseDelay or 0.1) + rng:NextNumber(0, jitter or 0.05)))
    end

    local loops = {
        { function() return cfg.AutoFarmEgg end, function() eggsMod.FarmTarget(cfg) end, function() return cfg.EggTeleportDelay end },
        { function() return cfg.AutoBestEgg end, function() eggsMod.FarmBest(cfg) end, function() return cfg.BestEggInterval end },
        { function() return cfg.NoMonsterDamage end, function() combatMod.ProtectFromMonsters(cfg) end, function() return 0.08 end },
        { function() return cfg.AutoTreadmill end, function() combatMod.FarmTreadmill(cfg) end, function() return cfg.TreadmillDelay end },
    }
    for _, lp in ipairs(loops) do
        task.spawn(function()
            while running and task.wait() do
                if not running then break end
                if lp[1]() then pcall(lp[2]) end
                waitJitter(lp[3](), cfg.TimingJitter)
            end
        end)
    end
end)()
