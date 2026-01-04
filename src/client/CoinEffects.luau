--[[
	CoinEffects - Handles client-side visual effects for coins
	Includes collection popups, level up effects, and rebirth animations
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CoinEffects = {}

-- Effect colors by rarity
local RARITY_COLORS = {}
for _, rarity in ipairs(GameConfig.CoinRarities) do
	RARITY_COLORS[rarity.name] = rarity.color
end

-- ═══════════════════════════════════════════════════════════════
-- COLLECTION POPUP
-- ═══════════════════════════════════════════════════════════════

local function createCollectionPopup(rarityName, value, xp)
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	local character = LocalPlayer.Character
	if not character then return end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- Create billboard GUI attached to world position
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 150, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Adornee = root
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboardGui
	
	local coinText = Instance.new("TextLabel")
	coinText.Size = UDim2.new(1, 0, 0.6, 0)
	coinText.BackgroundTransparency = 1
	coinText.Text = "+" .. value .. " 🪙"
	coinText.TextSize = 18
	coinText.Font = Enum.Font.GothamBold
	coinText.TextColor3 = RARITY_COLORS[rarityName] or Color3.fromRGB(255, 215, 0)
	coinText.TextStrokeTransparency = 0.5
	coinText.TextStrokeColor3 = Color3.new(0, 0, 0)
	coinText.Parent = container
	
	local xpText = Instance.new("TextLabel")
	xpText.Size = UDim2.new(1, 0, 0.4, 0)
	xpText.Position = UDim2.new(0, 0, 0.6, 0)
	xpText.BackgroundTransparency = 1
	xpText.Text = "+" .. xp .. " XP"
	xpText.TextSize = 12
	xpText.Font = Enum.Font.Gotham
	xpText.TextColor3 = Color3.fromRGB(100, 200, 255)
	xpText.TextStrokeTransparency = 0.5
	xpText.TextStrokeColor3 = Color3.new(0, 0, 0)
	xpText.Parent = container
	
	billboardGui.Parent = PlayerGui
	
	-- Animate float up and fade
	local startOffset = billboardGui.StudsOffset
	local endOffset = startOffset + Vector3.new(0, 3, 0)
	
	local tween = TweenService:Create(billboardGui, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = endOffset
	})
	tween:Play()
	
	task.delay(0.5, function()
		local fadeTween = TweenService:Create(coinText, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})
		local fadeXPTween = TweenService:Create(xpText, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})
		fadeTween:Play()
		fadeXPTween:Play()
	end)
	
	Debris:AddItem(billboardGui, 1.2)
end

-- ═══════════════════════════════════════════════════════════════
-- LEVEL UP EFFECT
-- ═══════════════════════════════════════════════════════════════

local function createLevelUpEffect(newLevel, levelsGained)
	local effectGui = Instance.new("ScreenGui")
	effectGui.Name = "LevelUpEffect"
	effectGui.Parent = PlayerGui
	
	-- Center text
	local levelText = Instance.new("TextLabel")
	levelText.Size = UDim2.new(0, 400, 0, 100)
	levelText.Position = UDim2.new(0.5, -200, 0.4, -50)
	levelText.BackgroundTransparency = 1
	levelText.Text = "LEVEL " .. newLevel .. "!"
	levelText.TextSize = 60
	levelText.Font = Enum.Font.GothamBlack
	levelText.TextColor3 = Color3.fromRGB(255, 215, 0)
	levelText.TextStrokeTransparency = 0
	levelText.TextStrokeColor3 = Color3.fromRGB(150, 100, 0)
	levelText.TextTransparency = 1
	levelText.Parent = effectGui
	
	-- Subtitle
	local subtitleText = Instance.new("TextLabel")
	subtitleText.Size = UDim2.new(0, 400, 0, 30)
	subtitleText.Position = UDim2.new(0.5, -200, 0.4, 50)
	subtitleText.BackgroundTransparency = 1
	if levelsGained > 1 then
		subtitleText.Text = "+" .. levelsGained .. " Levels"
	else
		subtitleText.Text = "Level Up!"
	end
	subtitleText.TextSize = 24
	subtitleText.Font = Enum.Font.GothamBold
	subtitleText.TextColor3 = Color3.fromRGB(255, 255, 200)
	subtitleText.TextStrokeTransparency = 0.3
	subtitleText.TextTransparency = 1
	subtitleText.Parent = effectGui
	
	-- Glow effect
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(0, 0, 0, 0)
	glow.Position = UDim2.new(0.5, 0, 0.4, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	glow.BackgroundTransparency = 0.8
	glow.Parent = effectGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = glow
	
	-- Animate
	-- Glow expand
	local glowTween = TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 600, 0, 600),
		BackgroundTransparency = 1
	})
	glowTween:Play()
	
	-- Text appear
	local textAppear = TweenService:Create(levelText, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextSize = 72
	})
	textAppear:Play()
	
	local subtitleAppear = TweenService:Create(subtitleText, TweenInfo.new(0.3), {
		TextTransparency = 0
	})
	task.delay(0.2, function()
		subtitleAppear:Play()
	end)
	
	-- Fade out
	task.delay(1.5, function()
		local fadeOut = TweenService:Create(levelText, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})
		local subtitleFade = TweenService:Create(subtitleText, TweenInfo.new(0.5), {
			TextTransparency = 1
		})
		fadeOut:Play()
		subtitleFade:Play()
	end)
	
	Debris:AddItem(effectGui, 2.5)
