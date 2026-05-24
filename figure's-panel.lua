local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Figure's Panel",
	Icon = 0,
	LoadingTitle = "Figure's Panel",
	LoadingSubtitle = "",
	ShowText = "Figure's Panel",
	Theme = "Default",
	ToggleUIKeybind = "K",
	DisableRayfieldPrompts = true,
	DisableBuildWarnings = true,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "FiguresPanel",
		FileName = "AdminConfig"
	},
	Discord = {
		Enabled = false,
		Invite = "",
		RememberJoins = true
	},
	KeySystem = false
})

local DefaultWalkSpeed = 16
local DefaultJumpPower = 50
local DefaultGravity = Workspace.Gravity
local DefaultCameraFOV = Camera.FieldOfView
local GravitySliderMax = math.max(DefaultGravity, 196.2)
local CameraFOVMax = math.max(DefaultCameraFOV, 120)

local function getHumanoid()
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return character:FindFirstChildOfClass("Humanoid")
end

local humanoid = getHumanoid()
if humanoid then
	DefaultWalkSpeed = humanoid.WalkSpeed
	DefaultJumpPower = humanoid.UseJumpPower and humanoid.JumpPower or 50
end

local OriginalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ExposureCompensation = Lighting.ExposureCompensation
}

local Settings = {
	Aimbot = false,
	AimMode = "Hold",
	ShowFOV = false,
	Smoothness = 0,
	AimMethod = "camera",
	BodyPart = "Head",
	AimWallCheck = false,
	AimTeamCheck = false,
	AimAliveCheck = true,
	ESP = false,
	Box = false,
	BoxFill = false,
	Chams = false,
	Tracers = false,
	HealthBar = false,
	Names = false,
	Distance = false,
	BoxColor = Color3.fromRGB(255, 255, 255),
	BoxFillColor = Color3.fromRGB(255, 255, 255),
	ChamsColor = Color3.fromRGB(255, 255, 255),
	TracerColor = Color3.fromRGB(255, 255, 255),
	NameColor = Color3.fromRGB(255, 255, 255),
	DistanceColor = Color3.fromRGB(255, 255, 255),
	TeamColor = false,
	ESPTeamCheck = false,
	ESPAliveCheck = true,
	FOVRadius = 160,
	CameraFOV = DefaultCameraFOV,
	WalkSpeedEnabled = false,
	WalkSpeed = DefaultWalkSpeed,
	JumpPowerEnabled = false,
	JumpPower = DefaultJumpPower,
	Sit = false,
	Fly = false,
	FlySpeed = 1,
	Noclip = false,
	InfiniteJump = false,
	Spin = false,
	SpinSpeed = 8,
	SelectedPlayer = nil,
	LoopGoto = false,
	RMASelectedPlayer = "",
	RMAHideAFK = false,
	Fullbright = false,
	Gravity = DefaultGravity
}

local AimHeld = false
local AimToggled = false
local ESPObjects = {}
local FlyVelocity = nil
local FlyGyro = nil
local SpinVelocity = nil
local PlayerDropdown = nil
local RMAHideAFKRunning = false

