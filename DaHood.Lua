-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-- /Tob2 Da Hood Script  |  Core
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

local function showError(msg)
	warn("[Tob2] " .. tostring(msg))
	pcall(function()
		local pg  = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		local old = pg:FindFirstChild("Tob2Error")
		if old then old:Destroy() end
		local eg = Instance.new("ScreenGui")
		eg.Name           = "Tob2Error"
		eg.ResetOnSpawn   = false
		eg.DisplayOrder   = 999
		eg.IgnoreGuiInset = true
		eg.Parent         = pg
		local bg = Instance.new("Frame")
		bg.AnchorPoint      = Vector2.new(0.5, 0)
		bg.Position         = UDim2.new(0.5, 0, 0, 12)
		bg.Size             = UDim2.new(0.9, 0, 0, 0)
		bg.AutomaticSize    = Enum.AutomaticSize.Y
		bg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
		bg.BorderSizePixel  = 0
		bg.Parent           = eg
		local co = Instance.new("UICorner") co.CornerRadius = UDim.new(0, 8) co.Parent = bg
		local lbl = Instance.new("TextLabel")
		lbl.Size                   = UDim2.new(1, -16, 0, 0)
		lbl.Position               = UDim2.fromOffset(8, 8)
		lbl.AutomaticSize          = Enum.AutomaticSize.Y
		lbl.BackgroundTransparency = 1
		lbl.Font                   = Enum.Font.GothamMedium
		lbl.TextSize               = 13
		lbl.TextColor3             = Color3.fromRGB(255, 100, 100)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.TextWrapped            = true
		lbl.Text                   = "[Tob2] Error:\n" .. tostring(msg)
		lbl.Parent                 = bg
	end)
end

