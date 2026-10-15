-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-- /Tob2 Da Hood Script  |  UI
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

-- ── Pull globals from core ────────────────────────────────
local Aim              = _G.Tob2Aim
local DaHood           = _G.Tob2DaHood
local Movement         = _G.Tob2Movement
local RapidFire        = _G.Tob2RapidFire
local ESP              = _G.Tob2ESP
local Users            = _G.Tob2Users
local Config           = _G.Tob2Config
local MenuSettings     = _G.Tob2MenuSettings
local THEME            = _G.Tob2THEME
local Players          = _G.Tob2Players
local TweenService     = _G.Tob2TweenService
local UserInputService = _G.Tob2UserInputService
local RunService       = _G.Tob2RunService
local Workspace        = _G.Tob2Workspace
local player           = _G.Tob2player
local playerGui        = _G.Tob2playerGui
local inputMatches     = _G.Tob2inputMatches

-- ── Constants ─────────────────────────────────────────────
local FONT      = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local HOVER_BG  = Color3.fromRGB(38, 38, 48)

-- ── UI helpers ────────────────────────────────────────────
local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function corner(p, r)
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p return c
end

local function stroke(p, color, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color           = color
	s.Thickness       = thick or 1
	s.Transparency    = trans or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent          = p
	return s
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font                   = FONT
	l.TextColor3             = THEME.Text
	l.TextSize               = 14
	l.BorderSizePixel        = 0
	for k, v in pairs(props) do l[k] = v end
	l.Parent = parent
	return l
end

-- ── Main GUI ──────────────────────────────────────────────
local existing = playerGui:FindFirstChild("Tob2UI")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name           = "Tob2UI"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 100
gui.Parent         = playerGui

local main = Instance.new("Frame")
main.Name             = "Main"
main.AnchorPoint      = Vector2.new(0.5, 0.5)
main.Position         = UDim2.fromScale(0.5, 0.5)
main.Size             = UDim2.fromOffset(460, 370)
main.BackgroundColor3 = THEME.Background
main.BorderSizePixel  = 0
main.ClipsDescendants = true
main.Parent           = gui
corner(main, 12)
stroke(main, THEME.Stroke, 1)

local uiScale = Instance.new("UIScale") uiScale.Scale = 0.85 uiScale.Parent = main

-- ── Toast notification system ─────────────────────────────
local toastGui = Instance.new("ScreenGui")
toastGui.Name           = "Tob2Toasts"
toastGui.ResetOnSpawn   = false
toastGui.IgnoreGuiInset = true
toastGui.DisplayOrder   = 200
toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toastGui.Parent         = playerGui

local activeToasts = 0

local function notify(title, message, duration)
	activeToasts += 1
	local slot = activeToasts

	local card = Instance.new("Frame")
	card.AnchorPoint      = Vector2.new(1, 1)
	card.Size             = UDim2.fromOffset(260, 52)
	card.Position         = UDim2.new(1, 300, 1, -14 - (slot - 1) * 62)
	card.BackgroundColor3 = THEME.Card
	card.BorderSizePixel  = 0
	card.ZIndex           = 10
	card.Parent           = toastGui
	corner(card, 8)
	stroke(card, THEME.Stroke, 1)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font        = FONT_BOLD
	titleLbl.TextSize    = 13
	titleLbl.TextColor3  = THEME.Text
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Position    = UDim2.new(0, 12, 0, 7)
	titleLbl.Size        = UDim2.new(1, -16, 0, 16)
	titleLbl.Text        = title
	titleLbl.ZIndex      = 11
	titleLbl.Parent      = card

	local msgLbl = Instance.new("TextLabel")
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font        = FONT
	msgLbl.TextSize    = 12
	msgLbl.TextColor3  = THEME.SubText
	msgLbl.TextXAlignment = Enum.TextXAlignment.Left
	msgLbl.Position    = UDim2.new(0, 12, 0, 27)
	msgLbl.Size        = UDim2.new(1, -16, 0, 16)
	msgLbl.Text        = message
	msgLbl.ZIndex      = 11
	msgLbl.Parent      = card

	-- slide in
	tween(card, 0.25, { Position = UDim2.new(1, -14, 1, -14 - (slot - 1) * 62) })

	task.delay(duration or 2.5, function()
		if not card.Parent then return end
		local t = tween(card, 0.25, { Position = UDim2.new(1, 300, 1, -14 - (slot - 1) * 62) })
		t.Completed:Connect(function()
			card:Destroy()
			activeToasts = math.max(0, activeToasts - 1)
		end)
	end)
end

-- ── Top bar ───────────────────────────────────────────────
local topBar = Instance.new("Frame")
topBar.Name             = "TopBar"
topBar.Size             = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = THEME.TopBar
topBar.BorderSizePixel  = 0
topBar.Parent           = main
corner(topBar, 12)

-- cover bottom corners of topBar
local topBarFill = Instance.new("Frame")
topBarFill.Position         = UDim2.new(0, 0, 1, -12)
topBarFill.Size             = UDim2.new(1, 0, 0, 12)
topBarFill.BackgroundColor3 = THEME.TopBar
topBarFill.BorderSizePixel  = 0
topBarFill.Parent           = topBar

local accentDot = Instance.new("Frame")
accentDot.Size             = UDim2.fromOffset(8, 8)
accentDot.Position         = UDim2.new(0, 16, 0.5, -4)
accentDot.BackgroundColor3 = THEME.Accent
accentDot.BorderSizePixel  = 0
accentDot.Parent           = topBar
corner(accentDot, 4)

label(topBar, {
	Name           = "Title",
	Text           = "/Tob2  •  Da Hood",
	Font           = FONT_BOLD,
	TextSize       = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position       = UDim2.new(0, 34, 0, 0),
	Size           = UDim2.new(1, -150, 1, 0),
})

local function topButton(name, xOffset)
	local b = Instance.new("TextButton")
	b.Name             = name
	b.AnchorPoint      = Vector2.new(1, 0.5)
	b.Position         = UDim2.new(1, xOffset, 0.5, 0)
	b.Size             = UDim2.fromOffset(26, 26)
	b.BackgroundColor3 = THEME.Card
	b.AutoButtonColor  = false
	b.Text             = ""
	b.Font             = FONT_BOLD
	b.TextSize         = 16
	b.TextColor3       = THEME.SubText
	b.BorderSizePixel  = 0
	b.Parent           = topBar
	corner(b, 7)
	return b
end

local closeBtn = topButton("Close", -10)
closeBtn.Text     = "X"
closeBtn.TextSize = 12
closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.15, { BackgroundColor3=Color3.fromRGB(200,60,70), TextColor3=THEME.Text    }) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.15, { BackgroundColor3=THEME.Card,                TextColor3=THEME.SubText }) end)

