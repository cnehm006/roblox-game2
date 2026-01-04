--[[
	UIManager - Handles the main HUD elements
	Shows coins, level bar at bottom, and rebirth panel
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UIManager = {}

-- State
local mainGui
local statsFrame
local levelFrame
local rebirthFrame
local notificationFrame

local currentData = nil
local rebirthBoardUnlocked = false

-- Theme colors
local COLORS = {
	background = Color3.fromRGB(20, 20, 30),
	panel = Color3.fromRGB(35, 35, 50),
	panelLight = Color3.fromRGB(50, 50, 70),
	accent = Color3.fromRGB(70, 180, 220),
	accentGold = Color3.fromRGB(255, 200, 50),
	accentRebirth = Color3.fromRGB(180, 100, 255),
	text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(180, 180, 200),
	success = Color3.fromRGB(100, 220, 100),
	error = Color3.fromRGB(220, 80, 80),
	xpBar = Color3.fromRGB(100, 200, 255),
	xpBarBg = Color3.fromRGB(40, 50, 70),
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function formatNumber(num)
	if num >= 1000000000000 then
		return string.format("%.2fT", num / 1000000000000)
	elseif num >= 1000000000 then
		return string.format("%.2fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("%.2fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.2fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.accent
	stroke.Thickness = thickness or 2
	stroke.Transparency = 0.5
	stroke.Parent = parent
	return stroke
end

local function createGradient(parent, color1, color2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(color1, color2)
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN GUI CREATION
-- ═══════════════════════════════════════════════════════════════

local function createMainGui()
	mainGui = Instance.new("ScreenGui")
	mainGui.Name = "CoinIncrementalUI"
	mainGui.ResetOnSpawn = false
	mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainGui.Parent = PlayerGui
	return mainGui
end

-- ═══════════════════════════════════════════════════════════════
-- STATS HUD (Top - coins display)
-- ═══════════════════════════════════════════════════════════════

local coinsLabel
local rebirthLabel

local function createStatsHUD()
	statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsHUD"
	statsFrame.Size = UDim2.new(0, 280, 0, 50)
	statsFrame.Position = UDim2.new(0.5, -140, 0, 10)
	statsFrame.BackgroundColor3 = COLORS.panel
	statsFrame.BackgroundTransparency = 0.2
	statsFrame.Parent = mainGui
	createCorner(statsFrame)
	createStroke(statsFrame, COLORS.accentGold, 2)
	
	-- Coins display
	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size = UDim2.new(0, 35, 0, 35)
	coinIcon.Position = UDim2.new(0, 10, 0.5, -17)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "🪙"
	coinIcon.TextSize = 28
	coinIcon.Parent = statsFrame
	
	coinsLabel = Instance.new("TextLabel")
	coinsLabel.Size = UDim2.new(0, 150, 1, 0)
	coinsLabel.Position = UDim2.new(0, 45, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "0"
	coinsLabel.TextSize = 24
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextColor3 = COLORS.accentGold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = statsFrame
	
	-- Rebirth counter
	rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.Size = UDim2.new(0, 70, 0, 30)
	rebirthLabel.Position = UDim2.new(1, -80, 0.5, -15)
	rebirthLabel.BackgroundColor3 = COLORS.accentRebirth
	rebirthLabel.BackgroundTransparency = 0.3
	rebirthLabel.Text = "⟳ 0"
	rebirthLabel.TextSize = 16
	rebirthLabel.Font = Enum.Font.GothamBold
	rebirthLabel.TextColor3 = COLORS.text
	rebirthLabel.Parent = statsFrame
	createCorner(rebirthLabel, 6)
end

-- ═══════════════════════════════════════════════════════════════
-- LEVEL BAR (Bottom of screen)
-- ═══════════════════════════════════════════════════════════════

local levelLabel
local xpBarBg
local xpBarFill
local xpText

local function createLevelBar()
	levelFrame = Instance.new("Frame")
	levelFrame.Name = "LevelBar"
	levelFrame.Size = UDim2.new(0, 350, 0, 55)
	levelFrame.Position = UDim2.new(0.5, -175, 1, -65)
	levelFrame.BackgroundColor3 = COLORS.panel
	levelFrame.BackgroundTransparency = 0.2
	levelFrame.Parent = mainGui
	createCorner(levelFrame, 10)
	createStroke(levelFrame, COLORS.xpBar, 2)
	
	-- Level text
	levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, 0, 0, 22)
	levelLabel.Position = UDim2.new(0, 0, 0, 5)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Level 1"
	levelLabel.TextSize = 18
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextColor3 = COLORS.text
	levelLabel.Parent = levelFrame
	
	-- XP bar background
	xpBarBg = Instance.new("Frame")
	xpBarBg.Size = UDim2.new(1, -20, 0, 14)
	xpBarBg.Position = UDim2.new(0, 10, 0, 28)
	xpBarBg.BackgroundColor3 = COLORS.xpBarBg
	xpBarBg.Parent = levelFrame
	createCorner(xpBarBg, 7)
	
	-- XP bar fill
	xpBarFill = Instance.new("Frame")
	xpBarFill.Size = UDim2.new(0, 0, 1, 0)
	xpBarFill.BackgroundColor3 = COLORS.xpBar
	xpBarFill.Parent = xpBarBg
	createCorner(xpBarFill, 7)
	createGradient(xpBarFill, COLORS.xpBar, Color3.fromRGB(150, 230, 255), 0)
	
	-- XP text
	xpText = Instance.new("TextLabel")
	xpText.Size = UDim2.new(1, 0, 0, 12)
	xpText.Position = UDim2.new(0, 0, 0, 42)
	xpText.BackgroundTransparency = 1
	xpText.Text = "0 / 100 XP"
	xpText.TextSize = 11
	xpText.Font = Enum.Font.Gotham
	xpText.TextColor3 = COLORS.textDim
	xpText.Parent = levelFrame
end

-- ═══════════════════════════════════════════════════════════════
-- REBIRTH PANEL (Bottom right)
-- ═══════════════════════════════════════════════════════════════

local rebirthProgressLabel
local rebirthButton
local rebirthBoostLabel

local function createRebirthPanel()
	rebirthFrame = Instance.new("Frame")
	rebirthFrame.Name = "RebirthPanel"
	rebirthFrame.Size = UDim2.new(0, 180, 0, 100)
	rebirthFrame.Position = UDim2.new(1, -190, 1, -110)
	rebirthFrame.BackgroundColor3 = COLORS.panel
	rebirthFrame.BackgroundTransparency = 0.2
	rebirthFrame.Parent = mainGui
	createCorner(rebirthFrame)
	createStroke(rebirthFrame, COLORS.accentRebirth)
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⟳ REBIRTH"
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = COLORS.accentRebirth
	titleLabel.Parent = rebirthFrame
	
	rebirthProgressLabel = Instance.new("TextLabel")
	rebirthProgressLabel.Size = UDim2.new(1, -10, 0, 16)
	rebirthProgressLabel.Position = UDim2.new(0, 5, 0, 22)
	rebirthProgressLabel.BackgroundTransparency = 1
	rebirthProgressLabel.Text = "0 / 1M"
	rebirthProgressLabel.TextSize = 11
	rebirthProgressLabel.Font = Enum.Font.Gotham
	rebirthProgressLabel.TextColor3 = COLORS.textDim
	rebirthProgressLabel.Parent = rebirthFrame
	
	rebirthButton = Instance.new("TextButton")
	rebirthButton.Size = UDim2.new(1, -20, 0, 32)
	rebirthButton.Position = UDim2.new(0, 10, 0, 40)
	rebirthButton.BackgroundColor3 = COLORS.accentRebirth
	rebirthButton.Text = "REBIRTH"
	rebirthButton.TextSize = 14
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.TextColor3 = COLORS.text
	rebirthButton.AutoButtonColor = true
	rebirthButton.Parent = rebirthFrame
	createCorner(rebirthButton, 6)
	
	rebirthBoostLabel = Instance.new("TextLabel")
	rebirthBoostLabel.Size = UDim2.new(1, -10, 0, 14)
	rebirthBoostLabel.Position = UDim2.new(0, 5, 0, 76)
	rebirthBoostLabel.BackgroundTransparency = 1
	rebirthBoostLabel.Text = "+10% coins, +2% speed"
	rebirthBoostLabel.TextSize = 9
	rebirthBoostLabel.Font = Enum.Font.Gotham
	rebirthBoostLabel.TextColor3 = COLORS.success
	rebirthBoostLabel.Parent = rebirthFrame
	
	rebirthButton.MouseButton1Click:Connect(function()
		local result = Remotes.invokeServer("PerformRebirth")
		if result and not result.success then
			UIManager.showNotification(result.error or "Cannot rebirth", COLORS.error)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function createNotificationSystem()
	notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "Notifications"
	notificationFrame.Size = UDim2.new(0, 300, 0, 200)
	notificationFrame.Position = UDim2.new(0.5, -150, 0, 70)
	notificationFrame.BackgroundTransparency = 1
	notificationFrame.Parent = mainGui
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = notificationFrame
end

-- ═══════════════════════════════════════════════════════════════
-- UPDATE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function updateStatsDisplay()
	if not currentData then return end
	
	coinsLabel.Text = formatNumber(currentData.coins)
	rebirthLabel.Text = "⟳ " .. (currentData.rebirths or 0)
end

local function updateLevelDisplay()
	if not currentData then return end
	
	local level = currentData.level or 1
	local xp = currentData.xp or 0
	local requirement = GameConfig.getXPRequirement(level)
	local progress = math.clamp(xp / requirement, 0, 1)
	
	levelLabel.Text = "Level " .. level
	xpText.Text = formatNumber(xp) .. " / " .. formatNumber(requirement) .. " XP"
	
	-- Animate XP bar
	TweenService:Create(xpBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = UDim2.new(progress, 0, 1, 0)
	}):Play()
end

local function updateRebirthDisplay()
	if not currentData then return end
	
	local requirement = currentData.rebirthRequirement or 1000000
	
	rebirthProgressLabel.Text = formatNumber(currentData.coins) .. " / " .. formatNumber(requirement)
	
	if currentData.coins >= requirement then
		rebirthButton.BackgroundColor3 = COLORS.success
		rebirthButton.Text = "REBIRTH!"
	else
		rebirthButton.BackgroundColor3 = COLORS.accentRebirth
		rebirthButton.Text = "REBIRTH"
	end
	
	local nextCoinBoost = ((currentData.rebirths or 0) + 1) * 10
	local nextSpeedBoost = math.min(((currentData.rebirths or 0) + 1) * 2, 100)
	rebirthBoostLabel.Text = "+" .. nextCoinBoost .. "% coins, +" .. nextSpeedBoost .. "% speed"
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function UIManager.init()
	createMainGui()
	createStatsHUD()
	createLevelBar()
	createRebirthPanel()
	createNotificationSystem()
	
	print("[UIManager] Initialized")
end

function UIManager.updateAllData(data)
	currentData = data
	rebirthBoardUnlocked = data.rebirthBoardUnlocked or false
	
	updateStatsDisplay()
	updateLevelDisplay()
	updateRebirthDisplay()
end

function UIManager.updateStats(stats)
	if not currentData then return end
	
	for key, value in pairs(stats) do
		currentData[key] = value
	end
	
	updateStatsDisplay()
	updateLevelDisplay()
	updateRebirthDisplay()
end

function UIManager.updateUpgrades(upgrades)
	if not currentData then return end
	currentData.upgrades = upgrades
end

function UIManager.updateRebirthData(rebirthData)
	if not currentData then return end
	
	currentData.rebirths = rebirthData.rebirths
	currentData.coins = rebirthData.keptCoins or 0
	currentData.xp = 0
	currentData.level = 1
	
	updateStatsDisplay()
	updateLevelDisplay()
	updateRebirthDisplay()
end

function UIManager.unlockRebirthBoard()
	rebirthBoardUnlocked = true
end

function UIManager.showNotification(message, color)
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(1, 0, 0, 30)
	notification.BackgroundColor3 = color or COLORS.accent
	notification.BackgroundTransparency = 0.2
	notification.Text = message
	notification.TextSize = 14
	notification.Font = Enum.Font.GothamBold
	notification.TextColor3 = COLORS.text
	notification.Parent = notificationFrame
	createCorner(notification, 6)
	
	notification.BackgroundTransparency = 1
	notification.TextTransparency = 1
	
	local tweenIn = TweenService:Create(notification, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.2,
		TextTransparency = 0,
	})
	tweenIn:Play()
	
	task.delay(3, function()
		local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

-- Legacy functions for compatibility
function UIManager.toggleUpgradeBoard() end
function UIManager.toggleRebirthBoard() end

return UIManager