local ok, err = pcall(function()

-- ── Services ──────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local HttpService      = game:GetService("HttpService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VU = nil
pcall(function() VU = game:GetService("VirtualUser") end)

-- ── Config ────────────────────────────────────────────────
local AUTOLOAD_CONFIG = ""
local MenuSettings    = { Bind = Enum.KeyCode.RightShift }

local THEME = {
	Background = Color3.fromRGB(18,  18,  24),
	TopBar     = Color3.fromRGB(22,  22,  30),
	Card       = Color3.fromRGB(26,  26,  34),
	Stroke     = Color3.fromRGB(45,  45,  58),
	Accent     = Color3.fromRGB(124, 92,  255),
	Text       = Color3.fromRGB(240, 240, 245),
	SubText    = Color3.fromRGB(140, 140, 160),
	Danger     = Color3.fromRGB(235, 64,  72),
}

-- ── Helpers ───────────────────────────────────────────────
local function inputMatches(input, bind)
	if not bind then return false end
	if bind.EnumType == Enum.KeyCode then return input.KeyCode == bind end
	return input.UserInputType == bind
end

local function getChar()
	local c = player.Character
	return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function clickMouse()
	if not VU then return end
	pcall(function()
		local ml = UserInputService:GetMouseLocation()
		local cf = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()
		VU:Button1Down(ml, cf)
		task.delay(0.05, function() pcall(function() VU:Button1Up(ml, cf) end) end)
	end)
end

-- ── Aim Module ────────────────────────────────────────────
local Aim = (function()
	local M = {}
	M.Settings = {
		CamLock   = { Enabled=false, Bind=Enum.KeyCode.Q,  Mode="Toggle", TargetPart="Head", Smoothing=0,   FOV=math.huge, TeamCheck=false, WallCheck=true,  Sticky=true,  Prediction=0.1, AutoRelock=true  },
		SilentAim = { Enabled=false, Bind=Enum.KeyCode.Z,  TargetPart="Head", FOV=250, ShowFOV=true, TeamCheck=false, WallCheck=false, HitChance=100, Prediction=0.1 },
	}

	local CL      = M.Settings.CamLock
	local SA      = M.Settings.SilentAim
	local changed = Instance.new("BindableEvent")
	M.Changed     = changed.Event

	local function getPart(char, name)
		if name == "Head"  then return char:FindFirstChild("Head")       or char:FindFirstChild("HumanoidRootPart") end
		if name == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") end
		return char:FindFirstChild("HumanoidRootPart")
	end

	local function isEnemy(other, teamCheck)
		if not teamCheck then return true end
		local ok2, same = pcall(function() return player.Team ~= nil and other.Team == player.Team end)
		if ok2 and same then return false end
		return true
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType  = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local function isVisible(part, char)
		local cam = Workspace.CurrentCamera
		if not cam then return false end
		rayParams.FilterDescendantsInstances = player.Character and { player.Character } or {}
		local result = Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, rayParams)
		return not result or result.Instance:IsDescendantOf(char)
	end

	local function getMousePos()
		local cam = Workspace.CurrentCamera
		if cam and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			return cam.ViewportSize / 2
		end
		return UserInputService:GetMouseLocation()
	end

	local function findTarget(cfg, excludeChar)
		local cam = Workspace.CurrentCamera
		if not cam then return nil end
		local mousePos = getMousePos()
		local best, bestDist = nil, cfg.FOV
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and isEnemy(other, cfg.TeamCheck) then
				local char = other.Character
				if char and char ~= excludeChar then
					local hum  = char:FindFirstChildOfClass("Humanoid")
					local part = getPart(char, cfg.TargetPart)
					if hum and hum.Health > 0 and part then
						local screen, onScreen = cam:WorldToViewportPoint(part.Position)
						if onScreen then
							local dist = (Vector2.new(screen.X, screen.Y) - mousePos).Magnitude
							if dist < bestDist and (not cfg.WallCheck or isVisible(part, char)) then
								best, bestDist = part, dist
							end
						end
					end
				end
			end
		end
		return best
	end

	local function isAlive(part)
		if not part or not part.Parent then return false end
		local hum = part.Parent:FindFirstChildOfClass("Humanoid")
		return hum ~= nil and hum.Health > 0
	end

	local function aimPos(part, cfg)
		local vel = Vector3.zero
		pcall(function() vel = part.AssemblyLinearVelocity end)
		return part.Position + vel * cfg.Prediction
	end

	-- public aim API
	function M.GetSilentTarget()
		if not SA.Enabled then return nil end
		if math.random(1, 100) > SA.HitChance then return nil end
		return findTarget(SA)
	end

	function M.GetAimPoint(def)
		local p = M.GetSilentTarget()
		return p and aimPos(p, SA) or def
	end

	function M.RedirectShot(origin, dir)
		local p = M.GetSilentTarget()
		if not p then return dir end
		local to = aimPos(p, SA) - origin
		if to.Magnitude < 1e-3 then return dir end
		return to.Unit * dir.Magnitude
	end

	-- FireServer hook (silent aim + rapid fire)
	local function isDir(v)
		if typeof(v) ~= "Vector3" then return false end
		local m = v.Magnitude
		return m > 0.01 and m < 5
	end
	local function isPos(v)
		if typeof(v) ~= "Vector3" then return false end
		return v.Magnitude >= 5
	end

	local function redirectArgs(args, tp)
		local hasDir = false
		for _, a in ipairs(args) do if isDir(a) then hasDir = true break end end
		for i, arg in ipairs(args) do
			if isDir(arg) then
				local origin = Vector3.zero
				for j = 1, i - 1 do if isPos(args[j]) then origin = args[j] break end end
				local to = tp - origin
				if to.Magnitude > 0.01 then args[i] = to.Unit * arg.Magnitude end
			elseif not hasDir and typeof(arg) == "Vector3" and isPos(arg) then
				args[i] = tp
			end
		end
	end

	-- rapid fire state
	local rfEnabled = false
	local rfRate    = 0.05
	local rfShots   = {}

	-- Silent aim + rapid fire: hook FireServer
	-- hookfunction(f, replacement) replaces f and returns the original callable.
	-- We must call the RETURNED original to avoid infinite recursion.
	local fireServerOriginal  -- will hold the trampoline returned by hookfunction
	pcall(function()
		local temp = Instance.new("RemoteEvent")
		local method = temp.FireServer
		temp:Destroy()
		fireServerOriginal = hookfunction(method, newcclosure(function(self, ...)
			local args = { ... }
			-- silent aim
			if SA.Enabled and math.random(1, 100) <= SA.HitChance then
				local target = findTarget(SA)
				if target then redirectArgs(args, aimPos(target, SA)) end
			end
			-- rapid fire snapshot (record last-fired args for replay)
			if rfEnabled then
				rfShots[tostring(self)] = {
					remote = self,
					args   = table.pack(table.unpack(args)),
					last   = tick(),
				}
			end
			-- call original via trampoline — NOT via the hooked method
			return fireServerOriginal(self, table.unpack(args))
		end))
	end)

	-- rapid fire heartbeat loop
	RunService.Heartbeat:Connect(function()
		if not rfEnabled then
			if next(rfShots) then table.clear(rfShots) end
			return
		end
		if not fireServerOriginal then return end
		local now = tick()
		for _, data in pairs(rfShots) do
			if now - data.last >= rfRate then
				data.last = now
				pcall(function()
					local args = { table.unpack(data.args, 1, data.args.n) }
					if SA.Enabled then
						local t = findTarget(SA)
						if t then redirectArgs(args, aimPos(t, SA)) end
					end
					fireServerOriginal(data.remote, table.unpack(args))
				end)
			end
		end
	end)

	function M.SetRapidFire(enabled, rate)
		rfEnabled = enabled
		if rate then rfRate = rate end
	end

	-- keybind capture
	local captureCallback   = nil
	local capturedThisFrame = false
	local holding           = false

	function M.CaptureBind(cb) captureCallback = cb end
	function M.IsCapturing() return captureCallback ~= nil or capturedThisFrame end

	local function matchBind(input, bind)
		if not bind then return false end
		if bind.EnumType == Enum.KeyCode then return input.KeyCode == bind end
		return input.UserInputType == bind
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		if captureCallback then
			local cb    = captureCallback
			local result, done = nil, false
			if input.UserInputType == Enum.UserInputType.Keyboard then
				done = true
				if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					result = false
				elseif input.KeyCode ~= Enum.KeyCode.Escape then
					result = input.KeyCode
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2
			    or input.UserInputType == Enum.UserInputType.MouseButton3 then
				done   = true
				result = input.UserInputType
			end
			if done then
				captureCallback   = nil
				capturedThisFrame = true
				task.defer(function() capturedThisFrame = false end)
				cb(result)
			end
			return
		end
		if gp then return end
		if matchBind(input, CL.Bind) then
			if CL.Mode == "Toggle" then
				CL.Enabled = not CL.Enabled
				if not CL.Enabled then M.ClearLock() end
				changed:Fire("CamLock", "Enabled", CL.Enabled)
			else
				holding = true
			end
		end
		if matchBind(input, SA.Bind) then
			SA.Enabled = not SA.Enabled
			changed:Fire("SilentAim", "Enabled", SA.Enabled)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if matchBind(input, CL.Bind) then
			holding = false
			if CL.Mode ~= "Toggle" then M.ClearLock() end
		end
	end)

	-- camlock state
	local lockedTarget   = nil
	local lockedDiedConn = nil

	function M.ClearLock()
		if lockedDiedConn then lockedDiedConn:Disconnect() lockedDiedConn = nil end
		lockedTarget = nil
	end

	local function lockOnto(part)
		M.ClearLock()
		lockedTarget = part
		local hum = part and part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if hum then
			lockedDiedConn = hum.Died:Connect(function()
				M.ClearLock()
				if not CL.AutoRelock then
					CL.Enabled = false
					changed:Fire("CamLock", "Enabled", false)
				end
			end)
		end
	end

	-- FOV / lock dot GUIs
	do
		local fovGui = playerGui:FindFirstChild("AimFOV")
		if fovGui then fovGui:Destroy() end
		fovGui = Instance.new("ScreenGui")
		fovGui.Name           = "AimFOV"
		fovGui.ResetOnSpawn   = false
		fovGui.IgnoreGuiInset = true
		fovGui.DisplayOrder   = 50
		fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		fovGui.Parent         = playerGui

		local silentCircle = Instance.new("Frame")
		silentCircle.AnchorPoint            = Vector2.new(0.5, 0.5)
		silentCircle.BackgroundTransparency = 1
		silentCircle.BorderSizePixel        = 0
		silentCircle.Visible                = false
		silentCircle.Parent                 = fovGui
		do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.5, 0) c.Parent = silentCircle end
		do local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(70,190,255) s.Thickness = 1.5 s.Transparency = 0.25 s.Parent = silentCircle end

		local lockDot = Instance.new("Frame")
		lockDot.AnchorPoint      = Vector2.new(0.5, 0.5)
		lockDot.Size             = UDim2.fromOffset(10, 10)
		lockDot.BackgroundColor3 = Color3.fromRGB(124, 92, 255)
		lockDot.BorderSizePixel  = 0
		lockDot.Visible          = false
		lockDot.ZIndex           = 10
		lockDot.Parent           = fovGui
		do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.5, 0) c.Parent = lockDot end
		do local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(255,255,255) s.Thickness = 1 s.Transparency = 0.5 s.Parent = lockDot end

		RunService:BindToRenderStep("AimAssist", Enum.RenderPriority.Camera.Value + 1, function(dt)
			silentCircle.Visible = SA.Enabled and SA.ShowFOV
			if silentCircle.Visible then
				local m = getMousePos()
				silentCircle.Position = UDim2.fromOffset(m.X, m.Y)
				silentCircle.Size     = UDim2.fromOffset(SA.FOV * 2, SA.FOV * 2)
			end

			local cam    = Workspace.CurrentCamera
			local active = CL.Enabled and (CL.Mode == "Toggle" or holding)
			if not active or not cam then
				lockDot.Visible = false
				return
			end

			if lockedTarget and not isAlive(lockedTarget) then M.ClearLock() end

			-- Sticky: only find a new target when we have none
			if not lockedTarget then
				local f = findTarget(CL)
				if f then lockOnto(f) end
			elseif not CL.Sticky then
				-- Non-sticky: re-evaluate best target every frame
				local f = findTarget(CL)
				if f and f ~= lockedTarget then lockOnto(f) end
			end

			if not lockedTarget then lockDot.Visible = false return end

			local sp, on = cam:WorldToViewportPoint(lockedTarget.Position)
			lockDot.Visible = on
			if on then lockDot.Position = UDim2.fromOffset(sp.X, sp.Y) end

			local goal  = CFrame.lookAt(cam.CFrame.Position, aimPos(lockedTarget, CL))
			local alpha = CL.Smoothing > 0 and (1 - CL.Smoothing ^ (dt * 60)) or 1
			cam.CFrame  = cam.CFrame:Lerp(goal, alpha)
		end)
	end

	return M
