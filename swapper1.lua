-- LocalScript → StarterPlayer → StarterPlayerScripts

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

-- ★ Текущая тема (будет меняться)
local currentTheme = "Тёмная"
local currentStyle = "Default"

print("[VIPMenu] Загрузка...")

-- ================= ЦВЕТОВЫЕ ТЕМЫ =================
local THEMES = {
	["Тёмная"] = {
		bg = Color3.fromRGB(20, 20, 26),
		panel = Color3.fromRGB(24, 24, 30),
		topBar = Color3.fromRGB(26, 26, 34),
		button = Color3.fromRGB(32, 32, 40),
		buttonHover = Color3.fromRGB(42, 42, 54),
		accent = Color3.fromRGB(90, 70, 220),
		text = Color3.fromRGB(220, 220, 235),
		textDim = Color3.fromRGB(150, 150, 170),
		stroke = Color3.fromRGB(48, 48, 60),
		header = Color3.fromRGB(40, 40, 55),
		headerText = Color3.fromRGB(180, 180, 220),
		success = Color3.fromRGB(120, 255, 150),
		danger = Color3.fromRGB(255, 90, 90),
		warn = Color3.fromRGB(255, 200, 80),
		info = Color3.fromRGB(130, 200, 255),
	},
	["Белая"] = {
		bg = Color3.fromRGB(245, 245, 250),
		panel = Color3.fromRGB(235, 235, 245),
		topBar = Color3.fromRGB(255, 255, 255),
		button = Color3.fromRGB(255, 255, 255),
		buttonHover = Color3.fromRGB(230, 230, 240),
		accent = Color3.fromRGB(120, 100, 240),
		text = Color3.fromRGB(30, 30, 40),
		textDim = Color3.fromRGB(100, 100, 120),
		stroke = Color3.fromRGB(200, 200, 215),
		header = Color3.fromRGB(220, 220, 235),
		headerText = Color3.fromRGB(60, 60, 90),
		success = Color3.fromRGB(60, 180, 100),
		danger = Color3.fromRGB(220, 60, 60),
		warn = Color3.fromRGB(230, 160, 30),
		info = Color3.fromRGB(80, 130, 220),
	},
	["Космос"] = {
		bg = Color3.fromRGB(10, 8, 25),
		panel = Color3.fromRGB(18, 15, 40),
		topBar = Color3.fromRGB(25, 15, 60),
		button = Color3.fromRGB(30, 25, 60),
		buttonHover = Color3.fromRGB(45, 35, 90),
		accent = Color3.fromRGB(150, 80, 255),
		text = Color3.fromRGB(230, 220, 255),
		textDim = Color3.fromRGB(160, 140, 220),
		stroke = Color3.fromRGB(80, 50, 150),
		header = Color3.fromRGB(50, 30, 110),
		headerText = Color3.fromRGB(200, 170, 255),
		success = Color3.fromRGB(150, 120, 255),
		danger = Color3.fromRGB(255, 100, 200),
		warn = Color3.fromRGB(255, 200, 255),
		info = Color3.fromRGB(180, 150, 255),
	},
	["Снежная"] = {
		bg = Color3.fromRGB(225, 240, 250),
		panel = Color3.fromRGB(210, 230, 245),
		topBar = Color3.fromRGB(240, 250, 255),
		button = Color3.fromRGB(240, 250, 255),
		buttonHover = Color3.fromRGB(210, 230, 245),
		accent = Color3.fromRGB(80, 160, 220),
		text = Color3.fromRGB(30, 50, 70),
		textDim = Color3.fromRGB(90, 120, 150),
		stroke = Color3.fromRGB(180, 210, 230),
		header = Color3.fromRGB(190, 220, 240),
		headerText = Color3.fromRGB(50, 90, 130),
		success = Color3.fromRGB(80, 180, 180),
		danger = Color3.fromRGB(220, 100, 130),
		warn = Color3.fromRGB(230, 170, 90),
		info = Color3.fromRGB(100, 170, 230),
	},
	["Осенняя"] = {
		bg = Color3.fromRGB(45, 25, 15),
		panel = Color3.fromRGB(60, 35, 20),
		topBar = Color3.fromRGB(80, 45, 25),
		button = Color3.fromRGB(75, 45, 25),
		buttonHover = Color3.fromRGB(105, 65, 35),
		accent = Color3.fromRGB(230, 130, 40),
		text = Color3.fromRGB(250, 230, 210),
		textDim = Color3.fromRGB(210, 170, 130),
		stroke = Color3.fromRGB(140, 80, 40),
		header = Color3.fromRGB(110, 60, 30),
		headerText = Color3.fromRGB(255, 210, 170),
		success = Color3.fromRGB(180, 200, 90),
		danger = Color3.fromRGB(220, 80, 60),
		warn = Color3.fromRGB(240, 180, 70),
		info = Color3.fromRGB(230, 160, 90),
	},
}

-- ================= СТИЛИ =================
local STYLES = {
	["Default"] = {
		cornerRadius = 10,
		buttonRadius = 6,
		strokeThickness = 1,
		windowPadding = 8,
		topBarHeight = 46,
		sidebarWidth = 150,
		useGradient = false,
	},
	["Compact"] = {
		cornerRadius = 4,
		buttonRadius = 2,
		strokeThickness = 1,
		windowPadding = 4,
		topBarHeight = 36,
		sidebarWidth = 130,
		useGradient = false,
	},
	["Rounded"] = {
		cornerRadius = 20,
		buttonRadius = 14,
		strokeThickness = 2,
		windowPadding = 12,
		topBarHeight = 54,
		sidebarWidth = 170,
		useGradient = true,
	},
}