local Overlay = Instance.new("ScreenGui")
Overlay.Name = "FiguresPanelOverlay"
Overlay.IgnoreGuiInset = true
Overlay.ResetOnSpawn = false
Overlay.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(Settings.FOVRadius * 2, Settings.FOVRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.Parent = Overlay

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1
FOVStroke.Transparency = 0.15
FOVStroke.Parent = FOVCircle

local function notify(title, content)
	Rayfield:Notify({
		Title = title,
		Content = content,
		Duration = 4,
		Image = 0
	})
end

local function getCharacterInfo(player, bodyPart)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local part = character:FindFirstChild(bodyPart) or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if not humanoid or not part then return end
	return character, humanoid, part
end

local function getRoot(player)
	local character = player.Character
	if not character then return end
	return character:FindFirstChild("HumanoidRootPart")
end

local function isAlive(humanoid)
	return humanoid and humanoid.Health > 0
end

local function wallClear(character, part)
	local origin = Camera.CFrame.Position
	local direction = part.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = Workspace:Raycast(origin, direction, params)
	if not result then return true end
	return result.Instance:IsDescendantOf(character)
end

local function getBoxColor(player)
	if Settings.TeamColor and player.TeamColor then
		return player.TeamColor.Color
	end
	return Settings.BoxColor
end

local function getChamsColor(player)
	if Settings.TeamColor and player.TeamColor then
		return player.TeamColor.Color
	end
	return Settings.ChamsColor
end

local function getHealthColor(ratio)
	if ratio > 0.65 then
		return Color3.fromRGB(0, 255, 0)
	elseif ratio > 0.4 then
		return Color3.fromRGB(255, 255, 0)
	elseif ratio > 0.2 then
		return Color3.fromRGB(255, 145, 0)
	else
		return Color3.fromRGB(255, 0, 0)
	end
end

local function validAimTarget(player)
	if player == LocalPlayer then return false end
	if Settings.AimTeamCheck and player.Team == LocalPlayer.Team then return false end
	local character, humanoid, part = getCharacterInfo(player, Settings.BodyPart)
	if not character then return false end
	if Settings.AimAliveCheck and not isAlive(humanoid) then return false end
	if Settings.AimWallCheck and not wallClear(character, part) then return false end
	local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
	if not onScreen then return false end
	local mouseLocation = UserInputService:GetMouseLocation()
	local center = Vector2.new(mouseLocation.X, mouseLocation.Y)
	local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
	if distance > Settings.FOVRadius then return false end
	return true, distance, part
end

local function getClosestTarget()
	local closestPart = nil
	local closestDistance = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local valid, distance, part = validAimTarget(player)
		if valid and distance < closestDistance then
			closestDistance = distance
			closestPart = part
		end
	end
	return closestPart
end

local function aimAt(part)
	if not part then return end
	local origin = Camera.CFrame.Position
	local targetCFrame = CFrame.lookAt(origin, part.Position)
	local smooth = tonumber(Settings.Smoothness) or 0
	if Settings.AimMethod == "mouse" and mousemoverel then
		local screenPoint = Camera:WorldToViewportPoint(part.Position)
		local mouseLocation = UserInputService:GetMouseLocation()
		local dx = screenPoint.X - mouseLocation.X
		local dy = screenPoint.Y - mouseLocation.Y
		local divisor = math.max(1, smooth * 4)
		mousemoverel(dx / divisor, dy / divisor)
	else
		if smooth <= 0 then
			Camera.CFrame = targetCFrame
		else
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / math.clamp(smooth * 6, 1, 30))
		end
	end
end

local function createESP(player)
	if ESPObjects[player] then return ESPObjects[player] end
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = Overlay
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Settings.BoxColor
	stroke.Parent = box
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Settings.BoxFillColor
	fill.BackgroundTransparency = 0.75
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Visible = false
	fill.Parent = box
	local health = Instance.new("Frame")
	health.BorderSizePixel = 0
	health.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	health.Visible = false
	health.Parent = Overlay
	local healthText = Instance.new("TextLabel")
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.fromRGB(0, 255, 0)
	healthText.TextStrokeTransparency = 0.4
	healthText.TextSize = 12
	healthText.Font = Enum.Font.GothamBold
	healthText.Visible = false
	healthText.Parent = Overlay
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextStrokeTransparency = 0.4
	name.TextSize = 13
	name.Font = Enum.Font.GothamBold
	name.Visible = false
	name.Parent = Overlay
	local distanceText = Instance.new("TextLabel")
	distanceText.BackgroundTransparency = 1
	distanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
	distanceText.TextStrokeTransparency = 0.4
	distanceText.TextSize = 12
	distanceText.Font = Enum.Font.GothamBold
	distanceText.Visible = false
	distanceText.Parent = Overlay
	local tracer = Instance.new("Frame")
	tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	tracer.BorderSizePixel = 0
	tracer.BackgroundColor3 = Settings.BoxColor
	tracer.Visible = false
	tracer.Parent = Overlay
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = Overlay
	ESPObjects[player] = {
		Box = box,
		Stroke = stroke,
		Fill = fill,
		Health = health,
		HealthText = healthText,
		Name = name,
		Distance = distanceText,
		Tracer = tracer,
		Highlight = highlight
	}
	return ESPObjects[player]