end)()
_G.Tob2Aim = Aim

-- ── Da Hood Module ────────────────────────────────────────
local DaHood = (function()
	local M = {}
	M.Settings = {
		KillAuraEnabled    = false, KillAuraBind    = Enum.KeyCode.K, KillAuraRadius = 3,  KillAuraSpeed = 4, KillAuraHeight = 0.5, StompRate = 0.08,
		OrbitEnabled       = false, OrbitBind       = Enum.KeyCode.O, OrbitRadius    = 5,  OrbitSpeed    = 3, OrbitHeight    = 0,
		ArrestDodgeEnabled = false, ArrestDodgeBind = Enum.KeyCode.J, ArrestDodgeDist= 30,
		NoRagdollEnabled   = false, NoRagdollBind   = Enum.KeyCode.N,
		AutoReviveEnabled  = false, AutoReviveBind  = Enum.KeyCode.V, AutoReviveDist = 6,
		AutoBagEnabled     = false, AutoBagBind     = Enum.KeyCode.B,
		JailEscapeBind     = Enum.KeyCode.P,
		Target             = nil,
		-- Telekinesis
		TelekinesisEnabled = false, TelekinesisBind = Enum.KeyCode.T, TelekinesisForce = 60,
		-- Speed Boost on Kill
		SpeedBoostEnabled  = false, SpeedBoostAmount = 80, SpeedBoostDuration = 2.5,
	}
	local DS      = M.Settings
	local changed = Instance.new("BindableEvent")
	M.Changed     = changed.Event

	local orbitAngle = 0
	local lastStomp  = 0

	local BAG_NAMES = { "MoneyBag","Money Bag","moneybag","CashBag","Cash Bag","Bag","bag" }

	local function findNearest()
		local _, _, myRoot = getChar()
		if not myRoot then return nil end
		local best, bestDist = nil, math.huge
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local char = other.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum  = char and char:FindFirstChildOfClass("Humanoid")
				if root and hum and hum.Health > 0 then
					local dist = (root.Position - myRoot.Position).Magnitude
					if dist < bestDist then best = other bestDist = dist end
				end
			end
		end
		return best
	end

	local function findBags()
		local bags = {}
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") or obj:IsA("Model") then
				for _, name in ipairs(BAG_NAMES) do
					if obj.Name:lower():find(name:lower(), 1, true) then
						table.insert(bags, obj) break
					end
				end
			end
		end
		return bags
	end

	-- Telekinesis state
	local tkHolding = false

	-- Speed Boost on Kill: hook enemy Humanoid.Died for each player
	local function hookSpeedBoost(other)
		if other == player then return end
		local function hookChar(char)
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			hum.Died:Connect(function()
				if not DS.SpeedBoostEnabled then return end
				local myChar = player.Character
				local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
				if not myHum or myHum.Health <= 0 then return end
				pcall(function()
					local orig = myHum.WalkSpeed
					myHum.WalkSpeed = DS.SpeedBoostAmount
					task.delay(DS.SpeedBoostDuration, function()
						pcall(function()
							if myHum and myHum.Parent then
								myHum.WalkSpeed = orig
							end
						end)
					end)
				end)
			end)
		end
		hookChar(other.Character)
		other.CharacterAdded:Connect(hookChar)
	end

	for _, other in ipairs(Players:GetPlayers()) do hookSpeedBoost(other) end
	Players.PlayerAdded:Connect(hookSpeedBoost)

	RunService.Heartbeat:Connect(function(dt)
		local _, hum, myRoot = getChar()
		if not myRoot or not hum or hum.Health <= 0 then return end

		if DS.NoRagdollEnabled then
			pcall(function()
				local state = hum:GetState()
				if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end

		if DS.ArrestDodgeEnabled then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player then
					local oChar = other.Character
					local oRoot = oChar and oChar:FindFirstChild("HumanoidRootPart")
					if oRoot and (oRoot.Position - myRoot.Position).Magnitude < 5.5 then
						myRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, DS.ArrestDodgeDist)
					end
				end
			end
		end

		if DS.KillAuraEnabled then
			local target = findNearest()
			if target then
				local tChar = target.Character
				local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
				local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")
				if tRoot and tHum and tHum.Health > 0 then
					orbitAngle = orbitAngle + DS.KillAuraSpeed * dt
					myRoot.CFrame = CFrame.new(
						tRoot.Position.X + math.cos(orbitAngle) * DS.KillAuraRadius,
						tRoot.Position.Y + DS.KillAuraHeight,
						tRoot.Position.Z + math.sin(orbitAngle) * DS.KillAuraRadius
					) * CFrame.Angles(0, -orbitAngle - math.pi / 2, 0)
					local now = tick()
					if now - lastStomp >= DS.StompRate then
						lastStomp = now
						myRoot.CFrame = CFrame.new(tRoot.Position + Vector3.new(0, 2, 0))
						clickMouse()
					end
				end
			end
		elseif DS.OrbitEnabled and DS.Target then
			local obj   = DS.Target
			if not obj or not obj.Parent then DS.Target = nil return end
			local tChar = obj:IsA("Player") and obj.Character or obj
			local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
			if tRoot then
				orbitAngle = orbitAngle + DS.OrbitSpeed * dt
				myRoot.CFrame = CFrame.new(
					tRoot.Position.X + math.cos(orbitAngle) * DS.OrbitRadius,
					tRoot.Position.Y + DS.OrbitHeight,
					tRoot.Position.Z + math.sin(orbitAngle) * DS.OrbitRadius
				) * CFrame.Angles(0, -orbitAngle - math.pi / 2, 0)
			end
		end

		if DS.AutoReviveEnabled then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player then
					local oChar = other.Character
					local oHum  = oChar and oChar:FindFirstChildOfClass("Humanoid")
					local oRoot = oChar and oChar:FindFirstChild("HumanoidRootPart")
					if oHum and oHum.Health <= 0 and oRoot
					and (oRoot.Position - myRoot.Position).Magnitude <= DS.AutoReviveDist then
						myRoot.CFrame = CFrame.new(oRoot.Position + Vector3.new(0, 2, 0))
						if VU then
							pcall(function()
								VU:KeyDown(string.byte("e"))
								task.delay(0.1, function() pcall(function() VU:KeyUp(string.byte("e")) end) end)
							end)
						end
					end
				end
			end
		end

		if DS.AutoBagEnabled then
			local bags = findBags()
			if #bags > 0 then
				local closest, closestDist = nil, math.huge
				for _, bag in ipairs(bags) do
					local pos = bag:IsA("BasePart") and bag.Position
						or (bag.PrimaryPart and bag.PrimaryPart.Position)
					if pos then
						local d = (pos - myRoot.Position).Magnitude
						if d < closestDist then closest = bag closestDist = d end
					end
				end
				if closest then
					local pos = closest:IsA("BasePart") and closest.Position
						or (closest.PrimaryPart and closest.PrimaryPart.Position)
					if pos then myRoot.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)) end
				end
			end
		end

		-- Telekinesis: pull nearest enemy toward local player
		if DS.TelekinesisEnabled and tkHolding then
			local nearest = findNearest()
			if nearest then
				local tChar = nearest.Character
				local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
				if tRoot then
					pcall(function()
						local dir  = (myRoot.Position - tRoot.Position)
						local dist = dir.Magnitude
						if dist > 2 then
							local step = math.min(DS.TelekinesisForce * dt, dist - 2)
							tRoot.CFrame = tRoot.CFrame + dir.Unit * step
						end
					end)
				end
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or Aim.IsCapturing() then return end
		if inputMatches(input, DS.KillAuraBind)    then DS.KillAuraEnabled    = not DS.KillAuraEnabled    changed:Fire() end
		if inputMatches(input, DS.OrbitBind)       then DS.OrbitEnabled       = not DS.OrbitEnabled       changed:Fire() end
		if inputMatches(input, DS.ArrestDodgeBind) then DS.ArrestDodgeEnabled = not DS.ArrestDodgeEnabled changed:Fire() end
		if inputMatches(input, DS.NoRagdollBind)   then DS.NoRagdollEnabled   = not DS.NoRagdollEnabled   changed:Fire() end
		if inputMatches(input, DS.AutoReviveBind)  then DS.AutoReviveEnabled  = not DS.AutoReviveEnabled  changed:Fire() end
		if inputMatches(input, DS.AutoBagBind)     then DS.AutoBagEnabled     = not DS.AutoBagEnabled     changed:Fire() end
		if inputMatches(input, DS.TelekinesisBind) then
			DS.TelekinesisEnabled = not DS.TelekinesisEnabled
			tkHolding = DS.TelekinesisEnabled
			changed:Fire()
		end
		if inputMatches(input, DS.JailEscapeBind)  then
			local _, _, root = getChar()
			if root then
				local sp = Workspace:FindFirstChild("Spawn") or Workspace:FindFirstChild("SpawnLocation")
				if sp and sp:IsA("BasePart") then
					root.CFrame = sp.CFrame + Vector3.new(0, 5, 0)
				else
					root.CFrame = CFrame.new(root.Position + Vector3.new(0, 60, 0))
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if inputMatches(input, DS.TelekinesisBind) then
			tkHolding = false
		end
	end)

	return M
