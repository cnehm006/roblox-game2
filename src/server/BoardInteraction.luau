--[[
	BoardInteraction - Creates physical upgrade boards with SurfaceGui
	Players can click directly on the boards to purchase upgrades
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataManager -- Forward declaration

local BoardInteraction = {}

-- Theme colors
local COLORS = {
	background = Color3.fromRGB(25, 30, 40),
	panel = Color3.fromRGB(35, 45, 60),
	accent = Color3.fromRGB(60, 170, 220),
	accentRebirth = Color3.fromRGB(180, 100, 255),
	text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(180, 180, 200),
	gold = Color3.fromRGB(255, 200, 50),
}

-- Store references to update buttons
local upgradeButtonRefs = {} -- [upgradeName] = {button, levelLabel, costLabel}
local rebirthButtonRefs = {}

-- Format numbers nicely
local function formatNumber(num)
	if num >= 1000000000 then
		return string.format("%.1fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

-- Create the physical upgrade board
local function createUpgradeBoard()
	-- Remove old board if exists
	local oldBoard = Workspace:FindFirstChild("UpgradeBoardModel")
	if oldBoard then oldBoard:Destroy() end
	
	local boardModel = Instance.new("Model")
	boardModel.Name = "UpgradeBoardModel"
	
	-- Main board part
	local board = Instance.new("Part")
	board.Name = "Board"
	board.Anchored = true
	board.CanCollide = true
	board.Size = Vector3.new(1, 14, 22)
	board.CFrame = CFrame.new(-55, 8, 0) * CFrame.Angles(0, math.rad(90), 0)
	board.Color = COLORS.background
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = boardModel
	
	-- Frame/border
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Anchored = true
	frame.CanCollide = false
	frame.Size = Vector3.new(1.1, 14.5, 22.5)
	frame.CFrame = board.CFrame
	frame.Color = COLORS.accent
	frame.Material = Enum.Material.Neon
	frame.Transparency = 0.5
	frame.Parent = boardModel
	
	-- Decorative lights on top
	local lights = Instance.new("Part")
	lights.Name = "Lights"
	lights.Anchored = true
	lights.CanCollide = false
	lights.Size = Vector3.new(0.3, 0.3, 23)
	lights.CFrame = CFrame.new(-55, 15.3, 0) * CFrame.Angles(0, math.rad(90), 0)
	lights.Color = Color3.fromRGB(255, 100, 100)
	lights.Material = Enum.Material.Neon
	lights.Parent = boardModel
	
	-- Create SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "UpgradeGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board
	
	-- Main container
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = surfaceGui
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.12, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.02, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "coin upgrades"
	titleLabel.TextColor3 = COLORS.accent
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame
	
	-- Upgrades container
	local upgradesFrame = Instance.new("Frame")
	upgradesFrame.Size = UDim2.new(0.95, 0, 0.65, 0)
	upgradesFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
	upgradesFrame.BackgroundTransparency = 1
	upgradesFrame.Parent = mainFrame
	
	-- Grid layout for upgrades
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.3, 0, 0.45, 0)
	gridLayout.CellPadding = UDim2.new(0.025, 0, 0.05, 0)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = upgradesFrame
	
	-- Create upgrade cards
	local upgradeOrder = {"FasterRespawning", "CoinValueMultiplier", "CoinRarityChance", "MaxCoinsOnPlatform", "CoinPullingStrength"}
	local displayNames = {
		FasterRespawning = "faster spawning",
		CoinValueMultiplier = "coin value",
		CoinRarityChance = "coin rarity",
		MaxCoinsOnPlatform = "max coins",
		CoinPullingStrength = "coin pulling strength",
	}
	
	for i, upgradeName in ipairs(upgradeOrder) do
		local upgrade = GameConfig.BaseUpgrades[upgradeName]
		if not upgrade then continue end
		
		local card = Instance.new("Frame")
		card.Name = upgradeName
		card.BackgroundColor3 = COLORS.panel
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = upgradesFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.05, 0)
		corner.Parent = card
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.accent
		stroke.Thickness = 2
		stroke.Transparency = 0.5
		stroke.Parent = card
		
		-- Upgrade name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
		nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = displayNames[upgradeName] or upgrade.displayName
		nameLabel.TextColor3 = COLORS.text
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Parent = card
		
		-- Level label
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelLabel"
		levelLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
		levelLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "lvl: 0 / " .. upgrade.maxLevel
		levelLabel.TextColor3 = COLORS.textDim
		levelLabel.TextScaled = true
		levelLabel.Font = Enum.Font.Gotham
		levelLabel.Parent = card
		
		-- Buy button
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0.8, 0, 0.25, 0)
		buyButton.Position = UDim2.new(0.1, 0, 0.42, 0)
		buyButton.BackgroundColor3 = COLORS.accent
		buyButton.Text = "upgrade"
		buyButton.TextColor3 = COLORS.text
		buyButton.TextScaled = true
		buyButton.Font = Enum.Font.GothamBold
		buyButton.AutoButtonColor = true
		buyButton.Parent = card
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0.15, 0)
		btnCorner.Parent = buyButton
		
		-- Cost label
		local costLabel = Instance.new("TextLabel")
		costLabel.Name = "CostLabel"
		costLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
		costLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = formatNumber(upgrade.baseCost) .. " coins"
		costLabel.TextColor3 = COLORS.gold
		costLabel.TextScaled = true
		costLabel.Font = Enum.Font.Gotham
		costLabel.Parent = card
		
		-- Store references
		upgradeButtonRefs[upgradeName] = {
			button = buyButton,
			levelLabel = levelLabel,
			costLabel = costLabel,
			card = card,
		}
		
		-- Click handler
		buyButton.MouseButton1Click:Connect(function()
			-- Find which player clicked (SurfaceGui click detection)
		end)
	end
	
	-- Bottom hint
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
	hintLabel.Position = UDim2.new(0.05, 0, 0.88, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "hold click on an upgrade to upgrade quickly"
	hintLabel.TextColor3 = COLORS.textDim
	hintLabel.TextScaled = true
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.Parent = mainFrame
	
	boardModel.Parent = Workspace
	
	print("[BoardInteraction] Upgrade board created")
	return boardModel
end

-- Create the rebirth upgrade board
local function createRebirthBoard()
	-- Remove old board if exists
	local oldBoard = Workspace:FindFirstChild("RebirthBoardModel")
	if oldBoard then oldBoard:Destroy() end
	
	local boardModel = Instance.new("Model")
	boardModel.Name = "RebirthBoardModel"
	
	-- Main board part
	local board = Instance.new("Part")
	board.Name = "Board"
	board.Anchored = true
	board.CanCollide = true
	board.Size = Vector3.new(1, 14, 22)
	board.CFrame = CFrame.new(120, 8, -40)
	board.Color = COLORS.background
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = boardModel
	
	-- Frame/border
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Anchored = true
	frame.CanCollide = false
	frame.Size = Vector3.new(1.1, 14.5, 22.5)
	frame.CFrame = board.CFrame
	frame.Color = COLORS.accentRebirth
	frame.Material = Enum.Material.Neon
	frame.Transparency = 0.5
	frame.Parent = boardModel
	
	-- Decorative lights
	local lights = Instance.new("Part")
	lights.Name = "Lights"
	lights.Anchored = true
	lights.CanCollide = false
	lights.Size = Vector3.new(0.3, 0.3, 23)
	lights.CFrame = CFrame.new(120, 15.3, -40)
	lights.Color = Color3.fromRGB(200, 100, 255)
	lights.Material = Enum.Material.Neon
	lights.Parent = boardModel
	
	-- Create SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "RebirthGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board
	
	-- Main container
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = surfaceGui
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.02, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "rebirth upgrades"
	titleLabel.TextColor3 = COLORS.accentRebirth
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame
	
	-- Upgrades container
	local upgradesFrame = Instance.new("Frame")
	upgradesFrame.Size = UDim2.new(0.95, 0, 0.75, 0)
	upgradesFrame.Position = UDim2.new(0.025, 0, 0.13, 0)
	upgradesFrame.BackgroundTransparency = 1
	upgradesFrame.Parent = mainFrame
	
	-- Grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.3, 0, 0.3, 0)
	gridLayout.CellPadding = UDim2.new(0.025, 0, 0.03, 0)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = upgradesFrame
	
	-- Create rebirth upgrade cards
	local upgradeOrder = {"QuickUpgrades", "RebirthVault", "OfflineCoinCollection", "AutomaticUpgrading", "AutomaticRebirths"}
	local displayNames = {
		QuickUpgrades = "quick upgrades",
		RebirthVault = "rebirth vault",
		OfflineCoinCollection = "offline coins",
		AutomaticUpgrading = "auto upgrade",
		AutomaticRebirths = "auto rebirth",
	}
	
	for i, upgradeName in ipairs(upgradeOrder) do
		local upgrade = GameConfig.RebirthUpgrades[upgradeName]
		if not upgrade then continue end
		
		local card = Instance.new("Frame")
		card.Name = upgradeName
		card.BackgroundColor3 = COLORS.panel
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = upgradesFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.05, 0)
		corner.Parent = card
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.accentRebirth
		stroke.Thickness = 2
		stroke.Transparency = 0.5
		stroke.Parent = card
		
		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.9, 0, 0.22, 0)
		nameLabel.Position = UDim2.new(0.05, 0, 0.03, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = displayNames[upgradeName]
		nameLabel.TextColor3 = COLORS.text
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Parent = card
		
		-- Level
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelLabel"
		levelLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
		levelLabel.Position = UDim2.new(0.05, 0, 0.26, 0)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "lvl: 0 / " .. upgrade.maxLevel
		levelLabel.TextColor3 = COLORS.textDim
		levelLabel.TextScaled = true
		levelLabel.Font = Enum.Font.Gotham
		levelLabel.Parent = card
		
		-- Button
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0.8, 0, 0.25, 0)
		buyButton.Position = UDim2.new(0.1, 0, 0.43, 0)
		buyButton.BackgroundColor3 = COLORS.accentRebirth
		buyButton.Text = "upgrade"
		buyButton.TextColor3 = COLORS.text
		buyButton.TextScaled = true
		buyButton.Font = Enum.Font.GothamBold
		buyButton.Parent = card
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0.15, 0)
		btnCorner.Parent = buyButton
		
		-- Cost
		local costLabel = Instance.new("TextLabel")
		costLabel.Name = "CostLabel"
		costLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
		costLabel.Position = UDim2.new(0.05, 0, 0.72, 0)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = formatNumber(upgrade.costPerLevel) .. " coins"
		costLabel.TextColor3 = COLORS.gold
		costLabel.TextScaled = true
		costLabel.Font = Enum.Font.Gotham
		costLabel.Parent = card
		
		rebirthButtonRefs[upgradeName] = {
			button = buyButton,
			levelLabel = levelLabel,
			costLabel = costLabel,
			card = card,
		}
	end
	
	-- Locked overlay (shown when not rebirthed)
	local lockedOverlay = Instance.new("Frame")
	lockedOverlay.Name = "LockedOverlay"
	lockedOverlay.Size = UDim2.new(1, 0, 1, 0)
	lockedOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lockedOverlay.BackgroundTransparency = 0.7
	lockedOverlay.Visible = false -- Will be controlled per-player on client
	lockedOverlay.Parent = mainFrame
	
	local lockedLabel = Instance.new("TextLabel")
	lockedLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
	lockedLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
	lockedLabel.BackgroundTransparency = 1
	lockedLabel.Text = "🔒 REBIRTH REQUIRED 🔒"
	lockedLabel.TextColor3 = COLORS.accentRebirth
	lockedLabel.TextScaled = true
	lockedLabel.Font = Enum.Font.GothamBold
	lockedLabel.Parent = lockedOverlay
	
	boardModel.Parent = Workspace
	
	print("[BoardInteraction] Rebirth board created")
	return boardModel
end

-- Update board displays for a player
local function updateBoardsForPlayer(player)
	local data = DataManager.getData(player)
	if not data then return end
	
	-- Note: SurfaceGui buttons are handled client-side
	-- This function can be used for server-side updates if needed
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function BoardInteraction.init(dataManagerModule)
	DataManager = dataManagerModule
	
	-- Wait for workspace to be ready
	task.wait(0.5)
	
	createUpgradeBoard()
	createRebirthBoard()
	
	print("[BoardInteraction] Initialized")
end

-- Get upgrade button references (for external updates)
function BoardInteraction.getUpgradeRefs()
	return upgradeButtonRefs
end

function BoardInteraction.getRebirthRefs()
	return rebirthButtonRefs
end

return BoardInteraction
