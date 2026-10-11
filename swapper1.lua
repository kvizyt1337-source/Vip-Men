-- LocalScript → StarterPlayer → StarterPlayerScripts

-- ★ pcall для перехвата ошибок
local _ok, _err = pcall(function()

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer

	-- ===== НАСТРОЙКИ =====
	local flyHeight = 25
	local flySpeed = 100
	local walkSpeedValue = 16
	local jumpPowerValue = 50
	local TP_STEP_DISTANCE = 8
	local TP_STEP_INTERVAL = 0.05

	local flyEnabled = false
	local flyFreeSpeed = 80

	local magnetEnabled = false
	local magnetTarget = nil
	local magnetDistance = 5
	local magnetConn = nil

	local autoTpEnabled = false
	local autoTpKey = Enum.KeyCode.E
	local autoTpKeyName = "E"
	local autoTpAbove = false

	local aimbotEnabled = false
	local aimbotKey = Enum.KeyCode.Q
	local aimbotKeyName = "Q"
	local aimbotSmoothness = 0.25
	local aimbotRange = 300
	local aimbotTeamCheck = false
	local aimbotVisibleCheck = false
	local aimbotConn = nil
	local aimbotTarget = nil

	local triggerbotEnabled = false
	local triggerbotRange = 50
	local triggerbotDelay = 0.1
	local triggerbotLastShot = 0
	local triggerbotConn = nil

	local magnetAllEnabled = false
	local magnetAllConn = nil
	local magnetAllForwardOffset = 15
	local magnetAllRadius = 100
	local magnetAllHoldTime = 8

	local savedPosition = nil
	local positionBeforeTeleport = nil
	local isTeleporting = false
	local teleportCancelled = false
	local connections = {}
	local unloaded = false
	local flyConn = nil
	local toggleRefs = {}
	local sliderRefs = {}

	local currentTheme = "Тёмная"
	local currentStyle = "Default"

	-- ===== КОНФИГ =====
	local CONFIG_FOLDER = "vip-menu"
	local CONFIG_FILE = "config.cfg"

	local hasFileAPI = (typeof(writefile) == "function") and (typeof(readfile) == "function")
		and (typeof(isfile) == "function") and (typeof(makefolder) == "function")

	local function configPath() return CONFIG_FOLDER .. "/" .. CONFIG_FILE end

	local function ensureFolder()
		if not hasFileAPI then return false end
		pcall(function()
			if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
		end)
		return true
	end

	local function serializeConfig()
		local data = {
			flySpeed = flySpeed,
			walkSpeed = walkSpeedValue,
			jumpPower = jumpPowerValue,
			flyFreeSpeed = flyFreeSpeed,
			magnetDistance = magnetDistance,
			autoTpKey = autoTpKeyName,
			autoTpEnabled = autoTpEnabled and "1" or "0",
			autoTpAbove = autoTpAbove and "1" or "0",
			aimbotKey = aimbotKeyName,
			aimbotEnabled = aimbotEnabled and "1" or "0",
			aimbotSmoothness = aimbotSmoothness,
			aimbotRange = aimbotRange,
			aimbotTeamCheck = aimbotTeamCheck and "1" or "0",
			aimbotVisibleCheck = aimbotVisibleCheck and "1" or "0",
			triggerbotEnabled = triggerbotEnabled and "1" or "0",
			triggerbotRange = triggerbotRange,
			triggerbotDelay = triggerbotDelay,
			magnetAllForwardOffset = magnetAllForwardOffset,
			magnetAllRadius = magnetAllRadius,
			magnetAllHoldTime = magnetAllHoldTime,
			theme = currentTheme,
			style = currentStyle,
		}
		local lines = {"-- VIP Menu Config", "-- by swapper.sk", ""}
		for k, v in pairs(data) do
			table.insert(lines, tostring(k) .. "=" .. tostring(v))
		end
		return table.concat(lines, "\n")
	end

	local function saveConfig()
		if not hasFileAPI then return false end
		ensureFolder()
		local ok = pcall(function() writefile(configPath(), serializeConfig()) end)
		return ok
	end

	local function loadConfig()
		if not hasFileAPI then return false end
		if not isfile(configPath()) then
			pcall(saveConfig)
			return false
		end
		local ok, content = pcall(function() return readfile(configPath()) end)
		if not ok or not content then return false end

		local config = {}
		for line in content:gmatch("[^\r\n]+") do
			local key, value = line:match("^([%w_]+)=(.+)$")
			if key and value then config[key] = value end
		end

		local function num(v, d) return tonumber(v) or d end
		local function bool(v) return v == "1" or v == "true" end

		flySpeed = num(config.flySpeed, flySpeed)
		walkSpeedValue = num(config.walkSpeed, walkSpeedValue)
		jumpPowerValue = num(config.jumpPower, jumpPowerValue)
		flyFreeSpeed = num(config.flyFreeSpeed, flyFreeSpeed)
		magnetDistance = num(config.magnetDistance, magnetDistance)

		if config.autoTpKey then
			autoTpKeyName = config.autoTpKey
			local kp = Enum.KeyCode[config.autoTpKey]
			if kp then autoTpKey = kp end
		end
		autoTpEnabled = bool(config.autoTpEnabled)
		autoTpAbove = bool(config.autoTpAbove)

		if config.aimbotKey then
			aimbotKeyName = config.aimbotKey
			local kp = Enum.KeyCode[config.aimbotKey]
			if kp then aimbotKey = kp end
		end
		aimbotEnabled = bool(config.aimbotEnabled)
		aimbotSmoothness = num(config.aimbotSmoothness, aimbotSmoothness)
		aimbotRange = num(config.aimbotRange, aimbotRange)
		aimbotTeamCheck = bool(config.aimbotTeamCheck)
		aimbotVisibleCheck = bool(config.aimbotVisibleCheck)

		triggerbotEnabled = bool(config.triggerbotEnabled)
		triggerbotRange = num(config.triggerbotRange, triggerbotRange)
		triggerbotDelay = num(config.triggerbotDelay, triggerbotDelay)

		magnetAllForwardOffset = num(config.magnetAllForwardOffset, magnetAllForwardOffset)
		magnetAllRadius = num(config.magnetAllRadius, magnetAllRadius)
		magnetAllHoldTime = num(config.magnetAllHoldTime, magnetAllHoldTime)

		if config.theme then currentTheme = config.theme end
		if config.style then currentStyle = config.style end
		return true
	end

	-- ===== ТЕМЫ =====
	local THEMES = {
		["Тёмная"] = {
			bg = Color3.fromRGB(20, 20, 26), panel = Color3.fromRGB(24, 24, 30),
			topBar = Color3.fromRGB(26, 26, 34), button = Color3.fromRGB(32, 32, 40),
			buttonHover = Color3.fromRGB(42, 42, 54), accent = Color3.fromRGB(90, 70, 220),
			text = Color3.fromRGB(220, 220, 235), textDim = Color3.fromRGB(150, 150, 170),
			stroke = Color3.fromRGB(48, 48, 60), header = Color3.fromRGB(40, 40, 55),
			headerText = Color3.fromRGB(180, 180, 220), barBg = Color3.fromRGB(18, 18, 24),
			success = Color3.fromRGB(120, 255, 150), danger = Color3.fromRGB(255, 90, 90),
			warn = Color3.fromRGB(255, 200, 80), info = Color3.fromRGB(130, 200, 255),
			sliderColor = Color3.fromRGB(130, 190, 255),
		},
		["Белая"] = {
			bg = Color3.fromRGB(245, 245, 250), panel = Color3.fromRGB(235, 235, 245),
			topBar = Color3.fromRGB(255, 255, 255), button = Color3.fromRGB(255, 255, 255),
			buttonHover = Color3.fromRGB(230, 230, 240), accent = Color3.fromRGB(120, 100, 240),
			text = Color3.fromRGB(30, 30, 40), textDim = Color3.fromRGB(100, 100, 120),
			stroke = Color3.fromRGB(200, 200, 215), header = Color3.fromRGB(220, 220, 235),
			headerText = Color3.fromRGB(60, 60, 90), barBg = Color3.fromRGB(210, 210, 220),
			success = Color3.fromRGB(60, 180, 100), danger = Color3.fromRGB(220, 60, 60),
			warn = Color3.fromRGB(230, 160, 30), info = Color3.fromRGB(80, 130, 220),
			sliderColor = Color3.fromRGB(100, 130, 240),
		},
		["Космос"] = {
			bg = Color3.fromRGB(10, 8, 25), panel = Color3.fromRGB(18, 15, 40),
			topBar = Color3.fromRGB(25, 15, 60), button = Color3.fromRGB(30, 25, 60),
			buttonHover = Color3.fromRGB(45, 35, 90), accent = Color3.fromRGB(150, 80, 255),
			text = Color3.fromRGB(230, 220, 255), textDim = Color3.fromRGB(160, 140, 220),
			stroke = Color3.fromRGB(80, 50, 150), header = Color3.fromRGB(50, 30, 110),
			headerText = Color3.fromRGB(200, 170, 255), barBg = Color3.fromRGB(15, 10, 35),
			success = Color3.fromRGB(150, 120, 255), danger = Color3.fromRGB(255, 100, 200),
			warn = Color3.fromRGB(255, 200, 255), info = Color3.fromRGB(180, 150, 255),
			sliderColor = Color3.fromRGB(180, 130, 255),
		},
		["Снежная"] = {
			bg = Color3.fromRGB(225, 240, 250), panel = Color3.fromRGB(210, 230, 245),
			topBar = Color3.fromRGB(240, 250, 255), button = Color3.fromRGB(255, 255, 255),
			buttonHover = Color3.fromRGB(210, 230, 245), accent = Color3.fromRGB(80, 160, 220),
			text = Color3.fromRGB(30, 50, 70), textDim = Color3.fromRGB(90, 120, 150),
			stroke = Color3.fromRGB(180, 210, 230), header = Color3.fromRGB(190, 220, 240),
			headerText = Color3.fromRGB(50, 90, 130), barBg = Color3.fromRGB(190, 210, 225),
			success = Color3.fromRGB(80, 180, 180), danger = Color3.fromRGB(220, 100, 130),
			warn = Color3.fromRGB(230, 170, 90), info = Color3.fromRGB(100, 170, 230),
			sliderColor = Color3.fromRGB(100, 170, 230),
		},
		["Осенняя"] = {
			bg = Color3.fromRGB(45, 25, 15), panel = Color3.fromRGB(60, 35, 20),
			topBar = Color3.fromRGB(80, 45, 25), button = Color3.fromRGB(75, 45, 25),
			buttonHover = Color3.fromRGB(105, 65, 35), accent = Color3.fromRGB(230, 130, 40),
			text = Color3.fromRGB(250, 230, 210), textDim = Color3.fromRGB(210, 170, 130),
			stroke = Color3.fromRGB(140, 80, 40), header = Color3.fromRGB(110, 60, 30),
			headerText = Color3.fromRGB(255, 210, 170), barBg = Color3.fromRGB(35, 20, 10),
			success = Color3.fromRGB(180, 200, 90), danger = Color3.fromRGB(220, 80, 60),
			warn = Color3.fromRGB(240, 180, 70), info = Color3.fromRGB(230, 160, 90),
			sliderColor = Color3.fromRGB(230, 160, 90),
		},
	}

	local STYLES = {
		["Default"] = {cornerRadius=10, buttonRadius=6, strokeThickness=1, topBarHeight=46, sidebarWidth=150, padding=8},
		["Compact"] = {cornerRadius=4, buttonRadius=2, strokeThickness=1, topBarHeight=36, sidebarWidth=130, padding=4},
		["Rounded"] = {cornerRadius=20, buttonRadius=14, strokeThickness=2, topBarHeight=54, sidebarWidth=170, padding=12},
	}

	-- ============================================================
	-- ЗАГРУЗОЧНЫЙ ЭКРАН
	-- ============================================================
	local loadGui = Instance.new("ScreenGui")
	loadGui.Name = "VIPMenu_Loading"
	loadGui.ResetOnSpawn = false
	loadGui.IgnoreGuiInset = true
	loadGui.DisplayOrder = 1000000
	loadGui.Parent = player:WaitForChild("PlayerGui")

	local loadFrame = Instance.new("Frame")
	loadFrame.Size = UDim2.new(0, 400, 0, 180)
	loadFrame.Position = UDim2.new(0.5, -200, 0.5, -90)
	loadFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	loadFrame.BorderSizePixel = 0
	loadFrame.Parent = loadGui

	local loadCorner = Instance.new("UICorner")
	loadCorner.CornerRadius = UDim.new(0, 12)
	loadCorner.Parent = loadFrame

	local loadStroke = Instance.new("UIStroke")
	loadStroke.Color = Color3.fromRGB(90, 70, 220)
	loadStroke.Thickness = 2
	loadStroke.Parent = loadFrame

	local loadTitle = Instance.new("TextLabel")
	loadTitle.Size = UDim2.new(1, 0, 0, 40)
	loadTitle.Position = UDim2.new(0, 0, 0, 20)
	loadTitle.BackgroundTransparency = 1
	loadTitle.Text = "⚡ VIP MENU"
	loadTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	loadTitle.TextSize = 22
	loadTitle.Font = Enum.Font.GothamBold
	loadTitle.Parent = loadFrame

	local loadSubtitle = Instance.new("TextLabel")
	loadSubtitle.Size = UDim2.new(1, 0, 0, 20)
	loadSubtitle.Position = UDim2.new(0, 0, 0, 58)
	loadSubtitle.BackgroundTransparency = 1
	loadSubtitle.Text = "загрузка..."
	loadSubtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
	loadSubtitle.TextSize = 12
	loadSubtitle.Font = Enum.Font.Gotham
	loadSubtitle.Parent = loadFrame

	local loadBarBg = Instance.new("Frame")
	loadBarBg.Size = UDim2.new(1, -60, 0, 10)
	loadBarBg.Position = UDim2.new(0, 30, 0, 100)
	loadBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	loadBarBg.BorderSizePixel = 0
	loadBarBg.Parent = loadFrame
	local loadBarCorner = Instance.new("UICorner") loadBarCorner.CornerRadius = UDim.new(1, 0) loadBarCorner.Parent = loadBarBg

	local loadBarFill = Instance.new("Frame")
	loadBarFill.Size = UDim2.new(0, 0, 1, 0)
	loadBarFill.BackgroundColor3 = Color3.fromRGB(120, 100, 240)
	loadBarFill.BorderSizePixel = 0
	loadBarFill.Parent = loadBarBg
	local loadBarFillCorner = Instance.new("UICorner") loadBarFillCorner.CornerRadius = UDim.new(1, 0) loadBarFillCorner.Parent = loadBarFill

	local loadPercent = Instance.new("TextLabel")
	loadPercent.Size = UDim2.new(1, 0, 0, 24)
	loadPercent.Position = UDim2.new(0, 0, 0, 120)
	loadPercent.BackgroundTransparency = 1
	loadPercent.Text = "0%"
	loadPercent.TextColor3 = Color3.fromRGB(180, 180, 220)
	loadPercent.TextSize = 16
	loadPercent.Font = Enum.Font.GothamBold
	loadPercent.Parent = loadFrame

	local function setPercent(p)
		loadPercent.Text = tostring(math.floor(p)) .. "%"
		TweenService:Create(loadBarFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			Size = UDim2.new(p / 100, 0, 1, 0)
		}):Play()
	end

	local loadSteps = {
		{text = "Инициализация...", to = 15, duration = 0.35},
		{text = "Загрузка конфига...", to = 30, duration = 0.35},
		{text = "Построение интерфейса...", to = 50, duration = 0.45},
		{text = "Загрузка тем...", to = 65, duration = 0.3},
		{text = "Инициализация модулей...", to = 80, duration = 0.4},
		{text = "Запуск сервисов...", to = 95, duration = 0.35},
		{text = "Готово!", to = 100, duration = 0.3},
	}

	for _, step in ipairs(loadSteps) do
		loadSubtitle.Text = step.text
		setPercent(step.to)
		task.wait(step.duration)
	end

	-- ============================================================
	-- ОСНОВНОЙ GUI
	-- ============================================================
	local themeTargets = {}
	local function registerThemeTarget(obj, role)
		if obj then table.insert(themeTargets, {obj = obj, role = role}) end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VIPMenu"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999999
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local windowW, windowH = 680, 600

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.Size = UDim2.new(0, windowW, 0, windowH)
	window.Position = UDim2.new(0.5, -windowW/2, 0.5, -windowH/2 + 40)
	window.BackgroundColor3 = THEMES[currentTheme].bg
	window.BackgroundTransparency = 1
	window.BorderSizePixel = 0
	window.Visible = false
	window.Active = true
	window.Draggable = true
	window.Parent = screenGui
	window.ZIndex = 10
	registerThemeTarget(window, "bg")

	local windowCorner = Instance.new("UICorner")
	windowCorner.CornerRadius = UDim.new(0, 10)
	windowCorner.Parent = window

	local windowStroke = Instance.new("UIStroke")
	windowStroke.Color = THEMES[currentTheme].stroke
	windowStroke.Thickness = 1
	windowStroke.Transparency = 1
	windowStroke.Parent = window

	-- Топ-бар
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 46)
	topBar.BackgroundColor3 = THEMES[currentTheme].topBar
	topBar.BorderSizePixel = 0
	topBar.Parent = window
	topBar.ZIndex = 11
	registerThemeTarget(topBar, "topBar")
	local topBarCorner = Instance.new("UICorner") topBarCorner.CornerRadius = UDim.new(0, 10) topBarCorner.Parent = topBar

	local topBarCover = Instance.new("Frame")
	topBarCover.Size = UDim2.new(1, 0, 0, 12)
	topBarCover.Position = UDim2.new(0, 0, 1, -12)
	topBarCover.BackgroundColor3 = THEMES[currentTheme].topBar
	topBarCover.BorderSizePixel = 0
	topBarCover.Parent = topBar
	topBarCover.ZIndex = 11
	registerThemeTarget(topBarCover, "topBar")

	local logoBox = Instance.new("Frame")
	logoBox.Size = UDim2.new(0, 30, 0, 30)
	logoBox.Position = UDim2.new(0, 12, 0.5, -15)
	logoBox.BackgroundColor3 = THEMES[currentTheme].accent
	logoBox.BorderSizePixel = 0
	logoBox.Parent = topBar
	logoBox.ZIndex = 12
	registerThemeTarget(logoBox, "accent")
	local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 7) lc.Parent = logoBox

	local logoIcon = Instance.new("TextLabel")
	logoIcon.Size = UDim2.new(1, 0, 1, 0)
	logoIcon.BackgroundTransparency = 1
	logoIcon.Text = "⚡"
	logoIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	logoIcon.TextSize = 18
	logoIcon.Font = Enum.Font.GothamBold
	logoIcon.Parent = logoBox
	logoIcon.ZIndex = 13

	local titleTop = Instance.new("TextLabel")
	titleTop.Size = UDim2.new(0, 250, 0, 16)
	titleTop.Position = UDim2.new(0, 52, 0, 7)
	titleTop.BackgroundTransparency = 1
	titleTop.Text = "VIP MENU"
	titleTop.TextColor3 = THEMES[currentTheme].text
	titleTop.TextSize = 13
	titleTop.TextXAlignment = Enum.TextXAlignment.Left
	titleTop.Font = Enum.Font.GothamBold
	titleTop.Parent = topBar
	titleTop.ZIndex = 12
	registerThemeTarget(titleTop, "text")

	local subtitleTop = Instance.new("TextLabel")
	subtitleTop.Size = UDim2.new(0, 350, 0, 14)
	subtitleTop.Position = UDim2.new(0, 52, 0, 22)
	subtitleTop.BackgroundTransparency = 1
	subtitleTop.Text = "by swapper.sk"
	subtitleTop.TextColor3 = THEMES[currentTheme].textDim
	subtitleTop.TextSize = 10
	subtitleTop.TextXAlignment = Enum.TextXAlignment.Left
	subtitleTop.Font = Enum.Font.Gotham
	subtitleTop.Parent = topBar
	subtitleTop.ZIndex = 12
	registerThemeTarget(subtitleTop, "textDim")

	local function createTopBtn(text, xOff, txtColor)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 24, 0, 24)
		b.Position = UDim2.new(1, xOff, 0.5, -12)
		b.BackgroundColor3 = THEMES[currentTheme].button
		b.Text = text
		b.TextColor3 = txtColor
		b.TextSize = 12
		b.Font = Enum.Font.GothamBold
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Parent = topBar
		b.ZIndex = 13
		registerThemeTarget(b, "button")
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
		return b
	end

	local minimizeBtn = createTopBtn("—", -70, Color3.fromRGB(200, 200, 210))
	local closeBtn = createTopBtn("✕", -38, Color3.fromRGB(255, 100, 110))

	-- Сайдбар
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 150, 1, -58)
	sidebar.Position = UDim2.new(0, 8, 0, 52)
	sidebar.BackgroundColor3 = THEMES[currentTheme].panel
	sidebar.BorderSizePixel = 0
	sidebar.Parent = window
	sidebar.ZIndex = 11
	registerThemeTarget(sidebar, "panel")
	local sbC = Instance.new("UICorner") sbC.CornerRadius = UDim.new(0, 8) sbC.Parent = sidebar

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 4)
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = sidebar

	local sidePad = Instance.new("UIPadding")
	sidePad.PaddingTop = UDim.new(0, 10)
	sidePad.PaddingLeft = UDim.new(0, 8)
	sidePad.PaddingRight = UDim.new(0, 8)
	sidePad.Parent = sidebar

	-- Контент
	local contentArea = Instance.new("Frame")
	contentArea.Name = "Content"
	contentArea.Size = UDim2.new(1, -174, 1, -68)
	contentArea.Position = UDim2.new(0, 166, 0, 58)
	contentArea.BackgroundColor3 = THEMES[currentTheme].panel
	contentArea.BorderSizePixel = 0
	contentArea.Parent = window
	contentArea.ZIndex = 11
	registerThemeTarget(contentArea, "panel")
	local caC = Instance.new("UICorner") caC.CornerRadius = UDim.new(0, 8) caC.Parent = contentArea

	local pageTitle = Instance.new("TextLabel")
	pageTitle.Size = UDim2.new(1, -16, 0, 22)
	pageTitle.Position = UDim2.new(0, 12, 0, 6)
	pageTitle.BackgroundTransparency = 1
	pageTitle.Text = "Info"
	pageTitle.TextColor3 = THEMES[currentTheme].text
	pageTitle.TextSize = 13
	pageTitle.TextXAlignment = Enum.TextXAlignment.Left
	pageTitle.Font = Enum.Font.GothamBold
	pageTitle.Parent = contentArea
	pageTitle.ZIndex = 12
	registerThemeTarget(pageTitle, "text")

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -16, 1, -36)
	scroll.Position = UDim2.new(0, 8, 0, 32)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = THEMES[currentTheme].textDim
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = contentArea
	scroll.ZIndex = 11

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 6)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = scroll

	-- Вкладки
	local tabs = {}
	local activeTab = nil
	local tabButtons = {}

	local function switchTab(name)
		for n, data in pairs(tabs) do
			if n == name then
				data.btn.BackgroundColor3 = THEMES[currentTheme].accent
				data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				data.page.Visible = true
			else
				data.btn.BackgroundColor3 = THEMES[currentTheme].panel
				data.btn.TextColor3 = THEMES[currentTheme].textDim
				data.page.Visible = false
			end
		end
		pageTitle.Text = name
		activeTab = name
	end

	local function createTab(name, icon)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = THEMES[currentTheme].panel
		btn.Text = "  " .. icon .. "   " .. name
		btn.TextColor3 = THEMES[currentTheme].textDim
		btn.TextSize = 11
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.GothamMedium
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = sidebar
		btn.ZIndex = 12
		registerThemeTarget(btn, "tab")
		local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = btn

		local page = Instance.new("Frame")
		page.Size = UDim2.new(1, 0, 0, 0)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.Parent = scroll
		page.ZIndex = 11
		page.AutomaticSize = Enum.AutomaticSize.Y

		local pl = Instance.new("UIListLayout")
		pl.Padding = UDim.new(0, 6)
		pl.SortOrder = Enum.SortOrder.LayoutOrder
		pl.Parent = page

		btn.MouseEnter:Connect(function()
			if activeTab ~= name then
				btn.BackgroundColor3 = THEMES[currentTheme].buttonHover
			end
		end)
		btn.MouseLeave:Connect(function()
			if activeTab ~= name then
				btn.BackgroundColor3 = THEMES[currentTheme].panel
			end
		end)
		btn.MouseButton1Click:Connect(function() switchTab(name) end)

		tabs[name] = {btn = btn, page = page}
		table.insert(tabButtons, {btn = btn, name = name})
		return page
	end

	local infoPage = createTab("Info", "ℹ")
	local farmingPage = createTab("Farming", "🌾")
	local movementPage = createTab("Movement", "🏃")
	local playersPage = createTab("Players", "👥")
	local combatPage = createTab("Combat", "⚔")
	local themePage = createTab("Theme", "🎨")
	local miscPage = createTab("Misc", "⚙")

	-- ===== Компоненты =====

	local function createSection(parent, text, collapsible)
		local wrapper = Instance.new("Frame")
		wrapper.Size = UDim2.new(1, 0, 0, 0)
		wrapper.BackgroundTransparency = 1
		wrapper.Parent = parent
		wrapper.ZIndex = 11
		wrapper.AutomaticSize = Enum.AutomaticSize.Y

		local wrapperLayout = Instance.new("UIListLayout")
		wrapperLayout.FillDirection = Enum.FillDirection.Vertical
		wrapperLayout.SortOrder = Enum.SortOrder.LayoutOrder
		wrapperLayout.Padding = UDim.new(0, 4)
		wrapperLayout.Parent = wrapper

		local header = Instance.new("TextButton")
		header.Size = UDim2.new(1, 0, 0, 26)
		header.BackgroundColor3 = THEMES[currentTheme].header
		header.Text = "  " .. text .. (collapsible and "  ▼" or "")
		header.TextColor3 = THEMES[currentTheme].headerText
		header.TextSize = 10
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Font = Enum.Font.GothamBold
		header.BorderSizePixel = 0
		header.AutoButtonColor = false
		header.LayoutOrder = 1
		header.Parent = wrapper
		header.ZIndex = 12
		registerThemeTarget(header, "header")
		local hc = Instance.new("UICorner") hc.CornerRadius = UDim.new(0, 6) hc.Parent = header

		local body = Instance.new("Frame")
		body.Size = UDim2.new(1, 0, 0, 0)
		body.BackgroundTransparency = 1
		body.LayoutOrder = 2
		body.Parent = wrapper
		body.ZIndex = 11
		body.AutomaticSize = Enum.AutomaticSize.Y

		local bodyLayout = Instance.new("UIListLayout")
		bodyLayout.Padding = UDim.new(0, 4)
		bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
		bodyLayout.Parent = body

		local collapsed = false
		if collapsible then
			header.MouseButton1Click:Connect(function()
				collapsed = not collapsed
				header.Text = "  " .. text .. (collapsed and "  ▶" or "  ▼")
				body.Visible = not collapsed
			end)
		end

		return body
	end

	local function createActionBtn(parent, text, markerColor)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 34)
		btn.BackgroundColor3 = THEMES[currentTheme].button
		btn.Text = "    " .. text
		btn.TextColor3 = THEMES[currentTheme].text
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.Gotham
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = parent
		btn.ZIndex = 12
		registerThemeTarget(btn, "buttonText")
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn

		local marker = Instance.new("Frame")
		marker.Size = UDim2.new(0, 3, 0, 14)
		marker.Position = UDim2.new(0, 8, 0.5, -7)
		marker.BackgroundColor3 = markerColor
		marker.BorderSizePixel = 0
		marker.Parent = btn
		marker.ZIndex = 13
		local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(1, 0) mc.Parent = marker

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = THEMES[currentTheme].buttonHover}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = THEMES[currentTheme].button}):Play()
		end)
		return btn
	end

	local function createToggle(parent, text, initialState, callback)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = THEMES[currentTheme].button
		row.BorderSizePixel = 0
		row.Parent = parent
		row.ZIndex = 12
		registerThemeTarget(row, "button")
		local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 6) rc.Parent = row

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -70, 1, 0)
		label.Position = UDim2.new(0, 14, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = THEMES[currentTheme].text
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.Gotham
		label.Parent = row
		label.ZIndex = 13
		registerThemeTarget(label, "text")

		local switchBg = Instance.new("TextButton")
		switchBg.Size = UDim2.new(0, 40, 0, 20)
		switchBg.Position = UDim2.new(1, -52, 0.5, -10)
		switchBg.BackgroundColor3 = initialState and THEMES[currentTheme].accent or Color3.fromRGB(60, 60, 72)
		switchBg.Text = ""
		switchBg.BorderSizePixel = 0
		switchBg.AutoButtonColor = false
		switchBg.Parent = row
		switchBg.ZIndex = 13
		local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(1, 0) sbc.Parent = switchBg

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 16, 0, 16)
		knob.Position = initialState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.Parent = switchBg
		knob.ZIndex = 14
		local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1, 0) kc.Parent = knob

		local state = initialState
		local function refresh()
			if state then
				TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = THEMES[currentTheme].accent}):Play()
				TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
			else
				TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 72)}):Play()
				TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
			end
		end

		switchBg.MouseButton1Click:Connect(function()
			state = not state
			refresh()
			if callback then callback(state) end
		end)

		toggleRefs[row] = {
			getState = function() return state end,
			setState = function(v) state = v; refresh() end,
		}
		return row
	end

	local function createSlider(parent, text, initial, minV, maxV, step, color, isFloat)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundColor3 = THEMES[currentTheme].button
		row.BorderSizePixel = 0
		row.Parent = parent
		row.ZIndex = 12
		registerThemeTarget(row, "button")
		local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 6) rc.Parent = row

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -90, 0, 18)
		label.Position = UDim2.new(0, 14, 0, 6)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = THEMES[currentTheme].text
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.Gotham
		label.Parent = row
		label.ZIndex = 13
		registerThemeTarget(label, "text")

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0, 70, 0, 18)
		valLbl.Position = UDim2.new(1, -84, 0, 6)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = isFloat and string.format("%.2f", initial) or tostring(initial)
		valLbl.TextColor3 = color
		valLbl.TextSize = 12
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.Font = Enum.Font.GothamBold
		valLbl.Parent = row
		valLbl.ZIndex = 13
		registerThemeTarget(valLbl, "sliderColor")

		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(1, -28, 0, 6)
		barBg.Position = UDim2.new(0, 14, 0, 30)
		barBg.BackgroundColor3 = THEMES[currentTheme].barBg
		barBg.BorderSizePixel = 0
		barBg.Parent = row
		barBg.ZIndex = 13
		registerThemeTarget(barBg, "barBg")
		local bbc = Instance.new("UICorner") bbc.CornerRadius = UDim.new(1, 0) bbc.Parent = barBg

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(0.5, 0, 1, 0)
		barFill.BackgroundColor3 = color
		barFill.BorderSizePixel = 0
		barFill.Parent = barBg
		barFill.ZIndex = 14
		registerThemeTarget(barFill, "sliderColor")
		local bfc = Instance.new("UICorner") bfc.CornerRadius = UDim.new(1, 0) bfc.Parent = barFill

		local minusBtn = Instance.new("TextButton")
		minusBtn.Size = UDim2.new(0, 26, 0, 18)
		minusBtn.Position = UDim2.new(0, 14, 0, 40)
		minusBtn.BackgroundColor3 = THEMES[currentTheme].header
		minusBtn.Text = "−"
		minusBtn.TextColor3 = THEMES[currentTheme].text
		minusBtn.TextSize = 13
		minusBtn.Font = Enum.Font.GothamBold
		minusBtn.BorderSizePixel = 0
		minusBtn.Parent = row
		minusBtn.ZIndex = 13
		registerThemeTarget(minusBtn, "buttonText")
		local mbc = Instance.new("UICorner") mbc.CornerRadius = UDim.new(0, 4) mbc.Parent = minusBtn

		local plusBtn = Instance.new("TextButton")
		plusBtn.Size = UDim2.new(0, 26, 0, 18)
		plusBtn.Position = UDim2.new(0, 44, 0, 40)
		plusBtn.BackgroundColor3 = THEMES[currentTheme].header
		plusBtn.Text = "+"
		plusBtn.TextColor3 = THEMES[currentTheme].text
		plusBtn.TextSize = 13
		plusBtn.Font = Enum.Font.GothamBold
		plusBtn.BorderSizePixel = 0
		plusBtn.Parent = row
		plusBtn.ZIndex = 13
		registerThemeTarget(plusBtn, "buttonText")
		local pbc = Instance.new("UICorner") pbc.CornerRadius = UDim.new(0, 4) pbc.Parent = plusBtn

		local value = initial
		local function refresh()
			valLbl.Text = isFloat and string.format("%.2f", value) or tostring(value)
			local ratio = math.clamp((value - minV) / (maxV - minV), 0, 1)
			TweenService:Create(barFill, TweenInfo.new(0.15), {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
		end
		refresh()

		plusBtn.MouseButton1Click:Connect(function()
			value = math.clamp(value + step, minV, maxV)
			refresh()
			if sliderRefs[row] and sliderRefs[row].onChanged then sliderRefs[row].onChanged(value) end
		end)
		minusBtn.MouseButton1Click:Connect(function()
			value = math.clamp(value - step, minV, maxV)
			refresh()
			if sliderRefs[row] and sliderRefs[row].onChanged then sliderRefs[row].onChanged(value) end
		end)

		sliderRefs[row] = {
			getValue = function() return value end,
			setValue = function(v) value = math.clamp(v, minV, maxV); refresh() end,
			onChanged = nil,
		}
		return row
	end

	local function createBindRow(parent, title, getKeyFn, setKeyFn, presetList)
		local wrapper = Instance.new("Frame")
		wrapper.Size = UDim2.new(1, 0, 0, 76)
		wrapper.BackgroundColor3 = THEMES[currentTheme].button
		wrapper.BorderSizePixel = 0
		wrapper.Parent = parent
		wrapper.ZIndex = 12
		registerThemeTarget(wrapper, "button")
		local wc = Instance.new("UICorner") wc.CornerRadius = UDim.new(0, 6) wc.Parent = wrapper

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -20, 0, 20)
		lbl.Position = UDim2.new(0, 14, 0, 4)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = THEMES[currentTheme].text
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Font = Enum.Font.Gotham
		lbl.Parent = wrapper
		lbl.ZIndex = 13
		registerThemeTarget(lbl, "text")

		local btnRow = Instance.new("Frame")
		btnRow.Size = UDim2.new(1, -20, 0, 32)
		btnRow.Position = UDim2.new(0, 10, 0, 30)
		btnRow.BackgroundTransparency = 1
		btnRow.Parent = wrapper
		btnRow.ZIndex = 13

		local btnLayout = Instance.new("UIListLayout")
		btnLayout.FillDirection = Enum.FillDirection.Horizontal
		btnLayout.Padding = UDim.new(0, 4)
		btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		btnLayout.Parent = btnRow

		local buttons = {}
		local function refresh()
			for _, data in ipairs(buttons) do
				if data.name == getKeyFn() then
					data.btn.BackgroundColor3 = THEMES[currentTheme].accent
					data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					data.btn.BackgroundColor3 = THEMES[currentTheme].header
					data.btn.TextColor3 = THEMES[currentTheme].text
				end
			end
		end

		for _, preset in ipairs(presetList) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, 30, 0, 30)
			b.BackgroundColor3 = THEMES[currentTheme].header
			b.Text = preset.name
			b.TextColor3 = THEMES[currentTheme].text
			b.TextSize = 12
			b.Font = Enum.Font.GothamBold
			b.BorderSizePixel = 0
			b.AutoButtonColor = false
			b.Parent = btnRow
			b.ZIndex = 14
			registerThemeTarget(b, "buttonText")
			local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = b

			b.MouseButton1Click:Connect(function()
				setKeyFn(preset.key, preset.name)
				refresh()
			end)
			table.insert(buttons, {btn = b, name = preset.name})
		end

		refresh()
		return wrapper
	end

	function getCharacterParts()
		local char = player.Character
		if not char then return nil, nil, nil end
		return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
	end

	local function getSortedPlayers()
		local _, myHrp = getCharacterParts()
		local myPos = myHrp and myHrp.Position or Vector3.zero
		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local dist = hrp and (hrp.Position - myPos).Magnitude or math.huge
				table.insert(list, {player = plr, distance = dist})
			end
		end
		table.sort(list, function(a, b) return a.distance < b.distance end)
		return list
	end

	local function isSameTeam(plr)
		if not plr then return false end
		if not plr.Team or not player.Team then
			if plr.TeamColor and player.TeamColor and plr.TeamColor == player.TeamColor then
				return true
			end
			return false
		end
		return plr.Team == player.Team or plr.TeamColor == player.TeamColor
	end

	-- ============================================================
	-- INFO
	-- ============================================================
	local infoSection = createSection(infoPage, "📖  О СКРИПТЕ", false)

	local infoTitle = Instance.new("TextLabel")
	infoTitle.Size = UDim2.new(1, 0, 0, 50)
	infoTitle.BackgroundColor3 = THEMES[currentTheme].accent
	infoTitle.Text = "   Script by tt: swapper.sk"
	infoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoTitle.TextSize = 16
	infoTitle.TextXAlignment = Enum.TextXAlignment.Left
	infoTitle.Font = Enum.Font.GothamBold
	infoTitle.BorderSizePixel = 0
	infoTitle.Parent = infoSection
	infoTitle.ZIndex = 12
	local itC = Instance.new("UICorner") itC.CornerRadius = UDim.new(0, 8) itC.Parent = infoTitle

	local infoTg = Instance.new("TextLabel")
	infoTg.Size = UDim2.new(1, 0, 0, 32)
	infoTg.BackgroundColor3 = THEMES[currentTheme].button
	infoTg.Text = "   TG: @ZearDLC"
	infoTg.TextColor3 = THEMES[currentTheme].info
	infoTg.TextSize = 14
	infoTg.TextXAlignment = Enum.TextXAlignment.Left
	infoTg.Font = Enum.Font.GothamBold
	infoTg.BorderSizePixel = 0
	infoTg.Parent = infoSection
	infoTg.ZIndex = 12
	registerThemeTarget(infoTg, "button")
	local itgC = Instance.new("UICorner") itgC.CornerRadius = UDim.new(0, 8) itgC.Parent = infoTg

	local socialsFrame = Instance.new("Frame")
	socialsFrame.Size = UDim2.new(1, 0, 0, 70)
	socialsFrame.BackgroundColor3 = THEMES[currentTheme].button
	socialsFrame.BorderSizePixel = 0
	socialsFrame.Parent = infoSection
	socialsFrame.ZIndex = 12
	registerThemeTarget(socialsFrame, "button")
	local sfC = Instance.new("UICorner") sfC.CornerRadius = UDim.new(0, 8) sfC.Parent = socialsFrame

	local socialsLayout = Instance.new("UIListLayout")
	socialsLayout.FillDirection = Enum.FillDirection.Horizontal
	socialsLayout.Padding = UDim.new(0, 10)
	socialsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	socialsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	socialsLayout.Parent = socialsFrame

	local tgIcon = Instance.new("TextButton")
	tgIcon.Size = UDim2.new(0, 50, 0, 50)
	tgIcon.BackgroundColor3 = Color3.fromRGB(40, 160, 220)
	tgIcon.Text = "✈"
	tgIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	tgIcon.TextSize = 26
	tgIcon.Font = Enum.Font.GothamBold
	tgIcon.BorderSizePixel = 0
	tgIcon.AutoButtonColor = false
	tgIcon.Parent = socialsFrame
	tgIcon.ZIndex = 13
	local tgiC = Instance.new("UICorner") tgiC.CornerRadius = UDim.new(1, 0) tgiC.Parent = tgIcon

	tgIcon.MouseButton1Click:Connect(function()
		print("[VIPMenu] Telegram: https://t.me/ZearDLC")
		tgIcon.Text = "✓"
		task.wait(1)
		tgIcon.Text = "✈"
	end)

	local ttIcon = Instance.new("TextButton")
	ttIcon.Size = UDim2.new(0, 50, 0, 50)
	ttIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	ttIcon.Text = "♪"
	ttIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	ttIcon.TextSize = 28
	ttIcon.Font = Enum.Font.GothamBold
	ttIcon.BorderSizePixel = 0
	ttIcon.AutoButtonColor = false
	ttIcon.Parent = socialsFrame
	ttIcon.ZIndex = 13
	local ttiC = Instance.new("UICorner") ttiC.CornerRadius = UDim.new(1, 0) ttiC.Parent = ttIcon

	local ttStroke = Instance.new("UIStroke")
	ttStroke.Color = Color3.fromRGB(255, 60, 100)
	ttStroke.Thickness = 2
	ttStroke.Parent = ttIcon

	ttIcon.MouseButton1Click:Connect(function()
		print("[VIPMenu] TikTok: https://tiktok.com/@swapper.sk")
		ttIcon.Text = "✓"
		task.wait(1)
		ttIcon.Text = "♪"
	end)

	local infoFunctions = createSection(infoPage, "📚  ФУНКЦИИ", false)

	local function addInfoLine(title, desc)
		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 46)
		line.BackgroundColor3 = THEMES[currentTheme].button
		line.BorderSizePixel = 0
		line.Parent = infoFunctions
		line.ZIndex = 12
		registerThemeTarget(line, "button")
		local lC = Instance.new("UICorner") lC.CornerRadius = UDim.new(0, 6) lC.Parent = line

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -16, 0, 20)
		t.Position = UDim2.new(0, 12, 0, 4)
		t.BackgroundTransparency = 1
		t.Text = title
		t.TextColor3 = THEMES[currentTheme].info
		t.TextSize = 12
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Font = Enum.Font.GothamBold
		t.Parent = line
		t.ZIndex = 13

		local d = Instance.new("TextLabel")
		d.Size = UDim2.new(1, -16, 0, 20)
		d.Position = UDim2.new(0, 12, 0, 24)
		d.BackgroundTransparency = 1
		d.Text = desc
		d.TextColor3 = THEMES[currentTheme].textDim
		d.TextSize = 10
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.Font = Enum.Font.Gotham
		d.TextWrapped = true
		d.Parent = line
		d.ZIndex = 13

		return line
	end

	addInfoLine("🌾  Farming", "Плавный и моментальный телепорт.")
	addInfoLine("🏃  Movement", "Fly, WalkSpeed, JumpPower.")
	addInfoLine("👥  Players", "Auto-TP к ближайшему по бинду.")
	addInfoLine("⚔  Combat — Aimbot", "Aim lock по зажатию бинда.")
	addInfoLine("⚔  Combat — Triggerbot", "Авто-выстрел когда перед тобой враг.")
	addInfoLine("⚔  Combat — Magnet All", "Собирает всех игроков перед тобой.")
	addInfoLine("🎨  Theme", "5 тем, 3 стиля.")
	addInfoLine("💾  Config", "C:\\" .. CONFIG_FOLDER .. "\\" .. CONFIG_FILE)

	-- ============================================================
	-- FARMING
	-- ============================================================
	local farmingTP = createSection(farmingPage, "TELEPORT", true)
	local saveBtn = createActionBtn(farmingTP, "📌  Запомнить координаты", Color3.fromRGB(80, 130, 230))
	local tpBtn = createActionBtn(farmingTP, "🚀  Телепорт", Color3.fromRGB(80, 200, 130))
	local backBtn = createActionBtn(farmingTP, "↩  Вернуться", Color3.fromRGB(230, 100, 80))

	local farmingInstant = createSection(farmingPage, "INSTANT", true)
	local instantSaveBtn = createActionBtn(farmingInstant, "📌  Запомнить (Instant)", Color3.fromRGB(80, 130, 230))
	local instantTpBtn = createActionBtn(farmingInstant, "⚡  Моментальный ТП", Color3.fromRGB(255, 200, 80))
	local instantBackBtn = createActionBtn(farmingInstant, "↩  Вернуться (Instant)", Color3.fromRGB(230, 120, 80))

	local farmingSpeed = createSection(farmingPage, "SPEED", true)
	local flySpeedSlider = createSlider(farmingSpeed, "🚀  Скорость полёта", flySpeed, 20, 500, 25, THEMES[currentTheme].sliderColor)
	sliderRefs[flySpeedSlider].onChanged = function(v) flySpeed = v; saveConfig() end

	-- ============================================================
	-- MOVEMENT
	-- ============================================================
	local movementPlayer = createSection(movementPage, "PLAYER", true)
	local walkSlider = createSlider(movementPlayer, "🏃  WalkSpeed", walkSpeedValue, 8, 200, 16, THEMES[currentTheme].sliderColor)
	sliderRefs[walkSlider].onChanged = function(v)
		walkSpeedValue = v
		local _, _, humanoid = getCharacterParts()
		if humanoid and not flyEnabled then humanoid.WalkSpeed = walkSpeedValue end
		saveConfig()
	end

	local jumpSlider = createSlider(movementPlayer, "🦘  JumpPower", jumpPowerValue, 0, 200, 10, THEMES[currentTheme].sliderColor)
	sliderRefs[jumpSlider].onChanged = function(v)
		jumpPowerValue = v
		local _, _, humanoid = getCharacterParts()
		if humanoid and not flyEnabled then humanoid.JumpPower = jumpPowerValue end
		saveConfig()
	end

	local movementFly = createSection(movementPage, "🚀  FLY", true)
	local flyToggle = createToggle(movementFly, "🚀  Fly", false, function(state)
		flyEnabled = state
		if not state then
			if flyConn then flyConn:Disconnect() flyConn = nil end
			local _, hrp, humanoid = getCharacterParts()
			if humanoid then
				humanoid.PlatformStand = false
				humanoid.WalkSpeed = walkSpeedValue
				humanoid.JumpPower = jumpPowerValue
			end
			if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
		end
	end)

	local flyFreeSpeedSlider = createSlider(movementFly, "🚀  Скорость Fly", flyFreeSpeed, 20, 300, 20, THEMES[currentTheme].sliderColor)
	sliderRefs[flyFreeSpeedSlider].onChanged = function(v) flyFreeSpeed = v; saveConfig() end

	-- ============================================================
	-- PLAYERS
	-- ============================================================
	local playersAuto = createSection(playersPage, "⚡  AUTO-TP", true)

	local autoTpToggle = createToggle(playersAuto, "⚡  Auto-TP (зажми бинд)", autoTpEnabled, function(state)
		autoTpEnabled = state
		saveConfig()
	end)

	local autoTpAboveToggle = createToggle(playersAuto, "⬆  Телепорт ВВЕРХ", autoTpAbove, function(state)
		autoTpAbove = state
		saveConfig()
	end)

	local autoTpBindRow = createBindRow(
		playersAuto,
		"Клавиша Auto-TP:",
		function() return autoTpKeyName end,
		function(key, name)
			autoTpKey = key
			autoTpKeyName = name
			saveConfig()
		end,
		{
			{key = Enum.KeyCode.E, name = "E"},
			{key = Enum.KeyCode.Q, name = "Q"},
			{key = Enum.KeyCode.G, name = "G"},
			{key = Enum.KeyCode.R, name = "R"},
			{key = Enum.KeyCode.F, name = "F"},
			{key = Enum.KeyCode.T, name = "T"},
			{key = Enum.KeyCode.X, name = "X"},
			{key = Enum.KeyCode.C, name = "C"},
		}
	)

	local playersList = createSection(playersPage, "👥  ИГРОКИ", true)

	local playersListFrame = Instance.new("Frame")
	playersListFrame.Size = UDim2.new(1, 0, 0, 220)
	playersListFrame.BackgroundColor3 = THEMES[currentTheme].button
	playersListFrame.BorderSizePixel = 0
	playersListFrame.Parent = playersList
	playersListFrame.ZIndex = 12
	registerThemeTarget(playersListFrame, "button")
	local plfC = Instance.new("UICorner") plfC.CornerRadius = UDim.new(0, 6) plfC.Parent = playersListFrame

	local playersListScroll = Instance.new("ScrollingFrame")
	playersListScroll.Size = UDim2.new(1, -8, 1, -8)
	playersListScroll.Position = UDim2.new(0, 4, 0, 4)
	playersListScroll.BackgroundTransparency = 1
	playersListScroll.BorderSizePixel = 0
	playersListScroll.ScrollBarThickness = 4
	playersListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	playersListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playersListScroll.Parent = playersListFrame
	playersListScroll.ZIndex = 13

	local playersListLayout = Instance.new("UIListLayout")
	playersListLayout.Padding = UDim.new(0, 4)
	playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playersListLayout.Parent = playersListScroll

	local playerRows = {}

	local function refreshPlayersList()
		for _, row in ipairs(playerRows) do row:Destroy() end
		playerRows = {}

		local sorted = getSortedPlayers()
		for i, entry in ipairs(sorted) do
			local plr = entry.player
			local distance = entry.distance
			local isNearest = (i == 1)

			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, -4, 0, 36)
			row.BackgroundColor3 = isNearest and THEMES[currentTheme].accent or THEMES[currentTheme].header
			row.Text = ""
			row.BorderSizePixel = 0
			row.AutoButtonColor = false
			row.Parent = playersListScroll
			row.ZIndex = 13
			local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 6) rc.Parent = row

			local avatar = Instance.new("ImageLabel")
			avatar.Size = UDim2.new(0, 28, 0, 28)
			avatar.Position = UDim2.new(0, 6, 0.5, -14)
			avatar.BackgroundColor3 = THEMES[currentTheme].header
			avatar.BorderSizePixel = 0
			avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48"
			avatar.Parent = row
			avatar.ZIndex = 14
			local ac = Instance.new("UICorner") ac.CornerRadius = UDim.new(1, 0) ac.Parent = avatar

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(1, -140, 1, 0)
			nameLbl.Position = UDim2.new(0, 42, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = (isNearest and "★ " or "") .. plr.Name
			nameLbl.TextColor3 = isNearest and Color3.fromRGB(255, 220, 120) or THEMES[currentTheme].text
			nameLbl.TextSize = 12
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Font = Enum.Font.Gotham
			nameLbl.Parent = row
			nameLbl.ZIndex = 14

			local distLbl = Instance.new("TextLabel")
			distLbl.Size = UDim2.new(0, 70, 1, 0)
			distLbl.Position = UDim2.new(1, -108, 0, 0)
			distLbl.BackgroundTransparency = 1
			distLbl.Text = string.format("%.0f studs", distance)
			distLbl.TextColor3 = THEMES[currentTheme].info
			distLbl.TextSize = 10
			distLbl.TextXAlignment = Enum.TextXAlignment.Right
			distLbl.Font = Enum.Font.GothamBold
			distLbl.Parent = row
			distLbl.ZIndex = 14

			row.MouseButton1Click:Connect(function()
				startMagnet(plr)
			end)

			table.insert(playerRows, row)
		end
	end

	-- ============================================================
	-- COMBAT
	-- ============================================================
	local combatAim = createSection(combatPage, "🎯  AIMBOT", true)

	local aimbotToggle = createToggle(combatAim, "🎯  Aimbot (зажми бинд)", aimbotEnabled, function(state)
		aimbotEnabled = state
		saveConfig()
	end)

	local combatSettings = createSection(combatPage, "⚙  НАСТРОЙКИ AIMBOT", true)

	local aimbotSmoothSlider = createSlider(combatSettings, "🎯  Плавность", aimbotSmoothness, 0, 1, 0.05, THEMES[currentTheme].sliderColor, true)
	sliderRefs[aimbotSmoothSlider].onChanged = function(v) aimbotSmoothness = v; saveConfig() end

	local aimbotRangeSlider = createSlider(combatSettings, "📏  Дальность", aimbotRange, 30, 1000, 30, THEMES[currentTheme].sliderColor)
	sliderRefs[aimbotRangeSlider].onChanged = function(v) aimbotRange = v; saveConfig() end

	local aimbotTeamToggle = createToggle(combatSettings, "👥  Игнорировать своих", aimbotTeamCheck, function(state)
		aimbotTeamCheck = state
		saveConfig()
	end)

	local aimbotVisibleToggle = createToggle(combatSettings, "👁  Только видимые", aimbotVisibleCheck, function(state)
		aimbotVisibleCheck = state
		saveConfig()
	end)

	local aimbotBindRow = createBindRow(
		combatSettings,
		"Клавиша Aimbot:",
		function() return aimbotKeyName end,
		function(key, name)
			aimbotKey = key
			aimbotKeyName = name
			saveConfig()
		end,
		{
			{key = Enum.KeyCode.Q, name = "Q"},
			{key = Enum.KeyCode.E, name = "E"},
			{key = Enum.KeyCode.R, name = "R"},
			{key = Enum.KeyCode.F, name = "F"},
			{key = Enum.KeyCode.G, name = "G"},
			{key = Enum.KeyCode.T, name = "T"},
			{key = Enum.KeyCode.X, name = "X"},
			{key = Enum.KeyCode.C, name = "C"},
		}
	)

	local combatTrigger = createSection(combatPage, "🔫  TRIGGERBOT", true)

	local triggerbotToggle = createToggle(combatTrigger, "🔫  Triggerbot", triggerbotEnabled, function(state)
		triggerbotEnabled = state
		saveConfig()
	end)

	local triggerbotRangeSlider = createSlider(combatTrigger, "📏  Радиус", triggerbotRange, 10, 200, 5, THEMES[currentTheme].sliderColor)
	sliderRefs[triggerbotRangeSlider].onChanged = function(v) triggerbotRange = v; saveConfig() end

	local triggerbotDelaySlider = createSlider(combatTrigger, "⏱  Задержка", triggerbotDelay, 0.05, 1, 0.05, THEMES[currentTheme].sliderColor, true)
	sliderRefs[triggerbotDelaySlider].onChanged = function(v) triggerbotDelay = v; saveConfig() end

	local combatMagnetAll = createSection(combatPage, "🌀  MAGNET ALL", true)

	local magnetAllToggle = createToggle(combatMagnetAll, "🌀  Magnet All", false, function(state)
		magnetAllEnabled = state
		if state then
			startMagnetAll()
		else
			stopMagnetAll()
		end
	end)

	local magnetAllOffsetSlider = createSlider(combatMagnetAll, "📍  Вперёд", magnetAllForwardOffset, 3, 60, 2, THEMES[currentTheme].sliderColor)
	sliderRefs[magnetAllOffsetSlider].onChanged = function(v) magnetAllForwardOffset = v; saveConfig() end

	local magnetAllRadiusSlider = createSlider(combatMagnetAll, "📏  Радиус", magnetAllRadius, 10, 500, 10, THEMES[currentTheme].sliderColor)
	sliderRefs[magnetAllRadiusSlider].onChanged = function(v) magnetAllRadius = v; saveConfig() end

	local magnetAllDurationSlider = createSlider(combatMagnetAll, "⏱  Длительность (0=∞)", magnetAllHoldTime, 0, 60, 2, THEMES[currentTheme].sliderColor)
	sliderRefs[magnetAllDurationSlider].onChanged = function(v) magnetAllHoldTime = v; saveConfig() end

	-- ============================================================
	-- THEME
	-- ============================================================
	local themeSection = createSection(themePage, "🎨  ЦВЕТОВАЯ ТЕМА", false)

	local themeHint = Instance.new("TextLabel")
	themeHint.Size = UDim2.new(1, 0, 0, 24)
	themeHint.BackgroundColor3 = THEMES[currentTheme].button
	themeHint.Text = "   Выбери тему:"
	themeHint.TextColor3 = THEMES[currentTheme].text
	themeHint.TextSize = 11
	themeHint.TextXAlignment = Enum.TextXAlignment.Left
	themeHint.Font = Enum.Font.Gotham
	themeHint.BorderSizePixel = 0
	themeHint.Parent = themeSection
	themeHint.ZIndex = 12
	registerThemeTarget(themeHint, "button")
	local thc = Instance.new("UICorner") thc.CornerRadius = UDim.new(0, 6) thc.Parent = themeHint

	local themeButtonRefs = {}

	local function applyTheme(themeName)
		local t = THEMES[themeName]
		if not t then return end
		currentTheme = themeName

		for _, ref in ipairs(themeTargets) do
			local obj = ref.obj
			if obj and obj.Parent then
				local role = ref.role
				if role == "bg" then obj.BackgroundColor3 = t.bg
				elseif role == "panel" then obj.BackgroundColor3 = t.panel
				elseif role == "topBar" then obj.BackgroundColor3 = t.topBar
				elseif role == "button" then obj.BackgroundColor3 = t.button
				elseif role == "header" then
					obj.BackgroundColor3 = t.header
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextColor3 = t.headerText end
				elseif role == "text" then
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextColor3 = t.text end
				elseif role == "textDim" then
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextColor3 = t.textDim end
				elseif role == "barBg" then obj.BackgroundColor3 = t.barBg
				elseif role == "accent" then obj.BackgroundColor3 = t.accent
				elseif role == "buttonText" then
					obj.BackgroundColor3 = t.button
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextColor3 = t.text end
				elseif role == "info" then
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextColor3 = t.info end
				elseif role == "sliderColor" then
					obj.BackgroundColor3 = t.sliderColor
					if obj:IsA("TextLabel") then obj.TextColor3 = t.sliderColor end
				elseif role == "tab" then
					if activeTab and tabs[activeTab] and tabs[activeTab].btn == obj then
						obj.BackgroundColor3 = t.accent
						obj.TextColor3 = Color3.fromRGB(255, 255, 255)
					else
						obj.BackgroundColor3 = t.panel
						obj.TextColor3 = t.textDim
					end
				end
			end
		end

		windowStroke.Color = t.stroke
		scroll.ScrollBarImageColor3 = t.textDim

		for _, data in ipairs(tabButtons) do
			if activeTab and tabs[activeTab] and tabs[activeTab].btn == data.btn then
				data.btn.BackgroundColor3 = t.accent
				data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				data.btn.BackgroundColor3 = t.panel
				data.btn.TextColor3 = t.textDim
			end
		end

		saveConfig()
	end

	local function applyStyle(styleName)
		local s = STYLES[styleName]
		if not s then return end
		currentStyle = styleName

		windowCorner.CornerRadius = UDim.new(0, s.cornerRadius)
		topBarCorner.CornerRadius = UDim.new(0, s.cornerRadius)
		sbC.CornerRadius = UDim.new(0, math.max(0, s.cornerRadius - 2))
		caC.CornerRadius = UDim.new(0, math.max(0, s.cornerRadius - 2))
		windowStroke.Thickness = s.strokeThickness

		topBar.Size = UDim2.new(1, 0, 0, s.topBarHeight)
		topBarCover.Size = UDim2.new(1, 0, 0, s.cornerRadius)
		topBarCover.Position = UDim2.new(0, 0, 1, -s.cornerRadius)

		sidebar.Size = UDim2.new(0, s.sidebarWidth, 1, -(s.topBarHeight + 12))
		sidebar.Position = UDim2.new(0, s.padding, 0, s.topBarHeight + 6)

		contentArea.Size = UDim2.new(1, -(s.sidebarWidth + 24), 1, -(s.topBarHeight + 22))
		contentArea.Position = UDim2.new(0, s.sidebarWidth + s.padding + 8, 0, s.topBarHeight + 12)

		saveConfig()
	end

	local themePresets = {
		{name = "Тёмная", color = Color3.fromRGB(30, 30, 40)},
		{name = "Белая", color = Color3.fromRGB(245, 245, 250)},
		{name = "Космос", color = Color3.fromRGB(40, 20, 100)},
		{name = "Снежная", color = Color3.fromRGB(210, 230, 245)},
		{name = "Осенняя", color = Color3.fromRGB(120, 60, 30)},
	}

	local themeGrid = Instance.new("Frame")
	themeGrid.Size = UDim2.new(1, 0, 0, 130)
	themeGrid.BackgroundTransparency = 1
	themeGrid.Parent = themeSection
	themeGrid.ZIndex = 12

	local themeGridLayout = Instance.new("UIGridLayout")
	themeGridLayout.CellSize = UDim2.new(0.32, -6, 0, 60)
	themeGridLayout.CellPadding = UDim2.new(0.01, 3, 0, 6)
	themeGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	themeGridLayout.Parent = themeGrid

	for i, preset in ipairs(themePresets) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = preset.color
		btn.Text = preset.name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = themeGrid
		btn.LayoutOrder = i
		btn.ZIndex = 13
		local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 8) bc.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 1
		stroke.Transparency = 0.7
		stroke.Parent = btn
		btn.UIStroke = stroke

		btn.MouseButton1Click:Connect(function()
			applyTheme(preset.name)
		end)

		themeButtonRefs[preset.name] = btn
	end

	local styleSection = createSection(themePage, "🖼  СТИЛЬ", false)

	local stylePresets = {
		{name = "Default", desc = "Стандартный", icon = "🎨"},
		{name = "Compact", desc = "Компактный", icon = "📐"},
		{name = "Rounded", desc = "Круглый", icon = "💠"},
	}

	local styleButtonRefs = {}

	for _, preset in ipairs(stylePresets) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 40)
		btn.BackgroundColor3 = THEMES[currentTheme].button
		btn.Text = "   " .. preset.icon .. "  " .. preset.name .. "   —   " .. preset.desc
		btn.TextColor3 = THEMES[currentTheme].text
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.Gotham
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = styleSection
		btn.ZIndex = 12
		registerThemeTarget(btn, "buttonText")
		local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = btn

		btn.MouseButton1Click:Connect(function()
			for _, b in pairs(styleButtonRefs) do
				b.btn.BackgroundColor3 = THEMES[currentTheme].button
				b.btn.TextColor3 = THEMES[currentTheme].text
				b.selected = false
			end
			btn.BackgroundColor3 = THEMES[currentTheme].accent
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			styleButtonRefs[preset.name].selected = true
			applyStyle(preset.name)
		end)

		styleButtonRefs[preset.name] = {btn = btn, selected = (preset.name == "Default")}
	end

	-- ============================================================
	-- MISC
	-- ============================================================
	local miscSection = createSection(miscPage, "SETTINGS", false)
	local unloadBtn = createActionBtn(miscSection, "✕  Unload", Color3.fromRGB(230, 80, 80))
	local saveConfigBtn = createActionBtn(miscSection, "💾  Сохранить конфиг", Color3.fromRGB(80, 180, 120))
	local loadConfigBtn = createActionBtn(miscSection, "📂  Загрузить конфиг", Color3.fromRGB(80, 130, 230))
	local resetBtn = createActionBtn(miscSection, "↺  Сбросить", Color3.fromRGB(160, 160, 200))

	-- ============================================================
	-- ЛОГИКА
	-- ============================================================
	local function applyWalkSpeed()
		local _, _, humanoid = getCharacterParts()
		if humanoid and not flyEnabled then humanoid.WalkSpeed = walkSpeedValue end
	end

	local function applyJumpPower()
		local _, _, humanoid = getCharacterParts()
		if humanoid and not flyEnabled then humanoid.JumpPower = jumpPowerValue end
	end

	local function startFlyLoop()
		if flyConn then flyConn:Disconnect() end
		flyConn = RunService.RenderStepped:Connect(function(dt)
			if unloaded or not flyEnabled then return end
			local char, hrp, humanoid = getCharacterParts()
			if not char or not hrp or not humanoid then return end
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			local camera = workspace.CurrentCamera
			if not camera then return end
			local moveDir = Vector3.zero
			local camCF = camera.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0, 1, 0) end
			if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
			hrp.AssemblyLinearVelocity = moveDir * flyFreeSpeed
		end)
	end
	startFlyLoop()

	function startMagnet(targetPlayer)
		if not targetPlayer or targetPlayer == player then return end
		magnetEnabled = true
		magnetTarget = targetPlayer

		local _, hrp, humanoid = getCharacterParts()
		if not hrp or not humanoid then return end
		humanoid.PlatformStand = true

		if magnetConn then magnetConn:Disconnect() end
		magnetConn = RunService.Heartbeat:Connect(function(dt)
			if unloaded or not magnetEnabled then return end
			if not magnetTarget then
				magnetEnabled = false
				if magnetConn then magnetConn:Disconnect() magnetConn = nil end
				return
			end
			local myChar, myHrp = getCharacterParts()
			if not myChar or not myHrp then return end
			local targetChar = magnetTarget.Character
			if not targetChar then
				magnetEnabled = false
				if magnetConn then magnetConn:Disconnect() magnetConn = nil end
				return
			end
			local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
			if not targetHrp then return end
			local targetPos = targetHrp.Position - targetHrp.CFrame.LookVector * magnetDistance + Vector3.new(0, 2, 0)
			local current = myHrp.Position
			local diff = targetPos - current
			local dist = diff.Magnitude
			if dist > 0.5 then
				local step = math.min(dist, (dist * 8 + 10) * dt)
				pcall(function()
					myHrp.CFrame = CFrame.new(current + diff.Unit * step)
				end)
			end
			myHrp.AssemblyLinearVelocity = Vector3.zero
		end)
	end

	local function doAutoTeleport()
		if unloaded then return end
		local sorted = getSortedPlayers()
		if #sorted == 0 then return end
		local nearest = sorted[1].player
		local char = nearest.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local targetPos
		if autoTpAbove then
			targetPos = hrp.Position + Vector3.new(0, 15, 0)
		else
			targetPos = hrp.Position - hrp.CFrame.LookVector * 5 + Vector3.new(0, 3, 0)
		end
		instantTeleport(targetPos)
	end

	local function startAimbotLoop()
		if aimbotConn then aimbotConn:Disconnect() end
		aimbotConn = RunService.RenderStepped:Connect(function(dt)
			if unloaded or not aimbotEnabled then return end
			if not UserInputService:IsKeyDown(aimbotKey) then return end
			local char, hrp = getCharacterParts()
			if not char or not hrp then return end
			local camera = workspace.CurrentCamera
			if not camera then return end
			local myPos = camera.CFrame.Position
			local closest = nil
			local closestDist = aimbotRange
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player then
					local skip = false
					if aimbotTeamCheck and isSameTeam(plr) then skip = true end
					if not skip then
						local targetChar = plr.Character
						if targetChar then
							local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
							local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
							if targetHrp and targetHum and targetHum.Health > 0 then
								local dist = (targetHrp.Position - myPos).Magnitude
								if dist < closestDist then
									if aimbotVisibleCheck then
										local rayParams = RaycastParams.new()
										rayParams.FilterType = Enum.RaycastFilterType.Exclude
										rayParams.FilterDescendantsInstances = {char, targetChar}
										local result = workspace:Raycast(myPos, targetHrp.Position - myPos, rayParams)
										if result then skip = true end
									end
									if not skip then
										closest = {player = plr, hrp = targetHrp, dist = dist}
										closestDist = dist
									end
								end
							end
						end
					end
				end
			end
			if closest then
				local targetPos = closest.hrp.Position
				local currentCF = camera.CFrame
				local targetCF = CFrame.new(currentCF.Position, targetPos)
				pcall(function()
					camera.CFrame = currentCF:Lerp(targetCF, 1 - aimbotSmoothness)
				end)
			end
		end)
	end
	startAimbotLoop()

	local function startTriggerbotLoop()
		if triggerbotConn then triggerbotConn:Disconnect() end
		triggerbotConn = RunService.Heartbeat:Connect(function(dt)
			if unloaded or not triggerbotEnabled then return end
			local now = os.clock()
			if now - triggerbotLastShot < triggerbotDelay then return end
			local char, hrp = getCharacterParts()
			if not char or not hrp then return end
			local camera = workspace.CurrentCamera
			if not camera then return end
			local myPos = camera.CFrame.Position
			local targetFound = false
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player then
					local targetChar = plr.Character
					if targetChar then
						local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
						local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
						if targetHrp and targetHum and targetHum.Health > 0 then
							local dist = (targetHrp.Position - myPos).Magnitude
							if dist < triggerbotRange then
								local dirToTarget = (targetHrp.Position - myPos).Unit
								local lookDir = camera.CFrame.LookVector
								local dot = dirToTarget:Dot(lookDir)
								if dot > 0.95 then targetFound = true; break end
							end
						end
					end
				end
			end
			if targetFound then
				triggerbotLastShot = now
				local tool = char:FindFirstChildOfClass("Tool")
				if tool then pcall(function() tool:Activate() end) end
			end
		end)
	end
	startTriggerbotLoop()

	local magnetAllEndTime = 0

	function startMagnetAll()
		if magnetAllConn then magnetAllConn:Disconnect() magnetAllConn = nil end
		magnetAllEndTime = (magnetAllHoldTime > 0) and (os.clock() + magnetAllHoldTime) or 0
		magnetAllConn = RunService.Heartbeat:Connect(function(dt)
			if unloaded or not magnetAllEnabled then return end
			if magnetAllEndTime > 0 and os.clock() >= magnetAllEndTime then
				magnetAllEnabled = false
				stopMagnetAll()
				return
			end
			local char, hrp = getCharacterParts()
			if not char or not hrp then return end
			local camera = workspace.CurrentCamera
			if not camera then return end
			local camCF = camera.CFrame
			local basePos = camCF.Position + camCF.LookVector * magnetAllForwardOffset
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player then
					local targetChar = plr.Character
					if targetChar then
						local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
						if targetHrp then
							local dist = (targetHrp.Position - basePos).Magnitude
							if dist < magnetAllRadius then
								local angle = (plr.UserId % 360) * math.pi / 180
								local ringRadius = 3
								local offset = Vector3.new(math.cos(angle) * ringRadius, 0, math.sin(angle) * ringRadius)
								local targetPos = basePos + offset + Vector3.new(0, 3, 0)
								local current = targetHrp.Position
								local diff = targetPos - current
								local d = diff.Magnitude
								if d > 1 then
									local step = math.min(d, (d * 6 + 8) * dt)
									pcall(function()
										targetHrp.CFrame = CFrame.new(current + diff.Unit * step)
									end)
								end
								targetHrp.AssemblyLinearVelocity = Vector3.zero
							end
						end
					end
				end
			end
		end)
	end

	function stopMagnetAll()
		magnetAllEnabled = false
		if magnetAllConn then magnetAllConn:Disconnect() magnetAllConn = nil end
	end

	local function stepFlyTo(targetPos)
		local done, cancelled = false, false
		while not done and not cancelled do
			if unloaded or teleportCancelled then cancelled = true break end
			local char, hrp, humanoid = getCharacterParts()
			if not char or not hrp or not humanoid then cancelled = true break end
			local current = hrp.Position
			local diff = targetPos - current
			local dist = diff.Magnitude
			if dist < 1 then
				hrp.CFrame = CFrame.new(targetPos)
				done = true
				break
			end
			local maxStep = math.min(flySpeed * TP_STEP_INTERVAL, TP_STEP_DISTANCE * 2)
			local step = math.min(maxStep, dist)
			hrp.CFrame = CFrame.new(current + diff.Unit * step)
			hrp.AssemblyLinearVelocity = Vector3.zero
			pcall(function()
				if humanoid.FloorMaterial == Enum.Material.Air then
					humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
				end
			end)
			task.wait(TP_STEP_INTERVAL)
		end
		return done and not cancelled
	end

	local function smoothTeleport(targetPosition)
		if isTeleporting or unloaded then return end
		isTeleporting = true
		teleportCancelled = false
		local char, hrp, humanoid = getCharacterParts()
		if not char or not hrp or not humanoid then isTeleporting = false return end
		local currentTool = char:FindFirstChildOfClass("Tool")
		humanoid.PlatformStand = true
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		local startPos = hrp.Position
		local endPos = targetPosition + Vector3.new(0, 3, 0)
		local liftPos = Vector3.new(startPos.X, startPos.Y + flyHeight, startPos.Z)
		local dropPos = Vector3.new(endPos.X, endPos.Y + flyHeight, endPos.Z)
		local function restore()
			if not flyEnabled then
				humanoid.PlatformStand = false
				humanoid.WalkSpeed = walkSpeedValue
				humanoid.JumpPower = jumpPowerValue
			end
			if currentTool then
				task.wait(0.05)
				if currentTool.Parent ~= char and currentTool.Parent ~= player:FindFirstChild("Backpack") then
					currentTool.Parent = player:FindFirstChild("Backpack") or char
				end
				humanoid:UnequipTools()
				task.wait(0.05)
				humanoid:EquipTool(currentTool)
			end
			isTeleporting = false
		end
		if not stepFlyTo(liftPos) then restore() return end
		if not stepFlyTo(dropPos) then restore() return end
		if not stepFlyTo(endPos) then restore() return end
		task.wait(0.3)
		restore()
	end

	function instantTeleport(targetPosition)
		if unloaded then return end
		local char, hrp, humanoid = getCharacterParts()
		if not char or not hrp or not humanoid then return end
		pcall(function()
			hrp.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
			hrp.AssemblyLinearVelocity = Vector3.zero
		end)
	end

	-- ============================================================
	-- КНОПКИ
	-- ============================================================
	table.insert(connections, saveBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		local _, hrp = getCharacterParts()
		if not hrp then return end
		savedPosition = hrp.Position
	end))

	table.insert(connections, tpBtn.MouseButton1Click:Connect(function()
		if unloaded or isTeleporting then return end
		if not savedPosition then return end
		local _, hrp = getCharacterParts()
		if not hrp then return end
		positionBeforeTeleport = hrp.Position
		smoothTeleport(savedPosition)
	end))

	table.insert(connections, backBtn.MouseButton1Click:Connect(function()
		if unloaded or isTeleporting then return end
		if not positionBeforeTeleport then return end
		local _, hrp = getCharacterParts()
		if not hrp then return end
		local temp = hrp.Position
		smoothTeleport(positionBeforeTeleport)
		positionBeforeTeleport = temp
	end))

	table.insert(connections, instantSaveBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		local _, hrp = getCharacterParts()
		if not hrp then return end
		savedPosition = hrp.Position
	end))

	table.insert(connections, instantTpBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		if not savedPosition then return end
		local _, hrp = getCharacterParts()
		if not hrp then return end
		positionBeforeTeleport = hrp.Position
		instantTeleport(savedPosition)
	end))

	table.insert(connections, instantBackBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		if not positionBeforeTeleport then return end
		local _, hrp = getCharacterParts()
		if not hrp then return end
		local temp = hrp.Position
		instantTeleport(positionBeforeTeleport)
		positionBeforeTeleport = temp
	end))

	table.insert(connections, saveConfigBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		saveConfig()
	end))

	table.insert(connections, loadConfigBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		loadConfig()
		applyTheme(currentTheme)
		applyStyle(currentStyle)
		if sliderRefs[walkSlider] then sliderRefs[walkSlider].setValue(walkSpeedValue) end
		if sliderRefs[jumpSlider] then sliderRefs[jumpSlider].setValue(jumpPowerValue) end
		if sliderRefs[flySpeedSlider] then sliderRefs[flySpeedSlider].setValue(flySpeed) end
		if sliderRefs[flyFreeSpeedSlider] then sliderRefs[flyFreeSpeedSlider].setValue(flyFreeSpeed) end
	end))

	table.insert(connections, resetBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		walkSpeedValue = 16
		jumpPowerValue = 50
		flySpeed = 100
		flyFreeSpeed = 80
		local _, _, humanoid = getCharacterParts()
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		end
		if sliderRefs[walkSlider] then sliderRefs[walkSlider].setValue(16) end
		if sliderRefs[jumpSlider] then sliderRefs[jumpSlider].setValue(50) end
		if sliderRefs[flySpeedSlider] then sliderRefs[flySpeedSlider].setValue(100) end
		if sliderRefs[flyFreeSpeedSlider] then sliderRefs[flyFreeSpeedSlider].setValue(80) end
		saveConfig()
	end))

	table.insert(connections, closeBtn.MouseButton1Click:Connect(function() window.Visible = false end))
	table.insert(connections, minimizeBtn.MouseButton1Click:Connect(function() window.Visible = false end))

	table.insert(connections, unloadBtn.MouseButton1Click:Connect(function()
		if unloaded then return end
		unloaded = true
		flyEnabled = false
		if flyConn then flyConn:Disconnect() flyConn = nil end
		stopMagnetAll()
		if aimbotConn then aimbotConn:Disconnect() aimbotConn = nil end
		if triggerbotConn then triggerbotConn:Disconnect() triggerbotConn = nil end
		saveConfig()
		for _, c in ipairs(connections) do
			if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
		end
		connections = {}
		if screenGui and screenGui.Parent then screenGui:Destroy() end
		print("[VIPMenu] Выгружено.")
	end))

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		applyWalkSpeed()
		applyJumpPower()
	end)
	task.wait(0.5)
	applyWalkSpeed()
	applyJumpPower()

	refreshPlayersList()

	task.spawn(function()
		while not unloaded do
			task.wait(0.5)
			if unloaded then break end
			if activeTab == "Players" then
				refreshPlayersList()
			end
		end
	end)

	-- ===== КЛАВИШИ =====
	local toggleKeys = {
		Enum.KeyCode.Insert,
		Enum.KeyCode.RightControl,
		Enum.KeyCode.F1,
		Enum.KeyCode.RightShift,
	}

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if unloaded then return end

		if autoTpEnabled and input.KeyCode == autoTpKey then
			task.spawn(doAutoTeleport)
			return
		end

		if input.KeyCode == Enum.KeyCode.Space then
			if isTeleporting then teleportCancelled = true end
			if magnetEnabled then
				magnetEnabled = false
				magnetTarget = nil
				if magnetConn then magnetConn:Disconnect() magnetConn = nil end
			end
			return
		end

		for _, key in ipairs(toggleKeys) do
			if input.KeyCode == key then
				window.Visible = not window.Visible
				return
			end
		end

		if gameProcessed then return end
	end))

	-- Загрузка конфига
	loadConfig()
	applyTheme(currentTheme)
	applyStyle(currentStyle)

	switchTab("Info")

	-- Плавное появление окна
	window.Visible = true
	TweenService:Create(window, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -windowW/2, 0.5, -windowH/2),
		BackgroundTransparency = 0,
	}):Play()
	TweenService:Create(windowStroke, TweenInfo.new(0.55), {Transparency = 0}):Play()

	-- Убираем загрузочный экран
	TweenService:Create(loadFrame, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
	for _, child in ipairs(loadFrame:GetDescendants()) do
		if child:IsA("TextLabel") then
			TweenService:Create(child, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
		elseif child:IsA("Frame") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, TweenInfo.new(0.35), {Transparency = 1}):Play()
		end
	end
	task.wait(0.4)
	if loadGui and loadGui.Parent then loadGui:Destroy() end

	print("[VIPMenu] Готово. Клавиши: Insert / RightCtrl / F1 / RightShift")
end)

-- ★ Показываем ошибку если скрипт упал
if not _ok then
	warn("[VIPMenu] ОШИБКА: " .. tostring(_err))
end