end)()
_G.Tob2DaHood = DaHood

-- ── Movement Module ───────────────────────────────────────
local Movement = (function()
	local M = {}
	M.Settings = {
		WalkSpeedOn=false, WalkSpeed=32, WalkSpeedBind=Enum.KeyCode.G, WalkSpeedBindAmount=100,
		JumpPowerOn=false, JumpPower=100, InfiniteJump=false,
		Fly=false, FlySpeed=60, FlyBind=Enum.KeyCode.F,
		Noclip=false,
		GravityOn=false, Gravity=100,
		FOVOn=false, FOV=90,
	}
	local S       = M.Settings
	local changed = Instance.new("BindableEvent")
	M.Changed     = changed.Event

	local original        = {}
	local appliedHum      = nil
	local flyBody         = nil
	local flyGyro         = nil
	local flying          = false
	local flyVel          = Vector3.zero
	local noclipParts     = {}
	local originalGravity = nil
	local originalFOV     = nil
	local walkBound       = false

	local function stopFly(hum)
		if flyBody then flyBody:Destroy() flyBody = nil end
		if flyGyro then flyGyro:Destroy() flyGyro = nil end
		if flying then
			flying = false
			flyVel = Vector3.zero
			if hum then hum.PlatformStand = false end
		end
	end

	local function axis(pos, neg)
		local v = 0
		if UserInputService:IsKeyDown(pos) then v += 1 end
		if UserInputService:IsKeyDown(neg) then v -= 1 end
		return v
	end

	RunService.Heartbeat:Connect(function(dt)
		local _, hum, root = getChar()
		if hum then
			if appliedHum ~= hum then
				appliedHum = hum
				original.WalkSpeed    = nil
				original.JumpPower    = nil
				original.UseJumpPower = nil
			end

			local wantSpeed = S.WalkSpeedOn or walkBound
			if wantSpeed then
				if original.WalkSpeed == nil then original.WalkSpeed = hum.WalkSpeed end
				hum.WalkSpeed = walkBound and S.WalkSpeedBindAmount or S.WalkSpeed
			elseif original.WalkSpeed ~= nil then
				hum.WalkSpeed      = original.WalkSpeed
				original.WalkSpeed = nil
			end

			if S.JumpPowerOn then
				if original.JumpPower == nil then
					original.JumpPower    = hum.JumpPower
					original.UseJumpPower = hum.UseJumpPower
				end
				hum.UseJumpPower = true
				hum.JumpPower    = S.JumpPower
			elseif original.JumpPower ~= nil then
				hum.JumpPower     = original.JumpPower
				hum.UseJumpPower  = original.UseJumpPower
				original.JumpPower = nil
			end
		end

		if S.Fly and hum and root and hum.Health > 0 then
			flying = true
			hum.PlatformStand = true
			if not flyBody or not flyBody.Parent then
				if flyBody then flyBody:Destroy() end
				flyBody = Instance.new("BodyVelocity")
				flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				flyBody.Velocity = Vector3.zero
				flyBody.Parent   = root
			end
			if not flyGyro or not flyGyro.Parent then
				if flyGyro then flyGyro:Destroy() end
				flyGyro = Instance.new("BodyGyro")
				flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
				flyGyro.P         = 2e4
				flyGyro.D         = 500
				flyGyro.CFrame    = root.CFrame
				flyGyro.Parent    = root
			end
			local cam = Workspace.CurrentCamera
			local tv  = Vector3.zero
			if cam and not UserInputService:GetFocusedTextBox() then
				local cf = cam.CFrame
				local md = cf.LookVector  * axis(Enum.KeyCode.W, Enum.KeyCode.S)
				         + cf.RightVector * axis(Enum.KeyCode.D, Enum.KeyCode.A)
				         + Vector3.yAxis  * (axis(Enum.KeyCode.Space, Enum.KeyCode.LeftControl)
				                           + axis(Enum.KeyCode.E,     Enum.KeyCode.Q))
				if md.Magnitude > 0.01 then tv = md.Unit * S.FlySpeed end
			end
			flyVel = flyVel:Lerp(tv, math.min(dt * 10, 1))
			flyBody.Velocity = flyVel
			if cam then
				local flat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
				if flat.Magnitude > 0.01 then
					flyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
				end
			end
		else
			stopFly(hum)
		end

		if S.GravityOn then
			if originalGravity == nil then originalGravity = Workspace.Gravity end
			Workspace.Gravity = S.Gravity
		elseif originalGravity ~= nil then
			Workspace.Gravity = originalGravity
			originalGravity   = nil
		end
	end)

	RunService.Stepped:Connect(function()
		local char = player.Character
		if S.Noclip and char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
					noclipParts[part] = true
				end
			end
		elseif next(noclipParts) ~= nil then
			for part in pairs(noclipParts) do
				if part.Parent then part.CanCollide = true end
				noclipParts[part] = nil
			end
		end
	end)

	RunService:BindToRenderStep("MovFOV", Enum.RenderPriority.Camera.Value + 3, function()
		local cam = Workspace.CurrentCamera
		if not cam then return end
		if S.FOVOn then
			if originalFOV == nil then originalFOV = cam.FieldOfView end
			cam.FieldOfView = S.FOV
		elseif originalFOV ~= nil then
			cam.FieldOfView = originalFOV
			originalFOV     = nil
		end
	end)

	UserInputService.JumpRequest:Connect(function()
		if not S.InfiniteJump then return end
		local _, hum = getChar()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or Aim.IsCapturing() then return end
		if inputMatches(input, S.FlyBind)       then S.Fly = not S.Fly changed:Fire() end
		if inputMatches(input, S.WalkSpeedBind) then walkBound = true end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if inputMatches(input, S.WalkSpeedBind) then walkBound = false end
	end)

	function M.Reset()
		S.WalkSpeedOn = false S.JumpPowerOn  = false S.InfiniteJump = false
		S.Fly         = false S.Noclip       = false S.GravityOn    = false S.FOVOn = false
		walkBound = false
		changed:Fire()
	end

	return M
end)()
_G.Tob2Movement = Movement