end

local function hideESP(object)
	for _, item in pairs(object) do
		if typeof(item) == "Instance" and item:IsA("GuiObject") then
			item.Visible = false
		end
	end
	object.Highlight.Enabled = false
end

local function clearESP(player)
	local object = ESPObjects[player]
	if not object then return end
	for _, item in pairs(object) do
		if typeof(item) == "Instance" then
			item:Destroy()
		end
	end
	ESPObjects[player] = nil
end

local function updateESP(player)
	if player == LocalPlayer then return end
	local object = createESP(player)
	if not Settings.ESP then hideESP(object) return end
	local character, humanoid, root = getCharacterInfo(player, "HumanoidRootPart")
	if not character then hideESP(object) return end
	if Settings.ESPTeamCheck and player.Team == LocalPlayer.Team then hideESP(object) return end
	if Settings.ESPAliveCheck and not isAlive(humanoid) then hideESP(object) return end
	local rootPoint, onScreen = Camera:WorldToViewportPoint(root.Position)
	if not onScreen then
		hideESP(object)
		object.Highlight.Enabled = Settings.Chams
		object.Highlight.Adornee = character
		object.Highlight.FillColor = getChamsColor(player)
		object.Highlight.OutlineColor = getChamsColor(player)
		return
	end
	local distance = (Camera.CFrame.Position - root.Position).Magnitude
	local height = math.clamp(3200 / distance, 45, 280)
	local width = height * 0.55
	local x = rootPoint.X - width / 2
	local y = rootPoint.Y - height / 2
	local color = getBoxColor(player)
	object.Box.Position = UDim2.fromOffset(x, y)
	object.Box.Size = UDim2.fromOffset(width, height)
	object.Box.Visible = Settings.Box
	object.Stroke.Color = color
	object.Fill.BackgroundColor3 = Settings.BoxFillColor
	object.Fill.Visible = Settings.BoxFill
	local hpRatio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
	local healthColor = getHealthColor(hpRatio)
	object.Health.Position = UDim2.fromOffset(x - 6, y + height * (1 - hpRatio))
	object.Health.Size = UDim2.fromOffset(3, height * hpRatio)
	object.Health.BackgroundColor3 = healthColor
	object.Health.Visible = Settings.HealthBar
	object.HealthText.Position = UDim2.fromOffset(x - 35, y + height * (1 - hpRatio) - 8)
	object.HealthText.Size = UDim2.fromOffset(28, 16)
	object.HealthText.Text = tostring(math.floor(humanoid.Health))
	object.HealthText.TextColor3 = healthColor
	object.HealthText.Visible = Settings.HealthBar
	object.Name.Position = UDim2.fromOffset(x - 40, y - 18)
	object.Name.Size = UDim2.fromOffset(width + 80, 16)
	object.Name.Text = player.DisplayName
	object.Name.TextColor3 = Settings.NameColor
	object.Name.Visible = Settings.Names
	object.Distance.Position = UDim2.fromOffset(x - 40, y + height + 2)
	object.Distance.Size = UDim2.fromOffset(width + 80, 16)
	object.Distance.Text = tostring(math.floor(distance)) .. " studs"
	object.Distance.TextColor3 = Settings.DistanceColor
	object.Distance.Visible = Settings.Distance
	local bottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
	local target = Vector2.new(rootPoint.X, y + height)
	local midpoint = (bottom + target) / 2
	local length = (bottom - target).Magnitude
	object.Tracer.Position = UDim2.fromOffset(midpoint.X, midpoint.Y)
	object.Tracer.Size = UDim2.fromOffset(1, length)
	object.Tracer.Rotation = math.deg(math.atan2(target.Y - bottom.Y, target.X - bottom.X)) + 90
	object.Tracer.BackgroundColor3 = Settings.TracerColor
	object.Tracer.Visible = Settings.Tracers
	object.Highlight.Adornee = character
	object.Highlight.FillColor = getChamsColor(player)
	object.Highlight.OutlineColor = getChamsColor(player)
	object.Highlight.Enabled = Settings.Chams