local minBtn = topButton("Minimize", -42)
minBtn.Text = "-"
minBtn.MouseEnter:Connect(function() tween(minBtn, 0.15, { BackgroundColor3=HOVER_BG,   TextColor3=THEME.Text    }) end)
minBtn.MouseLeave:Connect(function() tween(minBtn, 0.15, { BackgroundColor3=THEME.Card, TextColor3=THEME.SubText }) end)

local settingsBtn = topButton("Settings", -74)
do
	local gh = Instance.new("Frame")
	gh.AnchorPoint            = Vector2.new(0.5, 0.5)
	gh.Position               = UDim2.fromScale(0.5, 0.5)
	gh.Size                   = UDim2.fromOffset(16, 16)
	gh.BackgroundTransparency = 1
	gh.Parent                 = settingsBtn
	local gearParts = {}
	for i = 0, 3 do
		local t = Instance.new("Frame")
		t.AnchorPoint      = Vector2.new(0.5, 0.5)
		t.Position         = UDim2.fromScale(0.5, 0.5)
		t.Size             = UDim2.fromOffset(3, 16)
		t.Rotation         = i * 45
		t.BackgroundColor3 = THEME.SubText
		t.BorderSizePixel  = 0
		t.Parent           = gh
		corner(t, 1)
		table.insert(gearParts, t)
	end
	local gb = Instance.new("Frame")
	gb.AnchorPoint      = Vector2.new(0.5, 0.5)
	gb.Position         = UDim2.fromScale(0.5, 0.5)
	gb.Size             = UDim2.fromOffset(11, 11)
	gb.BackgroundColor3 = THEME.SubText
	gb.BorderSizePixel  = 0
	gb.Parent           = gh
	corner(gb, 6)
	table.insert(gearParts, gb)
	local ghole = Instance.new("Frame")
	ghole.AnchorPoint      = Vector2.new(0.5, 0.5)
	ghole.Position         = UDim2.fromScale(0.5, 0.5)
	ghole.Size             = UDim2.fromOffset(5, 5)
	ghole.BackgroundColor3 = THEME.Card
	ghole.BorderSizePixel  = 0
	ghole.Parent           = gh
	corner(ghole, 3)

	local function setGearColor(color)
		for _, p in ipairs(gearParts) do
			tween(p, 0.2, { BackgroundColor3 = color })
		end
	end

	settingsBtn.MouseEnter:Connect(function() setGearColor(THEME.Text)    end)
	settingsBtn.MouseLeave:Connect(function() setGearColor(THEME.SubText) end)

	local settingsOpen = false
	settingsBtn.Activated:Connect(function()
		settingsOpen = not settingsOpen
		if settingsOpen then
			setGearColor(THEME.Accent)
		else
			setGearColor(THEME.SubText)
		end
	end)
end

local topDivider = Instance.new("Frame")
topDivider.Size             = UDim2.new(1, 0, 0, 1)
topDivider.Position         = UDim2.new(0, 0, 0, 40)
topDivider.BackgroundColor3 = THEME.Stroke
topDivider.BorderSizePixel  = 0
topDivider.Parent           = main

-- ── Drag ──────────────────────────────────────────────────
do
	local dragging  = false
	local dragStart = nil
	local startPos  = nil
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = input.Position
			startPos  = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ── Tab bar ───────────────────────────────────────────────
local TAB_NAMES  = { "Home","Aim","ESP","Player","Users","Da Hood" }
local PAGE_NAMES = table.clone(TAB_NAMES)
table.insert(PAGE_NAMES, "Settings")

local tabBar = Instance.new("Frame")
tabBar.Name             = "TabBar"
tabBar.Position         = UDim2.new(0, 0, 0, 41)
tabBar.Size             = UDim2.new(1, 0, 0, 38)
tabBar.BackgroundColor3 = THEME.Background
tabBar.BorderSizePixel  = 0
tabBar.Parent           = main