-- ================= GUI =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VIPMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local windowW, windowH = 660, 600

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.new(0, windowW, 0, windowH)
window.Position = UDim2.new(0.5, -windowW/2, 0.5, -windowH/2)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
window.BorderSizePixel = 0
window.Visible = false
window.Active = true
window.Draggable = true
window.Parent = screenGui
window.ZIndex = 10

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 10)
windowCorner.Parent = window

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Color3.fromRGB(48, 48, 60)
windowStroke.Thickness = 1
windowStroke.Parent = window

-- ★ Собираем все элементы для смены темы
local themeRefs = {
	window = window,
	windowCorner = windowCorner,
	windowStroke = windowStroke,
}

-- Топ-бар
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 46)
topBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
topBar.BorderSizePixel = 0
topBar.Parent = window
topBar.ZIndex = 11
local topBarCorner = Instance.new("UICorner") topBarCorner.CornerRadius = UDim.new(0, 10) topBarCorner.Parent = topBar

local topBarCover = Instance.new("Frame")
topBarCover.Size = UDim2.new(1, 0, 0, 12)
topBarCover.Position = UDim2.new(0, 0, 1, -12)
topBarCover.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
topBarCover.BorderSizePixel = 0
topBarCover.Parent = topBar
topBarCover.ZIndex = 11

local logoBox = Instance.new("Frame")
logoBox.Size = UDim2.new(0, 30, 0, 30)
logoBox.Position = UDim2.new(0, 12, 0.5, -15)
logoBox.BackgroundColor3 = Color3.fromRGB(90, 70, 220)
logoBox.BorderSizePixel = 0
logoBox.Parent = topBar
logoBox.ZIndex = 12
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
titleTop.TextColor3 = Color3.fromRGB(255, 255, 255)
titleTop.TextSize = 13
titleTop.TextXAlignment = Enum.TextXAlignment.Left
titleTop.Font = Enum.Font.GothamBold
titleTop.Parent = topBar
titleTop.ZIndex = 12

local subtitleTop = Instance.new("TextLabel")
subtitleTop.Size = UDim2.new(0, 350, 0, 14)
subtitleTop.Position = UDim2.new(0, 52, 0, 22)
subtitleTop.BackgroundTransparency = 1
subtitleTop.Text = "by swapper.sk"
subtitleTop.TextColor3 = Color3.fromRGB(130, 130, 155)
subtitleTop.TextSize = 10
subtitleTop.TextXAlignment = Enum.TextXAlignment.Left
subtitleTop.Font = Enum.Font.Gotham
subtitleTop.Parent = topBar
subtitleTop.ZIndex = 12

local function createTopBtn(text, xOff, txtColor)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 24, 0, 24)
	b.Position = UDim2.new(1, xOff, 0.5, -12)
	b.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	b.Text = text
	b.TextColor3 = txtColor
	b.TextSize = 12
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent = topBar
	b.ZIndex = 13
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
	table.insert(themeRefs, {obj = b, prop = "BackgroundColor3", role = "button"})
	return b
end

local minimizeBtn = createTopBtn("—", -70, Color3.fromRGB(200, 200, 210))
local closeBtn = createTopBtn("✕", -38, Color3.fromRGB(255, 100, 110))

-- Сайдбар
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 150, 1, -58)
sidebar.Position = UDim2.new(0, 8, 0, 52)
sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
sidebar.BorderSizePixel = 0
sidebar.Parent = window
sidebar.ZIndex = 11
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
contentArea.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
contentArea.BorderSizePixel = 0
contentArea.Parent = window
contentArea.ZIndex = 11
local caC = Instance.new("UICorner") caC.CornerRadius = UDim.new(0, 8) caC.Parent = contentArea

local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(1, -16, 0, 22)
pageTitle.Position = UDim2.new(0, 12, 0, 6)
pageTitle.BackgroundTransparency = 1
pageTitle.Text = "Info"
pageTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pageTitle.TextSize = 13
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Font = Enum.Font.GothamBold
pageTitle.Parent = contentArea
pageTitle.ZIndex = 12

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Size = UDim2.new(1, -16, 1, -36)
scroll.Position = UDim2.new(0, 8, 0, 32)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 110)
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

local tabButtons = {}

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

-- ★ Info первый
local infoPage = createTab("Info", "ℹ")
local farmingPage = createTab("Farming", "🌾")
local movementPage = createTab("Movement", "🏃")
local playersPage = createTab("Players", "👥")
local combatPage = createTab("Combat", "⚔")
local themePage = createTab("Theme", "🎨")
local miscPage = createTab("Misc", "⚙")

-- ★★ Компоненты ★★

-- Секция с корректным сворачиванием через AutomaticSize
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
	header.Size = UDim2.new(1, 0, 0, 24)
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

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -28, 0, 6)
	barBg.Position = UDim2.new(0, 14, 0, 30)
	barBg.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	barBg.BorderSizePixel = 0
	barBg.Parent = row
	barBg.ZIndex = 13
	local bbc = Instance.new("UICorner") bbc.CornerRadius = UDim.new(1, 0) bbc.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0.5, 0, 1, 0)
	barFill.BackgroundColor3 = color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	barFill.ZIndex = 14
	local bfc = Instance.new("UICorner") bfc.CornerRadius = UDim.new(1, 0) bfc.Parent = barFill

	local minusBtn = Instance.new("TextButton")
	minusBtn.Size = UDim2.new(0, 26, 0, 18)
	minusBtn.Position = UDim2.new(0, 14, 0, 40)
	minusBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 60)
	minusBtn.Text = "−"
	minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	minusBtn.TextSize = 13
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.BorderSizePixel = 0
	minusBtn.Parent = row
	minusBtn.ZIndex = 13
	local mbc = Instance.new("UICorner") mbc.CornerRadius = UDim.new(0, 4) mbc.Parent = minusBtn

	local plusBtn = Instance.new("TextButton")
	plusBtn.Size = UDim2.new(0, 26, 0, 18)
	plusBtn.Position = UDim2.new(0, 44, 0, 40)
	plusBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 60)
	plusBtn.Text = "+"
	plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	plusBtn.TextSize = 13
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.BorderSizePixel = 0
	plusBtn.Parent = row
	plusBtn.ZIndex = 13
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
-- ИНФО
-- ============================================================
local infoTitle = Instance.new("TextLabel")
infoTitle.Size = UDim2.new(1, 0, 0, 50)
infoTitle.BackgroundColor3 = Color3.fromRGB(45, 30, 70)
infoTitle.Text = "   Script by tt: swapper.sk"
infoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
infoTitle.TextSize = 16
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
infoTitle.Font = Enum.Font.GothamBold
infoTitle.BorderSizePixel = 0
infoTitle.Parent = infoPage
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
infoTg.Parent = infoPage
infoTg.ZIndex = 12
local itgC = Instance.new("UICorner") itgC.CornerRadius = UDim.new(0, 8) itgC.Parent = infoTg