end

local function playerNames()
	local names = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(names, player.Name)
		end
	end
	if #names == 0 then
		table.insert(names, "None")
	end
	return names
end

local function findSelectedPlayer()
	if not Settings.SelectedPlayer or Settings.SelectedPlayer == "None" then return end
	return Players:FindFirstChild(Settings.SelectedPlayer)
end

local function refreshPlayerDropdown()
	if PlayerDropdown then
		PlayerDropdown:Refresh(playerNames())
	end
end

local function gotoPlayer()
	local targetPlayer = findSelectedPlayer()
	if not targetPlayer then return end
	local localRoot = getRoot(LocalPlayer)
	local targetRoot = getRoot(targetPlayer)
	if localRoot and targetRoot then
		localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
	end
end

local function applyFullbright(enabled)
	if enabled then
		Lighting.Brightness = 3
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.FogStart = 0
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.ExposureCompensation = 0.25
	else
		Lighting.Brightness = OriginalLighting.Brightness
		Lighting.ClockTime = OriginalLighting.ClockTime
		Lighting.FogEnd = OriginalLighting.FogEnd
		Lighting.FogStart = OriginalLighting.FogStart
		Lighting.GlobalShadows = OriginalLighting.GlobalShadows
		Lighting.Ambient = OriginalLighting.Ambient
		Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
		Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
	end
end

local function setFly(enabled)
	local character = LocalPlayer.Character
	local root = getRoot(LocalPlayer)
	local humanoid = getHumanoid()
	if not character or not root or not humanoid then return end
	if enabled then
		humanoid.PlatformStand = true
		FlyVelocity = Instance.new("BodyVelocity")
		FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		FlyVelocity.Velocity = Vector3.zero
		FlyVelocity.Parent = root
		FlyGyro = Instance.new("BodyGyro")
		FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		FlyGyro.P = 90000
		FlyGyro.CFrame = root.CFrame
		FlyGyro.Parent = root
	else
		humanoid.PlatformStand = false
		if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
		if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
	end
end

local function updateFly()
	if not Settings.Fly or not FlyVelocity or not FlyGyro then return end
	local direction = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += Camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= Camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= Camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += Camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end
	if direction.Magnitude > 0 then
		direction = direction.Unit
	end
	FlyVelocity.Velocity = direction * (50 * Settings.FlySpeed)
	FlyGyro.CFrame = Camera.CFrame
end

local function updateNoclip()
	if not Settings.Noclip then return end
	local character = LocalPlayer.Character
	if not character then return end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
		end
	end
end

local function setSpin(enabled)
	local root = getRoot(LocalPlayer)
	if not root then return end
	if enabled then
		SpinVelocity = Instance.new("BodyAngularVelocity")
		SpinVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
		SpinVelocity.AngularVelocity = Vector3.new(0, Settings.SpinSpeed, 0)
		SpinVelocity.Parent = root
	else
		if SpinVelocity then SpinVelocity:Destroy() SpinVelocity = nil end
	end
end

local function getRMARoot()
	local root = getRoot(LocalPlayer)
	if root then return root end
	notify("Rate My Avatar", "Character root was not found.")
end

local function rmaFireAFK()
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("IsAFK")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer(false)
		return true
	end
	return false
end

local function rmaStartHideAFK()
	if RMAHideAFKRunning then return end
	RMAHideAFKRunning = true
	task.spawn(function()
		while Settings.RMAHideAFK do
			rmaFireAFK()
			task.wait(0.25)
		end
		RMAHideAFKRunning = false
	end)
end

