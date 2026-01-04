--[[
	Remotes - Centralized remote event/function management
	Creates and provides access to all network communication
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Remote Events (one-way communication)
local remoteEvents = {
	-- Coin events
	"CoinCollected", -- Server -> Client: notify of collection
	"CoinSpawned", -- Server -> Client: coin was created
	"CoinDespawned", -- Server -> Client: coin was removed
	
	-- Player stats updates
	"StatsUpdated", -- Server -> Client: coins, xp, level changed
	"UpgradesUpdated", -- Server -> Client: upgrade levels changed
	
	-- Rebirth events
	"RebirthCompleted", -- Server -> Client: rebirth happened
	"RebirthBoardUnlocked", -- Server -> Client: first rebirth done
	
	-- Level events
	"LevelUp", -- Server -> Client: player leveled up
	
	-- Effects
	"PlayEffect", -- Server -> Client: trigger visual effect
}

-- Remote Functions (two-way communication)
local remoteFunctions = {
	"GetPlayerData", -- Client -> Server: request full data
	"PurchaseUpgrade", -- Client -> Server: buy upgrade
	"PurchaseRebirthUpgrade", -- Client -> Server: buy rebirth upgrade
	"PerformRebirth", -- Client -> Server: trigger rebirth
}

-- Create or get remotes folder
local function getRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

-- Initialize all remotes (call this from server)
function Remotes.init()
	local folder = getRemotesFolder()
	
	for _, name in ipairs(remoteEvents) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	
	for _, name in ipairs(remoteFunctions) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

-- Get a remote event
function Remotes.getEvent(name)
	local folder = getRemotesFolder()
	local remote = folder:WaitForChild(name, 10)
	assert(remote and remote:IsA("RemoteEvent"), "RemoteEvent " .. name .. " not found")
	return remote
end

-- Get a remote function
function Remotes.getFunction(name)
	local folder = getRemotesFolder()
	local remote = folder:WaitForChild(name, 10)
	assert(remote and remote:IsA("RemoteFunction"), "RemoteFunction " .. name .. " not found")
	return remote
end

-- Convenience methods for server
function Remotes.fireClient(eventName, player, ...)
	Remotes.getEvent(eventName):FireClient(player, ...)
end

function Remotes.fireAllClients(eventName, ...)
	Remotes.getEvent(eventName):FireAllClients(...)
end

-- Convenience methods for client
function Remotes.fireServer(eventName, ...)
	Remotes.getEvent(eventName):FireServer(...)
end

function Remotes.invokeServer(functionName, ...)
	return Remotes.getFunction(functionName):InvokeServer(...)
end

return Remotes