end

-- ═══════════════════════════════════════════════════════════════
-- REBIRTH EFFECT
-- ═══════════════════════════════════════════════════════════════

local function createRebirthEffect()
	local effectGui = Instance.new("ScreenGui")
	effectGui.Name = "RebirthEffect"
	effectGui.Parent = PlayerGui
	
	-- Full screen flash
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
	flash.BackgroundTransparency = 1
	flash.Parent = effectGui
	
	-- Rebirth text
	local rebirthText = Instance.new("TextLabel")
	rebirthText.Size = UDim2.new(0, 500, 0, 120)
	rebirthText.Position = UDim2.new(0.5, -250, 0.4, -60)
	rebirthText.BackgroundTransparency = 1
	rebirthText.Text = "⟳ REBIRTH ⟳"
	rebirthText.TextSize = 80
	rebirthText.Font = Enum.Font.GothamBlack
	rebirthText.TextColor3 = Color3.fromRGB(200, 150, 255)
	rebirthText.TextStrokeTransparency = 0
	rebirthText.TextStrokeColor3 = Color3.fromRGB(80, 40, 120)
	rebirthText.TextTransparency = 1
	rebirthText.Parent = effectGui
	
	-- Particle rings
	for i = 1, 3 do
		local ring = Instance.new("Frame")
		ring.Size = UDim2.new(0, 0, 0, 0)
		ring.Position = UDim2.new(0.5, 0, 0.5, 0)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
		ring.BackgroundTransparency = 0.5
		ring.Parent = effectGui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(220, 180, 255)
		stroke.Thickness = 3
		stroke.Parent = ring
		
		task.delay(i * 0.15, function()
			local expand = TweenService:Create(ring, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 800, 0, 800),
				BackgroundTransparency = 1
			})
			local strokeFade = TweenService:Create(stroke, TweenInfo.new(1), {
				Transparency = 1
			})
			expand:Play()
			strokeFade:Play()
		end)
	end
	
	-- Flash
	local flashIn = TweenService:Create(flash, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.3
	})
	flashIn:Play()
	flashIn.Completed:Connect(function()
		local flashOut = TweenService:Create(flash, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		})
		flashOut:Play()
	end)
	
	-- Text animation
	task.delay(0.1, function()
		local textIn = TweenService:Create(rebirthText, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			TextSize = 90
		})
		textIn:Play()
	end)
	
	task.delay(2, function()
		local textOut = TweenService:Create(rebirthText, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})
		textOut:Play()
	end)
	
	Debris:AddItem(effectGui, 3)
end

-- ═══════════════════════════════════════════════════════════════
-- COIN VISUAL EFFECTS
-- ═══════════════════════════════════════════════════════════════

local spinningCoins = {}

local function setupCoinSpin(coin)
	-- Simple rotation animation using RunService
	local rotation = 0
	local basePosition = coin.Position
	local initialRotation = math.random() * 360
	
	local connection = RunService.Heartbeat:Connect(function(dt)
		if not coin.Parent then
			return
		end
		
		rotation = rotation + dt * 120 -- 120 degrees per second
		
		-- Bob up and down while spinning
		local bobHeight = math.sin(os.clock() * 3) * 0.15
		-- Coin stands upright and spins around Y axis
		coin.CFrame = CFrame.new(basePosition + Vector3.new(0, bobHeight, 0)) 
			* CFrame.Angles(0, math.rad(rotation + initialRotation), 0)
			* CFrame.Angles(0, 0, math.rad(90)) -- Keep it upright
	end)
	
	spinningCoins[coin] = connection
	
	coin.Destroying:Connect(function()
		if spinningCoins[coin] then
			spinningCoins[coin]:Disconnect()
			spinningCoins[coin] = nil
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function CoinEffects.init()
	print("[CoinEffects] Initialized")
end

function CoinEffects.showCollectionEffect(rarityName, value, xp)
	createCollectionPopup(rarityName, value, xp)
end

function CoinEffects.showLevelUpEffect(newLevel, levelsGained)
	createLevelUpEffect(newLevel, levelsGained)
end

function CoinEffects.showRebirthEffect()
	createRebirthEffect()
end

function CoinEffects.setupCoinEffects(coin, rarityName, color)
	-- Set up spinning animation
	setupCoinSpin(coin)
end

return CoinEffects