local function rmaSpoofPlatformNone()
	local targetName = Settings.RMASelectedPlayer
	if targetName == "" then
		notify("Rate My Avatar", "Select a player first.")
		return
	end
	local character = Workspace:FindFirstChild(targetName)
	local head = character and character:FindFirstChild("Head")
	local title = head and head:FindFirstChild("Title")
	local platformIndicator = title and title:FindFirstChild("PlatformIndicator")
	local platformConfig = platformIndicator and platformIndicator:FindFirstChild("platformConfig")
	if platformConfig and platformConfig:IsA("RemoteEvent") then
		platformConfig:FireServer(nil)
		notify("Rate My Avatar", "Platform removed.")
	else
		notify("Rate My Avatar", "Platform remote was not found.")
	end
end

local function rmaBypassAntiBackshot()
	local killEvent = game:GetService("ReplicatedStorage"):FindFirstChild("KillEvent")
	if killEvent then
		killEvent:Destroy()
		notify("Rate My Avatar", "Anti-backshot bypassed locally.")
	else
		notify("Rate My Avatar", "KillEvent was not found.")
	end
end

local function rmaTeleportTo(instance)
	local root = getRMARoot()
	if root and instance then
		root.CFrame = instance.CFrame
	end
end

local function rmaTeleportShopCamera()
	local cameras = Workspace:FindFirstChild("Cameras")
	local shopCamera = cameras and cameras:FindFirstChild("ShopCamMain")
	if shopCamera then
		rmaTeleportTo(shopCamera)
	else
		notify("Rate My Avatar", "Shop camera was not found.")
	end
end

local function rmaTeleportSpawn()
	local map = Workspace:FindFirstChild("Map")
	local spawnLocation = map and map:FindFirstChild("SpawnLocation")
	if spawnLocation then
		rmaTeleportTo(spawnLocation)
	else
		notify("Rate My Avatar", "Spawn location was not found.")
	end
end

local AimbotTab = Window:CreateTab("Aimbot", 0)
AimbotTab:CreateSection("Main")
AimbotTab:CreateToggle({Name = "Aimbot", CurrentValue = false, Flag = "AimbotToggle", Callback = function(Value) Settings.Aimbot = Value end})
AimbotTab:CreateDropdown({Name = "Aim Key Mode", Options = {"Hold", "Toggle"}, CurrentOption = {"Hold"}, MultipleOptions = false, Flag = "AimMode", Callback = function(Options) Settings.AimMode = Options[1] end})
AimbotTab:CreateToggle({Name = "Show FOV", CurrentValue = false, Flag = "ShowFOV", Callback = function(Value) Settings.ShowFOV = Value end})
AimbotTab:CreateSlider({Name = "FOV Size", Range = {50, 500}, Increment = 5, Suffix = "", CurrentValue = 160, Flag = "AimbotFOVSize", Callback = function(Value) Settings.FOVRadius = Value end})
AimbotTab:CreateSection("Targeting")
AimbotTab:CreateSlider({Name = "Aim Smoothness", Range = {0, 5}, Increment = 1, Suffix = "", CurrentValue = 0, Flag = "AimSmoothness", Callback = function(Value) Settings.Smoothness = Value end})
AimbotTab:CreateDropdown({Name = "Aim Method", Options = {"mouse", "camera"}, CurrentOption = {"camera"}, MultipleOptions = false, Flag = "AimMethod", Callback = function(Options) Settings.AimMethod = Options[1] end})
AimbotTab:CreateDropdown({Name = "Body Part", Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, CurrentOption = {"Head"}, MultipleOptions = false, Flag = "BodyPart", Callback = function(Options) Settings.BodyPart = Options[1] end})
AimbotTab:CreateToggle({Name = "WallCheck", CurrentValue = false, Flag = "AimWallCheck", Callback = function(Value) Settings.AimWallCheck = Value end})
AimbotTab:CreateToggle({Name = "TeamCheck", CurrentValue = false, Flag = "AimTeamCheck", Callback = function(Value) Settings.AimTeamCheck = Value end})
AimbotTab:CreateToggle({Name = "AliveCheck", CurrentValue = true, Flag = "AimAliveCheck", Callback = function(Value) Settings.AimAliveCheck = Value end})