do
	local d1 = Instance.new("Frame")
	d1.Size             = UDim2.new(1, 0, 0, 1)
	d1.BackgroundColor3 = THEME.Stroke
	d1.BorderSizePixel  = 0
	d1.Parent           = tabBar
	local d2 = Instance.new("Frame")
	d2.Position         = UDim2.new(0, 0, 1, -1)
	d2.Size             = UDim2.new(1, 0, 0, 1)
	d2.BackgroundColor3 = THEME.Stroke
	d2.BorderSizePixel  = 0
	d2.Parent           = tabBar
end

local indicator = Instance.new("Frame")
indicator.Name             = "Indicator"
indicator.Size             = UDim2.new(1 / #TAB_NAMES, -24, 0, 2)
indicator.Position         = UDim2.new(0, 12, 1, -2)
indicator.BackgroundColor3 = THEME.Accent
indicator.BorderSizePixel  = 0
indicator.ZIndex           = 2
indicator.Parent           = tabBar
corner(indicator, 1)

local pages = Instance.new("Frame")
pages.Name                = "Pages"
pages.Position            = UDim2.new(0, 0, 0, 80)
pages.Size                = UDim2.new(1, 0, 0, 290)
pages.BackgroundTransparency = 1
pages.ClipsDescendants    = true
pages.Parent              = main

local PAGE_INFO = {
	Home      = { "Dashboard",   "Live stats & quick info"                        },
	Aim       = { "Aim",         "Cam lock & silent aim"                          },
	ESP       = { "ESP",         "Player visuals"                                 },
	Player    = { "Player",      "Movement & combat"                              },
	Users     = { "Users",       "Pick a target"                                  },
	["Da Hood"]={ "Da Hood",     "Kill aura, stomp, dodge & more"                 },
	Settings  = { "Settings",    "Configs & keybinds"                             },
}

local pageFrames = {}
local tabButtons = {}

for i, name in ipairs(PAGE_NAMES) do
	local page = Instance.new("Frame")
	page.Name                = name
	page.Size                = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.Visible             = false
	page.Parent              = pages

	label(page, {
		Name           = "Header",
		Text           = PAGE_INFO[name][1],
		Font           = FONT_BOLD,
		TextSize       = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position       = UDim2.new(0, 20, 0, 16),
		Size           = UDim2.new(1, -40, 0, 24),
	})
	label(page, {
		Name       = "Sub",
		Text           = PAGE_INFO[name][2],
		TextSize       = 13,
		TextColor3     = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position       = UDim2.new(0, 20, 0, 42),
		Size           = UDim2.new(1, -40, 0, 18),
	})

	pageFrames[name] = page

	if i > #TAB_NAMES then continue end
	local btn = Instance.new("TextButton")
	btn.Name                   = name
	btn.Size                   = UDim2.new(1 / #TAB_NAMES, 0, 1, -1)
	btn.Position               = UDim2.new((i - 1) / #TAB_NAMES, 0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor        = false
	btn.Text                   = name
	btn.Font                   = FONT
	btn.TextSize               = 13
	btn.TextColor3             = THEME.SubText
	btn.BorderSizePixel        = 0
	btn.Parent                 = tabBar
	tabButtons[name] = btn
end

-- ── Scroll / row helpers ──────────────────────────────────
local refreshers  = {}
local rowOrder    = 0
local currentScroll

local function newScroll(page)
	local s = Instance.new("ScrollingFrame")
	s.Name                 = "Controls"
	s.Position             = UDim2.new(0, 0, 0, 68)
	s.Size                 = UDim2.new(1, 0, 1, -68)
	s.BackgroundTransparency = 1
	s.BorderSizePixel      = 0
	s.ScrollBarThickness   = 3
	s.ScrollBarImageColor3 = THEME.Accent
	s.CanvasSize           = UDim2.new()
	s.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	s.ScrollingDirection   = Enum.ScrollingDirection.Y
	s.Parent               = page
	local list = Instance.new("UIListLayout")
	list.Padding   = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent    = s
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 20)
	pad.PaddingRight  = UDim.new(0, 24)
	pad.PaddingTop    = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.Parent        = s
	currentScroll = s
	rowOrder      = 0
	return s
end

local function newRow(h)
	rowOrder += 1
	local row = Instance.new("Frame")
	row.LayoutOrder      = rowOrder
	row.Size             = UDim2.new(1, 0, 0, h or 34)
	row.BackgroundColor3 = THEME.Card
	row.BorderSizePixel  = 0
	row.Parent           = currentScroll
	corner(row, 8)
	stroke(row, THEME.Stroke, 1)
	return row
end

local function rowLabel(row, text)
	return label(row, {
		Text           = text,
		TextSize       = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position       = UDim2.new(0, 12, 0, 0),
		Size           = UDim2.new(0.55, 0, 0, 34),
	})
end

local function addHover(row, hit)
	hit.MouseEnter:Connect(function() tween(row, 0.15, { BackgroundColor3 = Color3.fromRGB(31,31,40) }) end)
	hit.MouseLeave:Connect(function() tween(row, 0.15, { BackgroundColor3 = THEME.Card              }) end)
end

local function section(text)
	rowOrder += 1
	label(currentScroll, {
		LayoutOrder    = rowOrder,
		Text           = string.upper(text),
		Font           = FONT_BOLD,
		TextSize       = 12,
		TextColor3     = THEME.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size           = UDim2.new(1, 0, 0, 22),
	})
end

local function addToggle(text, get, set)
	local row = newRow() rowLabel(row, text)
	local sw = Instance.new("Frame")
	sw.AnchorPoint      = Vector2.new(1, 0.5)
	sw.Position         = UDim2.new(1, -12, 0.5, 0)
	sw.Size             = UDim2.fromOffset(36, 18)
	sw.BackgroundColor3 = THEME.Stroke
	sw.BorderSizePixel  = 0
	sw.Parent           = row
	corner(sw, 9)
	local knob = Instance.new("Frame")
	knob.AnchorPoint      = Vector2.new(0, 0.5)
	knob.Position         = UDim2.new(0, 3, 0.5, 0)
	knob.Size             = UDim2.fromOffset(12, 12)
	knob.BackgroundColor3 = THEME.Text
	knob.BorderSizePixel  = 0
	knob.Parent           = sw
	corner(knob, 6)
	local hit = Instance.new("TextButton")
	hit.Size                   = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text                   = ""
	hit.ZIndex                 = 2
	hit.Parent                 = row
	addHover(row, hit)
	local function refresh()
		local on = get()
		tween(sw,   0.18, { BackgroundColor3 = on and THEME.Accent or THEME.Stroke })
		tween(knob, 0.18, { Position         = on and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
	end
	hit.Activated:Connect(function() set(not get()) refresh() end)
	table.insert(refreshers, refresh)
	refresh()
end

local function addSlider(text, min, max, step, get, set, fmt)
	local row = newRow(50) rowLabel(row, text)
	local vl = label(row, {
		Text           = "",
		TextSize       = 13,
		TextColor3     = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint    = Vector2.new(1, 0),
		Position       = UDim2.new(1, -12, 0, 0),
		Size           = UDim2.new(0.4, 0, 0, 34),
	})
	local track = Instance.new("Frame")
	track.Position         = UDim2.new(0, 12, 0, 36)
	track.Size             = UDim2.new(1, -24, 0, 4)
	track.BackgroundColor3 = THEME.Stroke
	track.BorderSizePixel  = 0
	track.Parent           = row
	corner(track, 2)
	local fill = Instance.new("Frame")
	fill.Size             = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = THEME.Accent
	fill.BorderSizePixel  = 0
	fill.Parent           = track
	corner(fill, 2)
	local knob = Instance.new("Frame")
	knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	knob.Position         = UDim2.fromScale(0, 0.5)
	knob.Size             = UDim2.fromOffset(12, 12)
	knob.BackgroundColor3 = THEME.Text
	knob.BorderSizePixel  = 0
	knob.ZIndex           = 2
	knob.Parent           = track
	corner(knob, 6)
	local function refresh()
		local v = get()
		local a = math.clamp((v - min) / (max - min), 0, 1)
		fill.Size     = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		vl.Text       = fmt and fmt(v) or tostring(v)
	end
	local function setFromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = min + a * (max - min)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		v = tonumber(string.format("%.4g", v))
		set(v) refresh()
	end
	local hit = Instance.new("TextButton")
	hit.Position               = UDim2.new(0, 0, 0, 26)
	hit.Size                   = UDim2.new(1, 0, 0, 24)
	hit.BackgroundTransparency = 1
	hit.Text                   = ""
	hit.ZIndex                 = 3
	hit.Parent                 = row
	addHover(row, hit)
	local dragging = false
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	table.insert(refreshers, refresh)
	refresh()
end

local function sideButton(row)
	local btn = Instance.new("TextButton")
	btn.AnchorPoint      = Vector2.new(1, 0.5)
	btn.Position         = UDim2.new(1, -8, 0.5, 0)
	btn.Size             = UDim2.fromOffset(110, 22)
	btn.BackgroundColor3 = THEME.Background
	btn.AutoButtonColor  = false
	btn.Font             = FONT
	btn.TextSize         = 12
	btn.TextColor3       = THEME.Text
	btn.BorderSizePixel  = 0
	btn.Parent           = row
	corner(btn, 6)
	stroke(btn, THEME.Stroke, 1)
	btn.MouseEnter:Connect(function() tween(btn, 0.15, { BackgroundColor3 = Color3.fromRGB(30,30,38)  }) end)
	btn.MouseLeave:Connect(function() tween(btn, 0.15, { BackgroundColor3 = THEME.Background          }) end)
	return btn
end

local function bindName(bind)
	if not bind then return "None" end
	return bind.Name:gsub("MouseButton", "Mouse")
end

local function addKeybind(text, get, set)
	local row     = newRow() rowLabel(row, text)
	local btn     = sideButton(row)
	local waiting = false
	local function refresh()
		btn.Text       = waiting and "Press a key..." or ("[ " .. bindName(get()) .. " ]")
		btn.TextColor3 = waiting and THEME.Accent or THEME.Text
	end
	btn.Activated:Connect(function()
		if waiting then return end
		waiting = true refresh()
		Aim.CaptureBind(function(bind)
			waiting = false
			if bind ~= nil then set(bind) end
			refresh()
		end)
	end)
	btn.MouseButton2Click:Connect(function()
		if not waiting then set(false) refresh() end
	end)
	table.insert(refreshers, refresh)
	refresh()
end

local function addCycle(text, options, get, set)
	local row = newRow() rowLabel(row, text)
	local btn = sideButton(row)
	local function refresh() btn.Text = get() end
	btn.Activated:Connect(function()
		local idx = table.find(options, get()) or 0
		set(options[idx % #options + 1])
		refresh()
	end)
	table.insert(refreshers, refresh)
	refresh()
end

local function addButton(text, onClick, danger)
	local row = newRow()
	local hit = Instance.new("TextButton")
	hit.Size                   = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Font                   = FONT
	hit.TextSize               = 13
	hit.Text                   = text
	hit.TextColor3             = danger and THEME.Danger or THEME.Text
	hit.Parent                 = row
	addHover(row, hit)
	hit.Activated:Connect(function()
		local flash = danger and THEME.Danger or THEME.Accent
		tween(row, 0.1, { BackgroundColor3 = flash })
		task.delay(0.12, function() tween(row, 0.25, { BackgroundColor3 = THEME.Card }) end)
		onClick()
	end)
end

local function addTextBox(placeholder, height, multiline)
	local row = newRow(height or 34)
	local rs  = row:FindFirstChildOfClass("UIStroke")
	local box = Instance.new("TextBox")
	box.Position          = UDim2.fromOffset(10, 5)
	box.Size              = UDim2.new(1, -20, 1, -10)
	box.BackgroundTransparency = 1
	box.Font              = FONT
	box.TextSize          = multiline and 11 or 13
	box.TextColor3        = THEME.Text
	box.PlaceholderColor3 = THEME.SubText
	box.PlaceholderText   = placeholder
	box.Text              = ""
	box.ClearTextOnFocus  = false
	box.TextXAlignment    = Enum.TextXAlignment.Left
	box.TextYAlignment    = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	box.MultiLine         = multiline or false
	box.TextWrapped       = multiline or false
	box.Parent            = row
	box.Focused:Connect(function()   if rs then tween(rs, 0.15, { Color = THEME.Accent }) end end)
	box.FocusLost:Connect(function() if rs then tween(rs, 0.15, { Color = THEME.Stroke }) end end)
	return box
end

local function addInfo(text)
	local row = newRow()
	return label(row, {
		Text           = text,
		TextSize       = 12,
		TextColor3     = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		Position       = UDim2.new(0, 12, 0, 0),
		Size           = UDim2.new(1, -24, 1, 0),
	})
end

local function newHolder()
	rowOrder += 1
	local h = Instance.new("Frame")
	h.LayoutOrder            = rowOrder
	h.Size                   = UDim2.new(1, 0, 0, 0)
	h.AutomaticSize          = Enum.AutomaticSize.Y
	h.BackgroundTransparency = 1
	h.BorderSizePixel        = 0
	h.Parent                 = currentScroll
	local l = Instance.new("UIListLayout")
	l.Padding   = UDim.new(0, 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent    = h
	return h
end

local function clearHolder(h)
	for _, c in ipairs(h:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end

local function addListRow(h, text, selected, onClick)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder      = #h:GetChildren()
	btn.Size             = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = THEME.Card
	btn.AutoButtonColor  = false
	btn.Font             = FONT
	btn.TextSize         = 13
	btn.TextXAlignment   = Enum.TextXAlignment.Left
	btn.TextColor3       = selected and THEME.Accent or THEME.Text
	btn.Text             = text
	btn.BorderSizePixel  = 0
	btn.Parent           = h
	corner(btn, 8)
	stroke(btn, selected and THEME.Accent or THEME.Stroke, 1)
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 12) pad.Parent = btn
	btn.MouseEnter:Connect(function() tween(btn, 0.15, { BackgroundColor3 = Color3.fromRGB(31,31,40) }) end)
	btn.MouseLeave:Connect(function() tween(btn, 0.15, { BackgroundColor3 = THEME.Card              }) end)
	btn.Activated:Connect(onClick)
end

-- format helpers
local function pct(v)  return v .. "%" end
local function px(v)   return v .. " px" end
local function sec(v)  return string.format("%.2fs", v) end
local function stud(v) return v .. " studs" end
local function rs(v)   return string.format("%.1f r/s", v) end

-- ── Setting aliases ───────────────────────────────────────
local CL = Aim.Settings.CamLock
local SA = Aim.Settings.SilentAim
local ES = ESP.Settings
local MS = Movement.Settings
local RF = RapidFire.Settings
local DS = DaHood.Settings

-- ── Tab switching ─────────────────────────────────────────
local currentPage = nil

local function switchTab(name)
	if currentPage and currentPage ~= name then
		pageFrames[currentPage].Visible = false
	end
	currentPage = name
	local page  = pageFrames[name]
	page.Visible = true

	local idx = table.find(TAB_NAMES, name) or 1
	tween(indicator, 0.2, { Position = UDim2.new((idx - 1) / #TAB_NAMES, 12, 1, -2) })

	for n, btn in pairs(tabButtons) do
		btn.TextColor3 = n == name and THEME.Accent or THEME.SubText
		btn.Font       = n == name and FONT_BOLD    or FONT
	end
	for _, r in ipairs(refreshers) do pcall(r) end
end

for name, btn in pairs(tabButtons) do
	btn.Activated:Connect(function() switchTab(name) end)
end

-- ── Window controls ───────────────────────────────────────
local minimized = false
local function setMinimized(state)
	minimized = state
	tween(main, 0.2, { Size = state and UDim2.fromOffset(460, 40) or UDim2.fromOffset(460, 370) })
end

closeBtn.Activated:Connect(function()
	tween(main, 0.15, { Size = UDim2.fromOffset(460, 0) })
	task.delay(0.2, function() gui:Destroy() toastGui:Destroy() end)
end)

minBtn.Activated:Connect(function() setMinimized(not minimized) end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or Aim.IsCapturing() then return end
	if inputMatches(input, MenuSettings.Bind) then
		main.Visible = not main.Visible
	end
end)

-- ── Page: Home ────────────────────────────────────────────
do
	newScroll(pageFrames["Home"])
	section("Server")
	addInfo("Toggle menu: Right Shift  •  Rebind in Settings")

	local gameRow  = addInfo("Game: " .. game.Name)
	local plrRow   = addInfo("Players: ...")
	local pingRow  = addInfo("Ping: ...")

	task.spawn(function()
		while true do
			pcall(function()
				plrRow.Text = "Players: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
				pingRow.Text = "Ping: " .. math.floor(player:GetNetworkPing() * 1000 + 0.5) .. " ms"
				gameRow.Text = "Game: " .. game.Name
			end)
			task.wait(1)
		end
	end)

	section("Tips")
	addInfo("Aim page: Camera Lock & Silent Aim")
	addInfo("Player page: Speed, Jump, Fly, Noclip")
	addInfo("Da Hood page: Kill Aura, Telekinesis & more")
end

-- ── Page: Aim ─────────────────────────────────────────────
newScroll(pageFrames["Aim"])
section("Camera Lock")
addToggle("Enabled",      function() return CL.Enabled    end, function(v) CL.Enabled    = v end)
addKeybind("Bind",        function() return CL.Bind       end, function(v) CL.Bind       = v end)
addCycle("Mode",          {"Toggle","Hold"}, function() return CL.Mode end, function(v) CL.Mode = v end)
addCycle("Target Part",   {"Head","Torso","HumanoidRootPart"}, function() return CL.TargetPart end, function(v) CL.TargetPart = v end)
addSlider("Smoothing",    0, 0.99, 0.01,       function() return CL.Smoothing  end, function(v) CL.Smoothing  = v end)
addSlider("FOV",          50, 2000, 10,
	function() return CL.FOV == math.huge and 2000 or CL.FOV end,
	function(v) CL.FOV = v == 2000 and math.huge or v end,
	function(v) return v == 2000 and "Inf" or tostring(v) end)
addToggle("Sticky Lock",  function() return CL.Sticky     end, function(v) CL.Sticky     = v end)
addToggle("Team Check",   function() return CL.TeamCheck  end, function(v) CL.TeamCheck  = v end)
addToggle("Wall Check",   function() return CL.WallCheck  end, function(v) CL.WallCheck  = v end)
addToggle("Auto Relock",  function() return CL.AutoRelock end, function(v) CL.AutoRelock = v end)
addSlider("Prediction",   0, 0.5, 0.01,        function() return CL.Prediction end, function(v) CL.Prediction = v end)

section("Silent Aim")
addToggle("Enabled",      function() return SA.Enabled    end, function(v) SA.Enabled    = v end)
addKeybind("Bind",        function() return SA.Bind       end, function(v) SA.Bind       = v end)
addCycle("Target Part",   {"Head","Torso","HumanoidRootPart"}, function() return SA.TargetPart end, function(v) SA.TargetPart = v end)
addSlider("FOV",          50, 500, 5,           function() return SA.FOV        end, function(v) SA.FOV        = v end, px)
addToggle("Show FOV",     function() return SA.ShowFOV    end, function(v) SA.ShowFOV    = v end)
addSlider("Hit Chance",   1, 100, 1,            function() return SA.HitChance  end, function(v) SA.HitChance  = v end, pct)
addSlider("Prediction",   0, 0.5, 0.01,         function() return SA.Prediction end, function(v) SA.Prediction = v end)
addToggle("Team Check",   function() return SA.TeamCheck  end, function(v) SA.TeamCheck  = v end)
addToggle("Wall Check",   function() return SA.WallCheck  end, function(v) SA.WallCheck  = v end)

-- ── Page: ESP ─────────────────────────────────────────────
newScroll(pageFrames["ESP"])
section("General")
addToggle("Enabled",      function() return ES.Enabled     end, function(v) ES.Enabled     = v end)
addKeybind("Bind",        function() return ES.Bind        end, function(v) ES.Bind        = v end)
addSlider("Max Distance", 100, 2000, 50, function() return ES.MaxDistance end, function(v) ES.MaxDistance = v end, stud)
section("Visuals")
addToggle("Box",          function() return ES.Box         end, function(v) ES.Box         = v end)
addToggle("Name",         function() return ES.Name        end, function(v) ES.Name        = v end)
addToggle("Distance",     function() return ES.Distance    end, function(v) ES.Distance    = v end)
addToggle("Health Bar",   function() return ES.Health      end, function(v) ES.Health      = v end)
addToggle("Outline",      function() return ES.Outline     end, function(v) ES.Outline     = v end)
addToggle("Fill",         function() return ES.Fill        end, function(v) ES.Fill        = v end)
addToggle("Tracers",      function() return ES.Tracers     end, function(v) ES.Tracers     = v end)
addCycle("Tracer Origin", {"Bottom","Center"}, function() return ES.TracerOrigin end, function(v) ES.TracerOrigin = v end)
addCycle("Color",         ESP.ColorNames,      function() return ES.Color        end, function(v) ES.Color        = v end)
section("Team")
addToggle("Team Check",   function() return ES.TeamCheck   end, function(v) ES.TeamCheck   = v end)
addToggle("Team Colors",  function() return ES.TeamColors  end, function(v) ES.TeamColors  = v end)

-- ── Page: Player ──────────────────────────────────────────
newScroll(pageFrames["Player"])
section("Walk Speed")
addToggle("Enabled",      function() return MS.WalkSpeedOn         end, function(v) MS.WalkSpeedOn         = v end)
addSlider("Speed",        16, 200, 1,  function() return MS.WalkSpeed            end, function(v) MS.WalkSpeed            = v end)
addKeybind("Hold Bind",   function() return MS.WalkSpeedBind       end, function(v) MS.WalkSpeedBind       = v end)
addSlider("Hold Speed",   16, 500, 1,  function() return MS.WalkSpeedBindAmount   end, function(v) MS.WalkSpeedBindAmount   = v end)
section("Jump")
addToggle("Jump Power",   function() return MS.JumpPowerOn         end, function(v) MS.JumpPowerOn         = v end)
addSlider("Power",        50, 500, 5,  function() return MS.JumpPower             end, function(v) MS.JumpPower             = v end)
addToggle("Infinite Jump",function() return MS.InfiniteJump        end, function(v) MS.InfiniteJump        = v end)
section("Fly")
addToggle("Fly",          function() return MS.Fly                 end, function(v) MS.Fly                 = v end)
addKeybind("Fly Bind",    function() return MS.FlyBind             end, function(v) MS.FlyBind             = v end)
addSlider("Fly Speed",    10, 300, 5,  function() return MS.FlySpeed              end, function(v) MS.FlySpeed              = v end)
section("Misc")
addToggle("Noclip",       function() return MS.Noclip              end, function(v) MS.Noclip              = v end)
addToggle("Gravity",      function() return MS.GravityOn           end, function(v) MS.GravityOn           = v end)
addSlider("Gravity Value",0, 200, 5,   function() return MS.Gravity               end, function(v) MS.Gravity               = v end)
addToggle("Custom FOV",   function() return MS.FOVOn               end, function(v) MS.FOVOn               = v end)
addSlider("FOV",          30, 120, 1,  function() return MS.FOV                   end, function(v) MS.FOV                   = v end)
addButton("Reset Movement", function()
	Movement.Reset()
	for _, r in ipairs(refreshers) do pcall(r) end
end)

-- ── Page: Users ───────────────────────────────────────────
newScroll(pageFrames["Users"])
section("Target")
local infoRow    = addInfo("No target selected")
local userHolder = newHolder()
local searchBox

local function refreshUsers()
	clearHolder(userHolder)
	local query = searchBox and searchBox.Text or ""
	local list  = Users.Search(query)
	if #list == 0 then
		addListRow(userHolder, "No players found", false, function() end)
		return
	end
	for _, plr in ipairs(list) do
		local sel = plr == Users.Target
		addListRow(userHolder, plr.DisplayName .. " (@" .. plr.Name .. ")", sel, function()
			Users.SetTarget(plr)
			refreshUsers()
		end)
	end
end

searchBox = addTextBox("Search players...")
searchBox:GetPropertyChangedSignal("Text"):Connect(refreshUsers)
refreshUsers()

section("Actions")
addButton("Teleport to Target", function() Users.Teleport() end)
addToggle("Spectate",  function() return Users.Spectating end, function(v) Users.SetSpectating(v) end)
addToggle("Follow",    function() return Users.Following  end, function(v) Users.SetFollowing(v)  end)
addButton("← Prev",   function() Users.Cycle(-1) refreshUsers() end)
addButton("Next →",   function() Users.Cycle(1)  refreshUsers() end)

RunService.Heartbeat:Connect(function()
	if currentPage == "Users" then
		infoRow.Text = Users.Info()
	end
end)
Players.PlayerAdded:Connect(refreshUsers)
Players.PlayerRemoving:Connect(function() task.defer(refreshUsers) end)

-- ── Page: Da Hood ─────────────────────────────────────────
newScroll(pageFrames["Da Hood"])
section("Kill Aura")
addToggle("Enabled",       function() return DS.KillAuraEnabled    end, function(v) DS.KillAuraEnabled    = v end)
addKeybind("Bind",         function() return DS.KillAuraBind       end, function(v) DS.KillAuraBind       = v end)
addSlider("Radius",        1, 20,  0.5,   function() return DS.KillAuraRadius    end, function(v) DS.KillAuraRadius    = v end, stud)
addSlider("Orbit Speed",   1, 20,  0.5,   function() return DS.KillAuraSpeed     end, function(v) DS.KillAuraSpeed     = v end, rs)
addSlider("Height",       -5, 10,  0.5,   function() return DS.KillAuraHeight    end, function(v) DS.KillAuraHeight    = v end)
addSlider("Stomp Rate",   0.01, 0.5, 0.01,function() return DS.StompRate         end, function(v) DS.StompRate         = v end, sec)

section("Orbit")
addToggle("Enabled",       function() return DS.OrbitEnabled       end, function(v) DS.OrbitEnabled       = v end)
addKeybind("Bind",         function() return DS.OrbitBind          end, function(v) DS.OrbitBind          = v end)
addSlider("Radius",        1, 20, 0.5,    function() return DS.OrbitRadius        end, function(v) DS.OrbitRadius        = v end, stud)
addSlider("Speed",         1, 20, 0.5,    function() return DS.OrbitSpeed         end, function(v) DS.OrbitSpeed         = v end, rs)
addSlider("Height",       -5, 10, 0.5,    function() return DS.OrbitHeight        end, function(v) DS.OrbitHeight        = v end)

section("Arrest Dodge")
addToggle("Enabled",       function() return DS.ArrestDodgeEnabled end, function(v) DS.ArrestDodgeEnabled = v end)
addKeybind("Bind",         function() return DS.ArrestDodgeBind    end, function(v) DS.ArrestDodgeBind    = v end)
addSlider("Distance",      5, 100, 5,     function() return DS.ArrestDodgeDist    end, function(v) DS.ArrestDodgeDist    = v end, stud)

section("Telekinesis")
addToggle("Enabled",       function() return DS.TelekinesisEnabled end, function(v) DS.TelekinesisEnabled = v end)
addKeybind("Bind",         function() return DS.TelekinesisBind    end, function(v) DS.TelekinesisBind    = v end)
addSlider("Force",         10, 200, 5,    function() return DS.TelekinesisForce   end, function(v) DS.TelekinesisForce   = v end, stud)

section("Misc")
addToggle("Infinite Ammo", function() return DS.InfiniteAmmoEnabled end, function(v) DS.InfiniteAmmoEnabled = v end)
addToggle("No Ragdoll",    function() return DS.NoRagdollEnabled   end, function(v) DS.NoRagdollEnabled   = v end)
addKeybind("No Ragdoll Bind",  function() return DS.NoRagdollBind  end, function(v) DS.NoRagdollBind      = v end)
addToggle("Auto Revive",   function() return DS.AutoReviveEnabled  end, function(v) DS.AutoReviveEnabled  = v end)
addKeybind("Auto Revive Bind", function() return DS.AutoReviveBind end, function(v) DS.AutoReviveBind     = v end)
addSlider("Revive Dist",   1, 20, 1,      function() return DS.AutoReviveDist     end, function(v) DS.AutoReviveDist     = v end, stud)
addToggle("Auto Bag",      function() return DS.AutoBagEnabled     end, function(v) DS.AutoBagEnabled     = v end)
addKeybind("Auto Bag Bind",    function() return DS.AutoBagBind    end, function(v) DS.AutoBagBind        = v end)
addKeybind("Jail Escape Bind", function() return DS.JailEscapeBind end, function(v) DS.JailEscapeBind    = v end)
addToggle("Speed Boost on Kill",  function() return DS.SpeedBoostEnabled  end, function(v) DS.SpeedBoostEnabled  = v end)
addSlider("Boost Speed",   20, 200, 5,    function() return DS.SpeedBoostAmount   end, function(v) DS.SpeedBoostAmount   = v end)
addSlider("Duration",      0.5, 10, 0.5,  function() return DS.SpeedBoostDuration end, function(v) DS.SpeedBoostDuration = v end,
	function(v) return string.format("%.1f sec", v) end)

section("Rapid Fire")
addToggle("Enabled",       function() return RF.Enabled  end, function(v) RF.Enabled  = v Aim.SetRapidFire(v, RF.FireRate) end)
addKeybind("Bind",         function() return RF.Bind     end, function(v) RF.Bind     = v end)
addSlider("Fire Rate",     0.01, 0.3, 0.01, function() return RF.FireRate end, function(v) RF.FireRate = v end, sec)

-- ── Page: Settings ────────────────────────────────────────
newScroll(pageFrames["Settings"])
section("Menu")
addKeybind("Toggle Bind", function() return MenuSettings.Bind end, function(v) MenuSettings.Bind = v end)

section("Config")
local configNameBox = addTextBox("Config name...")
addButton("Save Config", function()
	local name = configNameBox.Text
	if name and name ~= "" then Config.Save(name) end
end)
addButton("Load Config", function()
	local name = configNameBox.Text
	if name then
		Config.Load(name)
		for _, r in ipairs(refreshers) do pcall(r) end
	end
end)
addButton("Delete Config", function()
	local name = configNameBox.Text
	if name then Config.Delete(name) end
end, true)
addButton("Reset All", function()
	Config.ResetAll()
	for _, r in ipairs(refreshers) do pcall(r) end
end, true)

section("Export / Import")
local exportBox = addTextBox("Paste config JSON here...", 60, true)
addButton("Export", function()
	exportBox.Text = Config.Export()
end)
addButton("Import", function()
	local ok2, msg = Config.Import(exportBox.Text)
	if ok2 then for _, r in ipairs(refreshers) do pcall(r) end end
	exportBox.Text = msg
end)

-- ── Changed event sync + toast notifications ──────────────
local function refreshAll()
	for _, r in ipairs(refreshers) do pcall(r) end
end

local function onOff(v) return v and "ON" or "OFF" end

Aim.Changed:Connect(function(module, key, value)
	refreshAll()
	if module == "CamLock"  and key == "Enabled" then notify("Camera Lock",  onOff(value), 2) end
	if module == "SilentAim" and key == "Enabled" then notify("Silent Aim",  onOff(value), 2) end
end)

ESP.Changed:Connect(function()
	refreshAll()
	notify("ESP", onOff(ES.Enabled), 2)
end)

Movement.Changed:Connect(function()
	refreshAll()
	notify("Fly", onOff(MS.Fly), 2)
end)

RapidFire.Changed:Connect(function()
	refreshAll()
	notify("Rapid Fire", onOff(RF.Enabled), 2)
end)

DaHood.Changed:Connect(function()
	refreshAll()
	notify("Kill Aura",   onOff(DS.KillAuraEnabled),    2)
end)

Users.Changed:Connect(function()
	refreshAll()
	if currentPage == "Users" then refreshUsers() end
end)

-- ── Open on Home ──────────────────────────────────────────
switchTab("Home")