-- ── Rapid Fire Module ─────────────────────────────────────
local RapidFire = (function()
	local M  = {}
	M.Settings = { Enabled=false, Bind=Enum.KeyCode.R, FireRate=0.05 }
	local RS      = M.Settings
	local changed = Instance.new("BindableEvent")
	M.Changed     = changed.Event

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or Aim.IsCapturing() then return end
		if input.KeyCode == RS.Bind then
			RS.Enabled = not RS.Enabled
			Aim.SetRapidFire(RS.Enabled, RS.FireRate)
			changed:Fire()
		end
	end)

	return M
end)()
_G.Tob2RapidFire = RapidFire

-- ── ESP Module ────────────────────────────────────────────
local ESP = (function()
	local M = {}
	M.Settings = {
		Enabled=false, Bind=Enum.KeyCode.X,
		Box=true, Name=true, Distance=true, Health=true,
		Outline=true, Fill=false, Tracers=false, TracerOrigin="Bottom",
		TeamCheck=false, TeamColors=false,
		MaxDistance=1000, Color="Purple",
	}
	local S      = M.Settings
	M.ColorNames = { "Purple","Red","Green","Blue","White","Yellow","Orange" }
	local COLORS = {
		Purple=Color3.fromRGB(124,92,255), Red=Color3.fromRGB(235,64,72),
		Green=Color3.fromRGB(80,220,140),  Blue=Color3.fromRGB(70,150,255),
		White=Color3.fromRGB(240,240,245), Yellow=Color3.fromRGB(250,215,70),
		Orange=Color3.fromRGB(255,150,60),
	}
	local changed = Instance.new("BindableEvent")
	M.Changed     = changed.Event

	local espGui = playerGui:FindFirstChild("Tob2ESP")
	if espGui then espGui:Destroy() end
	espGui = Instance.new("ScreenGui")
	espGui.Name           = "Tob2ESP"
	espGui.ResetOnSpawn   = false
	espGui.IgnoreGuiInset = true
	espGui.DisplayOrder   = 40
	espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	espGui.Parent         = playerGui

	local hlFolder = Workspace:FindFirstChild("Tob2Highlights")
	if hlFolder then hlFolder:Destroy() end
	hlFolder = Instance.new("Folder")
	hlFolder.Name   = "Tob2Highlights"
	hlFolder.Parent = Workspace

	local objects = {}

	local function makeLabel()
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Font                   = Enum.Font.GothamBold
		l.TextSize               = 13
		l.TextStrokeTransparency = 0.4
		l.Size                   = UDim2.fromOffset(200, 14)
		l.AnchorPoint            = Vector2.new(0.5, 0)
		l.Visible                = false
		l.Parent                 = espGui
		return l
	end

	local function createObjects(plr)
		if objects[plr] then return end
		local o = {}
		o.Box = Instance.new("Frame")
		o.Box.BackgroundTransparency = 1 o.Box.BorderSizePixel = 0 o.Box.Visible = false o.Box.Parent = espGui
		o.BoxStroke = Instance.new("UIStroke") o.BoxStroke.Thickness = 1.5 o.BoxStroke.Parent = o.Box
		o.NameLabel     = makeLabel()
		o.DistanceLabel = makeLabel()
		o.HealthBack = Instance.new("Frame")
		o.HealthBack.BackgroundColor3        = Color3.fromRGB(0,0,0)
		o.HealthBack.BackgroundTransparency  = 0.35
		o.HealthBack.BorderSizePixel         = 0
		o.HealthBack.Visible                 = false
		o.HealthBack.Parent                  = espGui
		o.HealthFill = Instance.new("Frame")
		o.HealthFill.AnchorPoint    = Vector2.new(0, 1)
		o.HealthFill.Position       = UDim2.fromScale(0, 1)
		o.HealthFill.Size           = UDim2.fromScale(1, 1)
		o.HealthFill.BorderSizePixel = 0
		o.HealthFill.Parent         = o.HealthBack
		o.Tracer = Instance.new("Frame")
		o.Tracer.AnchorPoint     = Vector2.new(0.5, 0.5)
		o.Tracer.BorderSizePixel = 0
		o.Tracer.Visible         = false
		o.Tracer.Parent          = espGui
		o.Highlight = Instance.new("Highlight")
		o.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		o.Highlight.Enabled   = false
		o.Highlight.Parent    = hlFolder
		objects[plr] = o
	end

	local function removeObjects(plr)
		local o = objects[plr]
		if not o then return end
		o.Box:Destroy() o.NameLabel:Destroy() o.DistanceLabel:Destroy()
		o.HealthBack:Destroy() o.Tracer:Destroy() o.Highlight:Destroy()
		objects[plr] = nil
	end

	local function hideAll(o)
		o.Box.Visible           = false
		o.NameLabel.Visible     = false
		o.DistanceLabel.Visible = false
		o.HealthBack.Visible    = false
		o.Tracer.Visible        = false
		o.Highlight.Enabled     = false
	end

	RunService:BindToRenderStep("ESPUpdate", Enum.RenderPriority.Camera.Value + 2, function()
		local cam = Workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local cp = cam.CFrame.Position
		for plr, o in pairs(objects) do
			local char = plr.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local show = S.Enabled and hum ~= nil and root ~= nil and hum.Health > 0
			if show and S.TeamCheck and player.Team ~= nil and plr.Team == player.Team then show = false end
			local dist = 0
			if show then
				dist = (cp - root.Position).Magnitude
				if dist > S.MaxDistance then show = false end
			end
			if not show then hideAll(o) continue end

			local color = S.TeamColors and plr.TeamColor.Color or COLORS[S.Color]
			local hl    = o.Highlight
			if hl.Adornee ~= char then hl.Adornee = char end
			hl.Enabled             = S.Outline or S.Fill
			hl.FillColor           = color
			hl.OutlineColor        = color
			hl.FillTransparency    = S.Fill    and 0.6 or 1
			hl.OutlineTransparency = S.Outline and 0   or 1

			local cf, size = char:GetBoundingBox()
			local half = Vector3.new(0, size.Y / 2, 0)
			local top  = cam:WorldToViewportPoint(cf.Position + half)
			local bot  = cam:WorldToViewportPoint(cf.Position - half)
			if top.Z <= 0 or bot.Z <= 0 then
				o.Box.Visible = false o.NameLabel.Visible = false
				o.DistanceLabel.Visible = false o.HealthBack.Visible = false
				o.Tracer.Visible = false continue
			end

			local height = math.abs(bot.Y - top.Y)
			local width  = height * 0.55
			local cx     = (top.X + bot.X) / 2
			local x      = cx - width / 2
			local y      = math.min(top.Y, bot.Y)

			o.Box.Visible = S.Box
			if S.Box then
				o.Box.Position    = UDim2.fromOffset(x, y)
				o.Box.Size        = UDim2.fromOffset(width, height)
				o.BoxStroke.Color = color
			end
			o.NameLabel.Visible = S.Name
			if S.Name then
				o.NameLabel.Text       = plr.DisplayName
				o.NameLabel.TextColor3 = color
				o.NameLabel.Position   = UDim2.fromOffset(cx, y - 16)
			end
			o.DistanceLabel.Visible = S.Distance
			if S.Distance then
				o.DistanceLabel.Text       = math.floor(dist + 0.5) .. " studs"
				o.DistanceLabel.TextColor3 = color
				o.DistanceLabel.Position   = UDim2.fromOffset(cx, y + height + 2)
			end
			o.HealthBack.Visible = S.Health
			if S.Health then
				local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
				o.HealthBack.Position        = UDim2.fromOffset(x - 6, y)
				o.HealthBack.Size            = UDim2.fromOffset(3, height)
				o.HealthFill.Size            = UDim2.fromScale(1, ratio)
				o.HealthFill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 1, 1)
			end
			o.Tracer.Visible = S.Tracers
			if S.Tracers then
				local from  = Vector2.new(vp.X / 2, S.TracerOrigin == "Center" and vp.Y / 2 or vp.Y)
				local to    = Vector2.new(cx, y + height)
				local delta = to - from
				local mid   = (from + to) / 2
				o.Tracer.Size             = UDim2.fromOffset(delta.Magnitude, 1.5)
				o.Tracer.Position         = UDim2.fromOffset(mid.X, mid.Y)
				o.Tracer.Rotation         = math.deg(math.atan2(delta.Y, delta.X))
				o.Tracer.BackgroundColor3 = color
			end
		end
	end)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then createObjects(plr) end
	end
	Players.PlayerAdded:Connect(function(plr) if plr ~= player then createObjects(plr) end end)
	Players.PlayerRemoving:Connect(removeObjects)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or Aim.IsCapturing() then return end
		local bind = S.Bind
		if not bind then return end
		local hit = bind.EnumType == Enum.KeyCode and input.KeyCode == bind or input.UserInputType == bind
		if hit then S.Enabled = not S.Enabled changed:Fire() end
	end)

	return M