local ESPTab = Window:CreateTab("ESP", 0)
ESPTab:CreateSection("Main")
ESPTab:CreateToggle({Name = "ESP", CurrentValue = false, Flag = "ESPMaster", Callback = function(Value) Settings.ESP = Value end})
ESPTab:CreateToggle({Name = "Box", CurrentValue = false, Flag = "BoxToggle", Callback = function(Value) Settings.Box = Value end})
ESPTab:CreateToggle({Name = "Box Fill", CurrentValue = false, Flag = "BoxFillToggle", Callback = function(Value) Settings.BoxFill = Value end})
ESPTab:CreateToggle({Name = "Chams", CurrentValue = false, Flag = "ChamsToggle", Callback = function(Value) Settings.Chams = Value end})
ESPTab:CreateToggle({Name = "Tracers", CurrentValue = false, Flag = "TracersToggle", Callback = function(Value) Settings.Tracers = Value end})
ESPTab:CreateToggle({Name = "Health Bar", CurrentValue = false, Flag = "HealthBar", Callback = function(Value) Settings.HealthBar = Value end})
ESPTab:CreateToggle({Name = "Names", CurrentValue = false, Flag = "NamesToggle", Callback = function(Value) Settings.Names = Value end})
ESPTab:CreateToggle({Name = "Distance", CurrentValue = false, Flag = "DistanceToggle", Callback = function(Value) Settings.Distance = Value end})
ESPTab:CreateSection("Colors")
ESPTab:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 255, 255), Flag = "BoxColor", Callback = function(Value) Settings.BoxColor = Value end})
ESPTab:CreateColorPicker({Name = "Box Fill Color", Color = Color3.fromRGB(255, 255, 255), Flag = "BoxFillColor", Callback = function(Value) Settings.BoxFillColor = Value end})
ESPTab:CreateColorPicker({Name = "Chams Color", Color = Color3.fromRGB(255, 255, 255), Flag = "ChamsColor", Callback = function(Value) Settings.ChamsColor = Value end})
ESPTab:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(255, 255, 255), Flag = "TracerColor", Callback = function(Value) Settings.TracerColor = Value end})
ESPTab:CreateColorPicker({Name = "Name Color", Color = Color3.fromRGB(255, 255, 255), Flag = "NameColor", Callback = function(Value) Settings.NameColor = Value end})
ESPTab:CreateColorPicker({Name = "Distance Color", Color = Color3.fromRGB(255, 255, 255), Flag = "DistanceColor", Callback = function(Value) Settings.DistanceColor = Value end})
ESPTab:CreateToggle({Name = "Team Color", CurrentValue = false, Flag = "TeamColorToggle", Callback = function(Value) Settings.TeamColor = Value end})
ESPTab:CreateSection("Targeting")
ESPTab:CreateToggle({Name = "TeamCheck", CurrentValue = false, Flag = "ESPTeamCheck", Callback = function(Value) Settings.ESPTeamCheck = Value end})
ESPTab:CreateToggle({Name = "AliveCheck", CurrentValue = true, Flag = "ESPAliveCheck", Callback = function(Value) Settings.ESPAliveCheck = Value end})