local socialsFrame = Instance.new("Frame")
socialsFrame.Size = UDim2.new(1, 0, 0, 70)
socialsFrame.BackgroundColor3 = THEMES[currentTheme].button
socialsFrame.BorderSizePixel = 0
socialsFrame.Parent = infoPage
socialsFrame.ZIndex = 12
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

tgIcon.MouseEnter:Connect(function()
	TweenService:Create(tgIcon, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 180, 240)}):Play()
end)
tgIcon.MouseLeave:Connect(function()
	TweenService:Create(tgIcon, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 160, 220)}):Play()
end)
tgIcon.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard("https://t.me/ZearDLC")
		tgIcon.Text = "✓"
		task.wait(1)
		tgIcon.Text = "✈"
	end
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

ttIcon.MouseEnter:Connect(function()
	TweenService:Create(ttIcon, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
	ttStroke.Color = Color3.fromRGB(60, 240, 220)
end)
ttIcon.MouseLeave:Connect(function()
	TweenService:Create(ttIcon, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 36)}):Play()
	ttStroke.Color = Color3.fromRGB(255, 60, 100)
end)
ttIcon.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard("https://tiktok.com/@swapper.sk")
		ttIcon.Text = "✓"
		task.wait(1)
		ttIcon.Text = "♪"
	end
end)

local function addInfoLine(title, desc)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 46)
	line.BackgroundColor3 = THEMES[currentTheme].button
	line.BorderSizePixel = 0
	line.Parent = infoPage
	line.ZIndex = 12
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

local infoSection = createSection(infoPage, "📖  ОПИСАНИЕ ФУНКЦИЙ")

addInfoLine("🌾  Farming", "Плавный и моментальный телепорт. Сохрани точку — вернись в любой момент.")
addInfoLine("🏃  Movement", "Fly — свободный полёт. Слайдеры WalkSpeed и JumpPower.")
addInfoLine("👥  Players", "Auto-TP к ближайшему по бинду. Список игроков сортирован по дистанции.")
addInfoLine("⚔  Combat — Aimbot", "Зажми бинд — камера наводится на ближайшего противника (aim lock).")
addInfoLine("⚔  Combat — Triggerbot", "Авто-выстрел когда перед тобой враг. Требует оружие в руках.")
addInfoLine("⚔  Combat — Magnet All", "Собирает всех игроков в кольцо перед тобой.")
addInfoLine("🎨  Theme", "3 стиля интерфейса (Default / Compact / Rounded) и 5 цветовых тем.")
addInfoLine("⌨  Клавиши", "Insert / RightCtrl / F1 / RightShift — меню. End — выгрузить.")

-- ============================================================
-- FARMING
-- ============================================================
local farmingTP = createSection(farmingPage, "TELEPORT (плавный)", true)
local saveBtn = createActionBtn(farmingTP, "📌  Запомнить координаты", Color3.fromRGB(80, 130, 230))
local tpBtn = createActionBtn(farmingTP, "🚀  Телепорт на координаты", Color3.fromRGB(80, 200, 130))
local backBtn = createActionBtn(farmingTP, "↩  Вернуться обратно", Color3.fromRGB(230, 100, 80))

local farmingInstant = createSection(farmingPage, "INSTANT TELEPORT", true)
local instantSaveBtn = createActionBtn(farmingInstant, "📌  Запомнить координаты (Instant)", Color3.fromRGB(80, 130, 230))
local instantTpBtn = createActionBtn(farmingInstant, "⚡  Моментальный телепорт", Color3.fromRGB(255, 200, 80))
local instantBackBtn = createActionBtn(farmingInstant, "↩  Вернуться (Instant)", Color3.fromRGB(230, 120, 80))

local farmingSpeed = createSection(farmingPage, "SPEED", true)
local flySpeedSlider = createSlider(farmingSpeed, "🚀  Скорость полёта (TP)", flySpeed, 20, 500, 25, Color3.fromRGB(130, 190, 255))
sliderRefs[flySpeedSlider].onChanged = function(v) flySpeed = v end

-- ============================================================
-- MOVEMENT
-- ============================================================
local movementPlayer = createSection(movementPage, "PLAYER", true)
local walkSlider = createSlider(movementPlayer, "🏃  Скорость бега", walkSpeedValue, 8, 200, 16, Color3.fromRGB(120, 255, 170))
sliderRefs[walkSlider].onChanged = function(v)
	walkSpeedValue = v
	local _, _, humanoid = getCharacterParts()
	if humanoid and not flyEnabled then humanoid.WalkSpeed = walkSpeedValue end
end