end)()
_G.Tob2ESP = ESP

-- ── Users Module ──────────────────────────────────────────
local Users = (function()
	local M = {}
	M.Target     = nil
	M.Spectating = false
	M.Following  = false
	local changed = Instance.new("BindableEvent")
	M.Changed     = changed.Event

	local function displayName(obj)
		return obj:IsA("Player") and obj.DisplayName or obj.Name
	end

	local function targetParts(obj)
		if not obj then return nil, nil, nil end
		local char = obj:IsA("Player") and obj.Character or obj
		return char,
		       char and char:FindFirstChildOfClass("Humanoid"),
		       char and char:FindFirstChild("HumanoidRootPart")
	end

	local function isValid(obj) return obj ~= nil and obj.Parent ~= nil end
	local function myRoot()
		local char = player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	function M.List()
		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then table.insert(list, plr) end
		end
		table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
		return list
	end

	function M.Search(query)
		query = string.lower(query)
		local exact, loose = {}, {}
		for _, obj in ipairs(M.List()) do
			local name = obj.Name:lower()
			local disp = displayName(obj):lower()
			if query == "" or name:sub(1, #query) == query or disp:sub(1, #query) == query then
				table.insert(exact, obj)
			elseif name:find(query, 1, true) or disp:find(query, 1, true) then
				table.insert(loose, obj)
			end
		end
		for _, o in ipairs(loose) do table.insert(exact, o) end
		return exact
	end

	function M.SetSpectating(state)
		local cam = Workspace.CurrentCamera
		if state then
			local _, hum = targetParts(M.Target)
			if not hum or not cam then M.Spectating = false changed:Fire() return end
			cam.CameraSubject = hum
			M.Spectating = true
		else
			M.Spectating = false
			local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if cam and myHum then cam.CameraSubject = myHum end
		end
		changed:Fire()
	end

	function M.SetTarget(obj)
		M.Target = obj
		DaHood.Settings.Target = obj
		if M.Spectating then
			local _, hum = targetParts(obj)
			local cam = Workspace.CurrentCamera
			if hum and cam then cam.CameraSubject = hum
			else M.SetSpectating(false) return end
		end
		changed:Fire()
	end

	function M.SetFollowing(state)
		M.Following = state and isValid(M.Target)
		changed:Fire()
	end

	function M.Teleport()
		local _, _, tr = targetParts(M.Target)
		local root = myRoot()
		if tr and root then root.CFrame = tr.CFrame * CFrame.new(0, 0, 4) end
	end

	function M.Cycle(step)
		local list = M.List()
		if #list == 0 then return end
		local index = table.find(list, M.Target) or (step > 0 and 0 or 1)
		index = (index - 1 + step) % #list + 1
		M.SetTarget(list[index])
	end

	function M.Info()
		local obj = M.Target
		if not isValid(obj) then return "No target selected" end
		local _, hum, root = targetParts(obj)
		local mine = myRoot()
		if hum and root and mine then
			return string.format("%s  |  %d HP  |  %d studs",
				displayName(obj),
				math.floor(hum.Health + 0.5),
				math.floor((root.Position - mine.Position).Magnitude + 0.5))
		end
		return displayName(obj) .. "  |  no character"
	end

	RunService.Heartbeat:Connect(function()
		local obj = M.Target
		if M.Spectating then
			local cam     = Workspace.CurrentCamera
			local _, hum  = targetParts(obj)
			if not isValid(obj) or not hum then
				M.SetSpectating(false)
			elseif cam and cam.CameraSubject ~= hum then
				cam.CameraSubject = hum
			end
		end
		if M.Following then
			if not isValid(obj) then
				M.Following = false changed:Fire()
			else
				local _, _, tr = targetParts(obj)
				local root = myRoot()
				if tr and root then root.CFrame = tr.CFrame * CFrame.new(0, 0, 4) end
			end
		end
	end)

	return M
end)()
_G.Tob2Users = Users

-- ── Config Module ─────────────────────────────────────────
local Config = (function()
	local M = {}
	M.Slots    = {}
	M.Sections = {
		CamLock   = Aim.Settings.CamLock,
		SilentAim = Aim.Settings.SilentAim,
		ESP       = ESP.Settings,
		Movement  = Movement.Settings,
		RapidFire = RapidFire.Settings,
		DaHood    = DaHood.Settings,
		Menu      = MenuSettings,
	}

	local function encode(v)
		local t = typeof(v)
		if t == "boolean" or t == "string" then return v end
		if t == "number" then
			if v == v and v ~= math.huge and v ~= -math.huge then return v end
			return nil
		end
		if t == "EnumItem" then return { Enum = tostring(v.EnumType), Name = v.Name } end
		return nil
	end

	local function decode(saved, current, key)
		if type(saved) == "table" then
			if saved.Enum and saved.Name then
				local ok2, et = pcall(function() return Enum[saved.Enum] end)
				if ok2 and et then
					local ok3, item = pcall(function() return et[saved.Name] end)
					if ok3 and item then return item end
				end
			end
			return nil
		end
		if key:sub(-4) == "Bind" and saved == false then return false end
		if type(saved) == type(current) then return saved end
		return nil
	end

	local function capture()
		local data = {}
		for sn, section in pairs(M.Sections) do
			local out = {}
			for key, value in pairs(section) do
				local e = encode(value)
				if e ~= nil then out[key] = e end
			end
			data[sn] = out
		end
		return data
	end

	local function apply(data)
		for sn, saved in pairs(data) do
			local section = M.Sections[sn]
			if section and type(saved) == "table" then
				for key, sv in pairs(saved) do
					local current = section[key]
					if current ~= nil and type(current) ~= "function" and type(current) ~= "table" then
						local v = decode(sv, current, key)
						if section == MenuSettings and (not v or v.EnumType ~= Enum.KeyCode) then v = nil end
						if v ~= nil then section[key] = v end
					end
				end
			end
		end
	end

	M.Defaults = capture()

	function M.Export()
		local ok2, r = pcall(function() return HttpService:JSONEncode({ v=1, d=capture() }) end)
		return ok2 and r or ""
	end

	function M.Import(text)
		if type(text) ~= "string" or text:match("^%s*$") then return false, "Paste a config first" end
		local ok2, decoded = pcall(function() return HttpService:JSONDecode(text) end)
		if not ok2 or type(decoded) ~= "table" or type(decoded.d) ~= "table" then return false, "Invalid config" end
		apply(decoded.d)
		return true, "Config loaded"
	end

	function M.Save(name)   M.Slots[name] = capture() end
	function M.Load(name)   local d = M.Slots[name] if not d then return false end apply(d) return true end
	function M.Delete(name) M.Slots[name] = nil end
	function M.Names()
		local names = {}
		for name in pairs(M.Slots) do table.insert(names, name) end
		table.sort(names)
		return names
	end
	function M.ResetAll() apply(M.Defaults) end

	return M
end)()
_G.Tob2Config = Config

if AUTOLOAD_CONFIG ~= "" then Config.Import(AUTOLOAD_CONFIG) end

-- ── Pass globals to UI ────────────────────────────────────
_G.Tob2MenuSettings     = MenuSettings
_G.Tob2THEME            = THEME
_G.Tob2Players          = Players
_G.Tob2TweenService     = TweenService
_G.Tob2UserInputService = UserInputService
_G.Tob2RunService       = RunService
_G.Tob2Workspace        = Workspace
_G.Tob2HttpService      = HttpService
_G.Tob2player           = player
_G.Tob2playerGui        = playerGui
_G.Tob2inputMatches     = inputMatches

-- ── Load UI ───────────────────────────────────────────────
local _ls = loadstring
pcall(function()
	_ls(game:HttpGet("https://raw.githubusercontent.com/Tob2Scripts/DaHoodTob2/main/DaHoodUI.Lua"))()
end)

end)
if not ok then showError(err) end