local PlayerTab = Window:CreateTab("Player", 0)
PlayerTab:CreateSection("Parameters")
PlayerTab:CreateToggle({Name = "WalkSpeed", CurrentValue = false, Flag = "WalkSpeedEnabled", Callback = function(Value) Settings.WalkSpeedEnabled = Value local h = getHumanoid() if h then h.WalkSpeed = Value and Settings.WalkSpeed or DefaultWalkSpeed end end})
PlayerTab:CreateSlider({Name = "WalkSpeed", Range = {DefaultWalkSpeed, 250}, Increment = 1, Suffix = "", CurrentValue = DefaultWalkSpeed, Flag = "WalkSpeed", Callback = function(Value) Settings.WalkSpeed = Value local h = getHumanoid() if h and Settings.WalkSpeedEnabled then h.WalkSpeed = Value end end})
PlayerTab:CreateToggle({Name = "JumpPower", CurrentValue = false, Flag = "JumpPowerEnabled", Callback = function(Value) Settings.JumpPowerEnabled = Value local h = getHumanoid() if h then h.UseJumpPower = true h.JumpPower = Value and Settings.JumpPower or DefaultJumpPower end end})
PlayerTab:CreateSlider({Name = "JumpPower", Range = {DefaultJumpPower, 250}, Increment = 1, Suffix = "", CurrentValue = DefaultJumpPower, Flag = "JumpPower", Callback = function(Value) Settings.JumpPower = Value local h = getHumanoid() if h and Settings.JumpPowerEnabled then h.UseJumpPower = true h.JumpPower = Value end end})
PlayerTab:CreateSlider({Name = "FOV", Range = {40, CameraFOVMax}, Increment = 1, Suffix = "", CurrentValue = DefaultCameraFOV, Flag = "CameraFOV", Callback = function(Value) Settings.CameraFOV = Value Camera.FieldOfView = Value end})
PlayerTab:CreateButton({Name = "Reset Character", Callback = function() local h = getHumanoid() if h then h.Health = 0 end end})
PlayerTab:CreateToggle({Name = "Sit", CurrentValue = false, Flag = "Sit", Callback = function(Value) Settings.Sit = Value local h = getHumanoid() if h then h.Sit = Value end end})
PlayerTab:CreateSection("Powers")
PlayerTab:CreateToggle({Name = "Fly", CurrentValue = false, Flag = "Fly", Callback = function(Value) Settings.Fly = Value setFly(Value) end})
PlayerTab:CreateSlider({Name = "Flyspeed", Range = {0.5, 3}, Increment = 0.1, Suffix = "x", CurrentValue = 1, Flag = "FlySpeed", Callback = function(Value) Settings.FlySpeed = Value end})
PlayerTab:CreateToggle({Name = "Noclip", CurrentValue = false, Flag = "Noclip", Callback = function(Value) Settings.Noclip = Value end})
PlayerTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Flag = "InfiniteJump", Callback = function(Value) Settings.InfiniteJump = Value end})
PlayerTab:CreateToggle({Name = "Spin", CurrentValue = false, Flag = "Spin", Callback = function(Value) Settings.Spin = Value setSpin(Value) end})
PlayerTab:CreateSlider({Name = "Spin Speed", Range = {1, 60}, Increment = 1, Suffix = "", CurrentValue = 8, Flag = "SpinSpeed", Callback = function(Value) Settings.SpinSpeed = Value if SpinVelocity then SpinVelocity.AngularVelocity = Vector3.new(0, Value, 0) end end})

local PlayersTab = Window:CreateTab("Players", 0)
PlayersTab:CreateSection("Target")
PlayerDropdown = PlayersTab:CreateDropdown({Name = "Player List", Options = playerNames(), CurrentOption = {"None"}, MultipleOptions = false, Flag = "PlayerList", Callback = function(Options) Settings.SelectedPlayer = Options[1] end})
PlayersTab:CreateSection("Actions")
PlayersTab:CreateButton({Name = "Goto Player", Callback = gotoPlayer})
PlayersTab:CreateToggle({Name = "Loopgoto Player", CurrentValue = false, Flag = "LoopGoto", Callback = function(Value) Settings.LoopGoto = Value end})
PlayersTab:CreateButton({Name = "Refresh Player List", Callback = refreshPlayerDropdown})

local RMATab = Window:CreateTab("Rate My Avatar", 0)
RMATab:CreateSection("Platform")
RMATab:CreateInput({Name = "Select Player", CurrentValue = "", PlaceholderText = "username", RemoveTextAfterFocusLost = false, Flag = "RMASelectedPlayer", Callback = function(Value) Settings.RMASelectedPlayer = Value end})
RMATab:CreateButton({Name = "Remove Platform", Callback = rmaSpoofPlatformNone})
RMATab:CreateSection("Other")
RMATab:CreateToggle({Name = "Hide AFK", CurrentValue = false, Flag = "RMAHideAFK", Callback = function(Value) Settings.RMAHideAFK = Value if Value then rmaStartHideAFK() end end})
RMATab:CreateButton({Name = "Bypass Anti-Backshot", Callback = rmaBypassAntiBackshot})
RMATab:CreateSection("Teleports")
RMATab:CreateButton({Name = "Shop Camera", Callback = rmaTeleportShopCamera})
RMATab:CreateButton({Name = "Spawn", Callback = rmaTeleportSpawn})