local jumpSlider = createSlider(movementPlayer, "🦘  Сила прыжка", jumpPowerValue, 0, 200, 10, Color3.fromRGB(255, 200, 120))
sliderRefs[jumpSlider].onChanged = function(v)
	jumpPowerValue = v
	local _, _, humanoid = getCharacterParts()
	if humanoid and not flyEnabled then humanoid.JumpPower = jumpPowerValue end
end

local movementFly = createSection(movementPage, "🚀  FLY", true)
local flyToggle = createToggle(movementFly, "🚀  Fly (свободный полёт)", false, function(state)
	flyEnabled = state
	if not state then
		if flyConn then flyConn:Disconnect() flyConn = nil end
		local _, hrp, humanoid = getCharacterParts()
		if humanoid then
			humanoid.PlatformStand = false
			humanoid.WalkSpeed = walkSpeedValue
			humanoid.JumpPower = jumpPowerValue
			humanoid.JumpHeight = 7.2
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
		end
		if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
	end
end)

local flyFreeSpeedSlider = createSlider(movementFly, "🚀  Скорость Fly", flyFreeSpeed, 20, 300, 20, Color3.fromRGB(255, 180, 120))
sliderRefs[flyFreeSpeedSlider].onChanged = function(v) flyFreeSpeed = v end

-- ============================================================
-- PLAYERS
-- ============================================================
local playersAuto = createSection(playersPage, "⚡  AUTO-TP К БЛИЖАЙШЕМУ", true)

local autoTpToggle = createToggle(playersAuto, "⚡  Auto-TP (зажми бинд)", false, function(state)
	autoTpEnabled = state
	if autoTpStatus then
		autoTpStatus.Text = state and ("   Статус: ВКЛ  |  Бинд: " .. autoTpKeyName) or "   Статус: ВЫКЛ"
		autoTpStatus.TextColor3 = state and THEMES[currentTheme].success or THEMES[currentTheme].text
	end
end)

local autoTpStatus = Instance.new("TextLabel")
autoTpStatus.Size = UDim2.new(1, 0, 0, 26)
autoTpStatus.BackgroundColor3 = THEMES[currentTheme].button
autoTpStatus.Text = "   Статус: ВЫКЛ"
autoTpStatus.TextColor3 = THEMES[currentTheme].text
autoTpStatus.TextSize = 11
autoTpStatus.TextXAlignment = Enum.TextXAlignment.Left
autoTpStatus.Font = Enum.Font.Gotham
autoTpStatus.BorderSizePixel = 0
autoTpStatus.Parent = playersAuto
autoTpStatus.ZIndex = 12
local atsC = Instance.new("UICorner") atsC.CornerRadius = UDim.new(0, 6) atsC.Parent = autoTpStatus

local autoTpAboveToggle = createToggle(playersAuto, "⬆  Телепорт ВВЕРХ над игроком", false, function(state)
	autoTpAbove = state
end)