local MiscTab = Window:CreateTab("Misc", 0)
MiscTab:CreateSection("Game")
MiscTab:CreateToggle({Name = "Fullbright", CurrentValue = false, Flag = "Fullbright", Callback = function(Value) Settings.Fullbright = Value applyFullbright(Value) end})
MiscTab:CreateSlider({Name = "Gravity", Range = {0, GravitySliderMax}, Increment = 1, Suffix = "", CurrentValue = DefaultGravity, Flag = "Gravity", Callback = function(Value) Settings.Gravity = Value Workspace.Gravity = Value end})
MiscTab:CreateButton({Name = "Reset Gravity", Callback = function() Settings.Gravity = DefaultGravity Workspace.Gravity = DefaultGravity end})
MiscTab:CreateSection("Server")
MiscTab:CreateButton({Name = "Server Hop", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})
MiscTab:CreateButton({Name = "Rejoin", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if Settings.AimMode == "Toggle" then
			AimToggled = not AimToggled
		else
			AimHeld = true
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		AimHeld = false
	end
end)

UserInputService.JumpRequest:Connect(function()
	if Settings.InfiniteJump then
		local h = getHumanoid()
		if h then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

Players.PlayerAdded:Connect(function()
	task.wait(0.2)
	refreshPlayerDropdown()
end)

Players.PlayerRemoving:Connect(function(player)
	clearESP(player)
	task.wait(0.2)
	refreshPlayerDropdown()
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	local h = getHumanoid()
	if h then
		h.WalkSpeed = Settings.WalkSpeedEnabled and Settings.WalkSpeed or DefaultWalkSpeed
		h.UseJumpPower = true
		h.JumpPower = Settings.JumpPowerEnabled and Settings.JumpPower or DefaultJumpPower
		h.Sit = Settings.Sit
	end
	if Settings.Fly then
		setFly(false)
		task.wait()
		setFly(true)
	end
	if Settings.Spin then
		setSpin(false)
		task.wait()
		setSpin(true)
	end
end)

RunService.RenderStepped:Connect(function()
	Camera = Workspace.CurrentCamera
	if Camera.FieldOfView ~= Settings.CameraFOV then
		Camera.FieldOfView = Settings.CameraFOV
	end
	local mouseLocation = UserInputService:GetMouseLocation()
	FOVCircle.Position = UDim2.fromOffset(mouseLocation.X, mouseLocation.Y)
	FOVCircle.Size = UDim2.fromOffset(Settings.FOVRadius * 2, Settings.FOVRadius * 2)
	FOVCircle.Visible = Settings.ShowFOV
	local h = getHumanoid()
	if h then
		if Settings.WalkSpeedEnabled and h.WalkSpeed ~= Settings.WalkSpeed then h.WalkSpeed = Settings.WalkSpeed end
		if Settings.JumpPowerEnabled then
			h.UseJumpPower = true
			if h.JumpPower ~= Settings.JumpPower then h.JumpPower = Settings.JumpPower end
		end
		if Settings.Sit then h.Sit = true end
	end
	if Settings.Aimbot then
		local active = Settings.AimMode == "Hold" and AimHeld or AimToggled
		if active then
			aimAt(getClosestTarget())
		end
	end
	if Settings.LoopGoto then
		gotoPlayer()
	end
	updateFly()
	updateNoclip()
	if Settings.Fullbright then
		applyFullbright(true)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		updateESP(player)
	end
end)

Rayfield:LoadConfiguration()
print("Figure's Panel loaded")