local autoTpBindRow = createBindRow(
	playersAuto,
	"Клавиша Auto-TP (зажми):",
	function() return autoTpKeyName end,
	function(key, name)
		autoTpKey = key
		autoTpKeyName = name
		if autoTpStatus then
			autoTpStatus.Text = autoTpEnabled and ("   Статус: ВКЛ  |  Бинд: " .. autoTpKeyName) or "   Статус: ВЫКЛ"
		end
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

local playersList = createSection(playersPage, "👥  ИГРОКИ (ближайший сверху)", true)

local playersListFrame = Instance.new("Frame")
playersListFrame.Size = UDim2.new(1, 0, 0, 220)
playersListFrame.BackgroundColor3 = THEMES[currentTheme].button
playersListFrame.BorderSizePixel = 0
playersListFrame.Parent = playersList
playersListFrame.ZIndex = 12
local plfC = Instance.new("UICorner") plfC.CornerRadius = UDim.new(0, 6) plfC.Parent = playersListFrame

local playersListScroll = Instance.new("ScrollingFrame")
playersListScroll.Size = UDim2.new(1, -8, 1, -8)
playersListScroll.Position = UDim2.new(0, 4, 0, 4)
playersListScroll.BackgroundTransparency = 1
playersListScroll.BorderSizePixel = 0
playersListScroll.ScrollBarThickness = 4
playersListScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 110)
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

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 30, 1, 0)
		icon.Position = UDim2.new(1, -32, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = "🧲"
		icon.TextColor3 = THEMES[currentTheme].accent
		icon.TextSize = 16
		icon.Font = Enum.Font.GothamBold
		icon.Parent = row
		icon.ZIndex = 14

		row.MouseEnter:Connect(function()
			row.BackgroundColor3 = THEMES[currentTheme].accent
		end)
		row.MouseLeave:Connect(function()
			row.BackgroundColor3 = isNearest and THEMES[currentTheme].accent or THEMES[currentTheme].header
		end)
		row.MouseButton1Click:Connect(function()
			startMagnet(plr)
		end)

		table.insert(playerRows, row)
	end
end

local playersActions = createSection(playersPage, "ДЕЙСТВИЯ", true)
local magnetStatusLabel = Instance.new("TextLabel")
magnetStatusLabel.Size = UDim2.new(1, 0, 0, 26)
magnetStatusLabel.BackgroundColor3 = THEMES[currentTheme].button
magnetStatusLabel.Text = "   Цель: нет"
magnetStatusLabel.TextColor3 = THEMES[currentTheme].text
magnetStatusLabel.TextSize = 11
magnetStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
magnetStatusLabel.Font = Enum.Font.Gotham
magnetStatusLabel.BorderSizePixel = 0
magnetStatusLabel.Parent = playersActions
magnetStatusLabel.ZIndex = 12
local mslC = Instance.new("UICorner") mslC.CornerRadius = UDim.new(0, 6) mslC.Parent = magnetStatusLabel

local stopMagnetBtn = createActionBtn(playersActions, "✕  Отлипнуть (пробел)", Color3.fromRGB(230, 80, 80))
local refreshPlayersBtn = createActionBtn(playersActions, "🔄  Обновить список", Color3.fromRGB(100, 180, 255))

-- ============================================================
-- COMBAT
-- ============================================================
local combatAim = createSection(combatPage, "🎯  AIMBOT (зажми бинд)", true)

local aimbotToggle = createToggle(combatAim, "🎯  Aimbot (aim lock)", false, function(state)
	aimbotEnabled = state
	if aimbotStatusLabel then
		aimbotStatusLabel.Text = state and ("   Aimbot: ВКЛ  |  Бинд: " .. aimbotKeyName) or "   Aimbot: ВЫКЛ"
		aimbotStatusLabel.TextColor3 = state and THEMES[currentTheme].danger or THEMES[currentTheme].text
	end
end)

local aimbotStatusLabel = Instance.new("TextLabel")
aimbotStatusLabel.Size = UDim2.new(1, 0, 0, 26)
aimbotStatusLabel.BackgroundColor3 = THEMES[currentTheme].button
aimbotStatusLabel.Text = "   Aimbot: ВЫКЛ"
aimbotStatusLabel.TextColor3 = THEMES[currentTheme].text
aimbotStatusLabel.TextSize = 11
aimbotStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
aimbotStatusLabel.Font = Enum.Font.Gotham
aimbotStatusLabel.BorderSizePixel = 0
aimbotStatusLabel.Parent = combatAim
aimbotStatusLabel.ZIndex = 12
local aslC = Instance.new("UICorner") aslC.CornerRadius = UDim.new(0, 6) aslC.Parent = aimbotStatusLabel

local aimbotTargetLabel = Instance.new("TextLabel")
aimbotTargetLabel.Size = UDim2.new(1, 0, 0, 26)
aimbotTargetLabel.BackgroundColor3 = THEMES[currentTheme].button
aimbotTargetLabel.Text = "   Цель: —"
aimbotTargetLabel.TextColor3 = THEMES[currentTheme].text
aimbotTargetLabel.TextSize = 11
aimbotTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
aimbotTargetLabel.Font = Enum.Font.Gotham
aimbotTargetLabel.BorderSizePixel = 0
aimbotTargetLabel.Parent = combatAim
aimbotTargetLabel.ZIndex = 12
local atlC = Instance.new("UICorner") atlC.CornerRadius = UDim.new(0, 6) atlC.Parent = aimbotTargetLabel

local combatSettings = createSection(combatPage, "⚙  НАСТРОЙКИ AIMBOT", true)

local aimbotSmoothSlider = createSlider(combatSettings, "🎯  Плавность", aimbotSmoothness, 0, 1, 0.05, Color3.fromRGB(255, 150, 150), true)
sliderRefs[aimbotSmoothSlider].onChanged = function(v) aimbotSmoothness = v end

local aimbotRangeSlider = createSlider(combatSettings, "📏  Дальность (studs)", aimbotRange, 30, 1000, 30, Color3.fromRGB(255, 180, 100))
sliderRefs[aimbotRangeSlider].onChanged = function(v) aimbotRange = v end

local aimbotTeamToggle = createToggle(combatSettings, "👥  Игнорировать своих (Team Check)", false, function(state)
	aimbotTeamCheck = state
end)

local aimbotVisibleToggle = createToggle(combatSettings, "👁  Только видимые", false, function(state)
	aimbotVisibleCheck = state
end)

local aimbotBindRow = createBindRow(
	combatSettings,
	"Клавиша Aimbot (зажми):",
	function() return aimbotKeyName end,
	function(key, name)
		aimbotKey = key
		aimbotKeyName = name
		if aimbotStatusLabel then
			aimbotStatusLabel.Text = aimbotEnabled and ("   Aimbot: ВКЛ  |  Бинд: " .. aimbotKeyName) or "   Aimbot: ВЫКЛ"
		end
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

local triggerbotToggle = createToggle(combatTrigger, "🔫  Triggerbot", false, function(state)
	triggerbotEnabled = state
	if triggerbotStatus then
		triggerbotStatus.Text = state and "   Triggerbot: ВКЛ" or "   Triggerbot: ВЫКЛ"
		triggerbotStatus.TextColor3 = state and THEMES[currentTheme].danger or THEMES[currentTheme].text
	end
end)

local triggerbotStatus = Instance.new("TextLabel")
triggerbotStatus.Size = UDim2.new(1, 0, 0, 26)
triggerbotStatus.BackgroundColor3 = THEMES[currentTheme].button
triggerbotStatus.Text = "   Triggerbot: ВЫКЛ"
triggerbotStatus.TextColor3 = THEMES[currentTheme].text
triggerbotStatus.TextSize = 11
triggerbotStatus.TextXAlignment = Enum.TextXAlignment.Left
triggerbotStatus.Font = Enum.Font.Gotham
triggerbotStatus.BorderSizePixel = 0
triggerbotStatus.Parent = combatTrigger
triggerbotStatus.ZIndex = 12
local tbsC = Instance.new("UICorner") tbsC.CornerRadius = UDim.new(0, 6) tbsC.Parent = triggerbotStatus

local triggerbotRangeSlider = createSlider(combatTrigger, "📏  Радиус (studs)", triggerbotRange, 10, 200, 5, Color3.fromRGB(255, 130, 130))
sliderRefs[triggerbotRangeSlider].onChanged = function(v) triggerbotRange = v end

local triggerbotDelaySlider = createSlider(combatTrigger, "⏱  Задержка (сек)", triggerbotDelay, 0.05, 1, 0.05, Color3.fromRGB(255, 180, 130), true)
sliderRefs[triggerbotDelaySlider].onChanged = function(v) triggerbotDelay = v end

local combatMagnetAll = createSection(combatPage, "🌀  MAGNET ALL", true)

local magnetAllToggle = createToggle(combatMagnetAll, "🌀  Magnet All", false, function(state)
	magnetAllEnabled = state
	if state then
		startMagnetAll()
	else
		stopMagnetAll()
	end
end)

local magnetAllStatus = Instance.new("TextLabel")
magnetAllStatus.Size = UDim2.new(1, 0, 0, 26)
magnetAllStatus.BackgroundColor3 = THEMES[currentTheme].button
magnetAllStatus.Text = "   Magnet All: ВЫКЛ"
magnetAllStatus.TextColor3 = THEMES[currentTheme].text
magnetAllStatus.TextSize = 11
magnetAllStatus.TextXAlignment = Enum.TextXAlignment.Left
magnetAllStatus.Font = Enum.Font.Gotham
magnetAllStatus.BorderSizePixel = 0
magnetAllStatus.Parent = combatMagnetAll
magnetAllStatus.ZIndex = 12
local masC = Instance.new("UICorner") masC.CornerRadius = UDim.new(0, 6) masC.Parent = magnetAllStatus

local magnetAllOffsetSlider = createSlider(combatMagnetAll, "📍  Вперёд ставить", magnetAllForwardOffset, 3, 60, 2, Color3.fromRGB(220, 130, 255))
sliderRefs[magnetAllOffsetSlider].onChanged = function(v) magnetAllForwardOffset = v end

local magnetAllRadiusSlider = createSlider(combatMagnetAll, "📏  Радиус сбора (studs)", magnetAllRadius, 10, 500, 10, Color3.fromRGB(180, 130, 255))
sliderRefs[magnetAllRadiusSlider].onChanged = function(v) magnetAllRadius = v end

local magnetAllDurationSlider = createSlider(combatMagnetAll, "⏱  Длительность (0 = ∞)", magnetAllHoldTime, 0, 60, 2, Color3.fromRGB(255, 160, 220))
sliderRefs[magnetAllDurationSlider].onChanged = function(v) magnetAllHoldTime = v end

-- ============================================================
-- THEME
-- ============================================================
local themeSection = createSection(themePage, "🎨  ЦВЕТОВАЯ ТЕМА", false)

local themeHint = Instance.new("TextLabel")
themeHint.Size = UDim2.new(1, 0, 0, 24)
themeHint.BackgroundColor3 = THEMES[currentTheme].button
themeHint.Text = "   Выбери тему интерфейса:"
themeHint.TextColor3 = THEMES[currentTheme].text
themeHint.TextSize = 11
themeHint.TextXAlignment = Enum.TextXAlignment.Left
themeHint.Font = Enum.Font.Gotham
themeHint.BorderSizePixel = 0
themeHint.Parent = themeSection
themeHint.ZIndex = 12
local thc = Instance.new("UICorner") thc.CornerRadius = UDim.new(0, 6) thc.Parent = themeHint

local themeButtons = {}
local themeButtonRefs = {}

-- ★★★ ФУНКЦИЯ ПРИМЕНЕНИЯ ТЕМЫ ★★★
local function applyTheme(themeName)
	local t = THEMES[themeName]
	if not t then return end
	currentTheme = themeName

	-- Окно
	window.BackgroundColor3 = t.bg
	windowStroke.Color = t.stroke
	topBar.BackgroundColor3 = t.topBar
	topBarCover.BackgroundColor3 = t.topBar
	sidebar.BackgroundColor3 = t.panel
	contentArea.BackgroundColor3 = t.panel

	pageTitle.TextColor3 = t.text
	titleTop.TextColor3 = t.text
	subtitleTop.TextColor3 = t.textDim

	logoBox.BackgroundColor3 = t.accent

	-- Вкладки
	for _, data in pairs(tabs) do
		if activeTab == data.btn.Name or (tabs[activeTab] and tabs[activeTab].btn == data.btn) then
			data.btn.BackgroundColor3 = t.accent
			data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			data.btn.BackgroundColor3 = t.panel
			data.btn.TextColor3 = t.textDim
		end
	end

	-- Пройтись по всем элементам и применить цвета по их ролям
	for _, ref in ipairs(themeRefs) do
		if type(ref) == "table" then
			local obj = ref.obj
			if obj and obj.Parent then
				if ref.role == "button" then obj.BackgroundColor3 = t.button end
			end
		end
	end

	-- Кнопки действий (с маркером)
	for _, obj in ipairs(scroll:GetDescendants()) do
		if obj:IsA("TextButton") and obj ~= nil then
			-- Обновляем по возможности
		end
	end

	-- Простой способ: пробегаем по всем TabButton и обновляем их цвета
	for _, data in ipairs(tabButtons) do
		if tabs[activeTab] and tabs[activeTab].btn == data.btn then
			data.btn.BackgroundColor3 = t.accent
			data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			data.btn.BackgroundColor3 = t.panel
			data.btn.TextColor3 = t.textDim
		end
	end

	-- Обновляем выделение в списке тем
	for name, btn in pairs(themeButtonRefs) do
		if name == themeName then
			btn.BackgroundColor3 = t.accent
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = t.button
			btn.TextColor3 = t.text
		end
	end

	-- Все action-кнопки, тогглы, слайдеры, бинды — обновляем по имени
	for _, obj in ipairs(scroll:GetDescendants()) do
		if obj:IsA("Frame") and obj.BackgroundColor3 ~= Color3.fromRGB(18, 18, 24) then
			-- не трогаем barBg (тёмный), он специально тёмный
		end
	end
end

-- ★★★ ФУНКЦИЯ ПРИМЕНЕНИЯ СТИЛЯ ★★★
local function applyStyle(styleName)
	local s = STYLES[styleName]
	if not s then return end
	currentStyle = styleName

	windowCorner.CornerRadius = UDim.new(0, s.cornerRadius)
	topBarCorner.CornerRadius = UDim.new(0, s.cornerRadius)
	sbC.CornerRadius = UDim.new(0, s.cornerRadius - 2)
	caC.CornerRadius = UDim.new(0, s.cornerRadius - 2)
	windowStroke.Thickness = s.strokeThickness

	topBar.Size = UDim2.new(1, 0, 0, s.topBarHeight)
	topBarCover.Size = UDim2.new(1, 0, 0, s.cornerRadius)
	topBarCover.Position = UDim2.new(0, 0, 1, -s.cornerRadius)

	sidebar.Size = UDim2.new(0, s.sidebarWidth, 1, -(s.topBarHeight + 12))
	sidebar.Position = UDim2.new(0, s.windowPadding, 0, s.topBarHeight + 6)

	contentArea.Size = UDim2.new(1, -(s.sidebarWidth + 24), 1, -(s.topBarHeight + 22))
	contentArea.Position = UDim2.new(0, s.sidebarWidth + s.windowPadding + 8, 0, s.topBarHeight + 12)

	-- Обновляем все UICorner
	for _, obj in ipairs(window:GetDescendants()) do
		if obj:IsA("UICorner") then
			obj.CornerRadius = UDim.new(0, s.buttonRadius)
		end
	end
	windowCorner.CornerRadius = UDim.new(0, s.cornerRadius)
	topBarCorner.CornerRadius = UDim.new(0, s.cornerRadius)
end

-- Пресеты тем
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

	btn.MouseButton1Click:Connect(function()
		applyTheme(preset.name)
	end)

	themeButtonRefs[preset.name] = btn
end

-- Стили
local styleSection = createSection(themePage, "🖼  СТИЛЬ ИНТЕРФЕЙСА", false)

local styleHint = Instance.new("TextLabel")
styleHint.Size = UDim2.new(1, 0, 0, 24)
styleHint.BackgroundColor3 = THEMES[currentTheme].button
styleHint.Text = "   Выбери стиль окна:"
styleHint.TextColor3 = THEMES[currentTheme].text
styleHint.TextSize = 11
styleHint.TextXAlignment = Enum.TextXAlignment.Left
styleHint.Font = Enum.Font.Gotham
styleHint.BorderSizePixel = 0
styleHint.Parent = styleSection
styleHint.ZIndex = 12
local shc = Instance.new("UICorner") shc.CornerRadius = UDim.new(0, 6) shc.Parent = styleHint

local stylePresets = {
	{name = "Default", desc = "Стандартный тёмный", icon = "🎨"},
	{name = "Compact", desc = "Компактный", icon = "📐"},
	{name = "Rounded", desc = "Круглый неон", icon = "💠"},
}

local styleButtons = {}
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
	local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = THEMES[currentTheme].buttonHover
	end)
	btn.MouseLeave:Connect(function()
		if styleButtonRefs[preset.name] and styleButtonRefs[preset.name].selected then
			btn.BackgroundColor3 = THEMES[currentTheme].accent
		else
			btn.BackgroundColor3 = THEMES[currentTheme].button
		end
	end)

	btn.MouseButton1Click:Connect(function()
		-- Снять выделение со всех
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
	if preset.name == "Default" then
		btn.BackgroundColor3 = THEMES[currentTheme].accent
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

-- Применить дефолт
applyTheme("Тёмная")
applyStyle("Default")

-- ============================================================
-- MISC
-- ============================================================
local miscSection = createSection(miscPage, "SETTINGS", false)
local unloadBtn = createActionBtn(miscSection, "✕  Unload (убрать скрипт)", Color3.fromRGB(230, 80, 80))
local resetBtn = createActionBtn(miscSection, "↺  Сбросить настройки", Color3.fromRGB(160, 160, 200))

-- ============================================================
-- ФУНКЦИИ
-- ============================================================
function getCharacterParts()
	local char = player.Character
	if not char then return nil, nil, nil end
	return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

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

local function stopMagnet()
	magnetEnabled = false
	magnetTarget = nil
	if magnetConn then magnetConn:Disconnect() magnetConn = nil end
	local _, hrp, humanoid = getCharacterParts()
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = walkSpeedValue
		humanoid.JumpPower = jumpPowerValue
		humanoid.JumpHeight = 7.2
	end
	if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
	magnetStatusLabel.Text = "   Цель: нет"
end

function startMagnet(targetPlayer)
	if not targetPlayer then return end
	if targetPlayer == player then return end
	magnetEnabled = true
	magnetTarget = targetPlayer
	magnetStatusLabel.Text = "   Цель: " .. targetPlayer.Name

	local _, hrp, humanoid = getCharacterParts()
	if not hrp or not humanoid then return end
	humanoid.PlatformStand = true

	if magnetConn then magnetConn:Disconnect() end
	magnetConn = RunService.Heartbeat:Connect(function(dt)
		if unloaded or not magnetEnabled then return end
		if not magnetTarget then stopMagnet() return end
		local myChar, myHrp = getCharacterParts()
		if not myChar or not myHrp then return end
		local targetChar = magnetTarget.Character
		if not targetChar then stopMagnet() return end
		local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
		if not targetHrp then stopMagnet() return end
		local targetPos = targetHrp.Position - targetHrp.CFrame.LookVector * magnetDistance + Vector3.new(0, 2, 0)
		local current = myHrp.Position
		local diff = targetPos - current
		local dist = diff.Magnitude
		if dist > 0.5 then
			local step = math.min(dist, (dist * 8 + 10) * dt)
			myHrp.CFrame = CFrame.new(current + diff.Unit * step)
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
		if not UserInputService:IsKeyDown(aimbotKey) then
			aimbotTarget = nil
			if aimbotTargetLabel then aimbotTargetLabel.Text = "   Цель: —" end
			return
		end
		local char, hrp, humanoid = getCharacterParts()
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
			aimbotTarget = closest.player
			if aimbotTargetLabel then
				aimbotTargetLabel.Text = "   Цель: " .. closest.player.Name .. string.format(" (%.0f studs)", closest.dist)
			end
			local targetPos = closest.hrp.Position
			local currentCF = camera.CFrame
			local targetCF = CFrame.new(currentCF.Position, targetPos)
			camera.CFrame = currentCF:Lerp(targetCF, 1 - aimbotSmoothness)
		else
			aimbotTarget = nil
			if aimbotTargetLabel then aimbotTargetLabel.Text = "   Цель: —" end
		end
	end)
end
startAimbotLoop()

local function startTriggerbotLoop()
	if triggerbotConn then triggerbotConn:Disconnect() end
	triggerbotConn = RunService.Heartbeat:Connect(function(dt)
		if unloaded or not triggerbotEnabled then return end
		local now = tick()
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
							if dot > 0.95 then
								targetFound = true
								break
							end
						end
					end
				end
			end
		end
		if targetFound then
			triggerbotLastShot = now
			local tool = char:FindFirstChildOfClass("Tool")
			if tool then
				pcall(function() tool:Activate() end)
			end
		end
	end)
end
startTriggerbotLoop()

local magnetAllEndTime = 0

function startMagnetAll()
	if magnetAllConn then magnetAllConn:Disconnect() magnetAllConn = nil end
	magnetAllEndTime = (magnetAllHoldTime > 0) and (tick() + magnetAllHoldTime) or 0
	if magnetAllStatus then
		magnetAllStatus.Text = "   Magnet All: ВКЛ"
		magnetAllStatus.TextColor3 = THEMES[currentTheme].accent
	end
	magnetAllConn = RunService.Heartbeat:Connect(function(dt)
		if unloaded or not magnetAllEnabled then return end
		if magnetAllEndTime > 0 and tick() >= magnetAllEndTime then
			magnetAllEnabled = false
			if magnetAllToggle and toggleRefs[magnetAllToggle] then
				toggleRefs[magnetAllToggle].setState(false)
			end
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
								targetHrp.CFrame = CFrame.new(current + diff.Unit * step)
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
	if magnetAllStatus then
		magnetAllStatus.Text = "   Magnet All: ВЫКЛ"
		magnetAllStatus.TextColor3 = THEMES[currentTheme].text
	end
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
	humanoid.JumpHeight = 0
	local startPos = hrp.Position
	local endPos = targetPosition + Vector3.new(0, 3, 0)
	local liftPos = Vector3.new(startPos.X, startPos.Y + flyHeight, startPos.Z)
	local dropPos = Vector3.new(endPos.X, endPos.Y + flyHeight, endPos.Z)
	local function restore()
		if not flyEnabled then
			humanoid.PlatformStand = false
			humanoid.WalkSpeed = walkSpeedValue
			humanoid.JumpPower = jumpPowerValue
			humanoid.JumpHeight = 7.2
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
	hrp.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
	hrp.AssemblyLinearVelocity = Vector3.zero
end

-- ============================================================
-- КНОПКИ
-- ============================================================
table.insert(connections, saveBtn.MouseButton1Click:Connect(function()
	if unloaded then return end
	local _, hrp = getCharacterParts()
	if not hrp then return end
	savedPosition = hrp.Position
	saveBtn.Text = "    ✓  Сохранено!"
	task.wait(1)
	saveBtn.Text = "    📌  Запомнить координаты"
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
	instantSaveBtn.Text = "    ✓  Сохранено!"
	task.wait(1)
	instantSaveBtn.Text = "    📌  Запомнить координаты (Instant)"
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

table.insert(connections, stopMagnetBtn.MouseButton1Click:Connect(function()
	if unloaded then return end
	stopMagnet()
end))

table.insert(connections, refreshPlayersBtn.MouseButton1Click:Connect(function()
	if unloaded then return end
	refreshPlayersList()
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
end))

table.insert(connections, closeBtn.MouseButton1Click:Connect(function() window.Visible = false end))
table.insert(connections, minimizeBtn.MouseButton1Click:Connect(function() window.Visible = false end))

local function doUnload()
	if unloaded then return end
	unloaded = true
	flyEnabled = false
	if flyConn then flyConn:Disconnect() flyConn = nil end
	stopMagnet()
	stopMagnetAll()
	if aimbotConn then aimbotConn:Disconnect() aimbotConn = nil end
	if triggerbotConn then triggerbotConn:Disconnect() triggerbotConn = nil end
	for _, c in ipairs(connections) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	connections = {}
	if screenGui and screenGui.Parent then screenGui:Destroy() end
	print("[VIPMenu] Выгружено.")
end
table.insert(connections, unloadBtn.MouseButton1Click:Connect(doUnload))

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

-- ============================================================
-- КЛАВИШИ
-- ============================================================
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
		if magnetEnabled then stopMagnet() end
		return
	end

	for _, key in ipairs(toggleKeys) do
		if input.KeyCode == key then
			window.Visible = not window.Visible
			return
		end
	end

	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.End then
		doUnload()
	end
end))

switchTab("Info")
window.Visible = true

print("[VIPMenu] Готово. Клавиши: Insert / RightCtrl / F1 / RightShift")
