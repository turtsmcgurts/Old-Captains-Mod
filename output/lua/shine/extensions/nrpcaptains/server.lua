local Plugin = Plugin

Plugin.Version = "1.0"

local debugmode = true

local TEAM_RR = 0
local TEAM_MARINE = 1
local TEAM_ALIEN = 2
local TEAM_SPEC = 3

local STATE_WAITING = 1
local STATE_PICKING = 2
local STATE_PLAYING = 3

--captain commands. parameters are always the team number
--RemoveCaptain, ClearCaptains, SetCaptain
local captain_clients 	= {0, 0} --store the client for each captain. 0 = none
local captain_name 		= {"", ""}
local captain_id 		= {0, 0} --store captain steamids here. 0 = none
local captain_exists 	= {false, false} --whether or not the specified captain exists
local captain_alltalk 	= {true, true}
--end

local islive = false

local is_player_captain = {} --local is_captain = is_player_captain[id]
local option_alltalk = true
local CountdownTime = 5


local Random = math.random
local Gamerules = GetGamerules()


Plugin.Conflicts = {
    DisableThem = {
		"pregame",
		"readyroom",
    },
    DisableUs = {}
}

function Plugin: Initialise()
	self.Enabled = true
	self.dt.state = 1
		
	self:CreateCommands()
	return true
end
function Plugin: ClientConnect(client)
	local player_steamid = client:GetUserId()
	is_player_captain[player_steamid] = false
	
	if (self.dt.enabled) then
		self:SimpleTimer( 2, function()
			--if(captain_exists[TEAM_MARINE] or captain_exists[TEAM_ALIEN]) then
				--send a message to captains to add this player to their list
				local player = client:GetControllingPlayer()
				--Print("Connected: %s %s", player:GetName(), tostring(client:GetUserId()))
				Plugin:SendAddPlayer(player)
				
				--if(not islive) then
					--self:NotifyGeneric(nil, "%s connected", true, player:GetName())
				--end
			--end
		end)
	end
end
function Plugin: ClientDisconnect(client)
	if (self.dt.enabled) then
		--if a captain disconnects, make sure to drop them internally.
		local player = client:GetControllingPlayer()
		local player_name = player:GetName()
		local team_number = player:GetTeamNumber()
		local team_name = Plugin: GetTeamName(team_number, false)
		
		if (captain_clients[team_number] == client) then --is he a captain?
		
			self:NotifyGeneric(nil, "%s is no longer %s captain. (Disconnected)", true, player_name, team_name)
			Plugin:RemoveCaptains(team_number)
		else
			if(player_name ~= kDefaultPlayerName) then
				if(islive) then
					self:NotifyGeneric(nil, "%s disconnected", true, player_name)
				end
			end
			Plugin: SendRemovePlayer(player)
		end
	end
end


--Shine.Hook.SetupClassHook( "NS2Gamerules", "ResetGame", "OnResetGame", "PassivePre" )

function Plugin: JoinTeam(Gamerules, player, new_team, Force, ShineForce) 
	if (not self.dt.enabled) then return end
	if (not player) then return end
	
	local client = player:GetClient()
	local player_steamid = client:GetUserId()
	local old_team = player:GetTeamNumber()
	local team_name = Plugin: GetTeamName(new_team, false)
	
	
	if(new_team == TEAM_RR) then
		--check if he's captain. remove him as captain if so.
		if(is_player_captain[player_steamid]) then
			Plugin: RemoveCaptain(client)
		end
		Plugin:SendAddPlayer(player)
	elseif (new_team == TEAM_MARINE or new_team == TEAM_ALIEN) then
		if(islive) then
			if(new_team == TEAM_MARINE) then
				Shine:NotifyDualColour(nil, 90, 171, 237, "[NRP]", 200, 200, 200, "%s joined %ss", true, player:GetName(), team_name)
			elseif (new_team == TEAM_ALIEN) then
				--self:NotifyGeneric( nil, "%s joined %ss", true, player:GetName(), team_name)
				Shine:NotifyDualColour(nil, 255, 165, 0, "[NRP]", 200, 200, 200, "%s joined %ss", true, player:GetName(), team_name)
			end
		end
		Plugin: SendRemovePlayer(player)
	elseif (new_team == TEAM_SPEC) then
		Plugin: SendRemovePlayer(player)
	end
end
function Plugin: CheckGameStart( Gamerules )
	local State = Gamerules:GetGameState()
	if (State == kGameState.Started) then
		islive = true
	end
	if State == kGameState.PreGame or State == kGameState.NotStarted then
		islive = false
	end
end
function Plugin: EndGame( Gamerules, WinningTeam )
	Print("Game Ended")
end
function Plugin: OnResetGame()
	--self:NotifyGeneric( nil, "Round Reset.", true)
	Plugin: PopulatePlayerList()
	
	return
end


function Plugin: SetCaptain(client)
	if (not self.dt.enabled) then return end
	if (not client) then return end
	if (not Plugin:IsPlayerOnTeam(client)) then return end --prevent readyroom/spectators
	
	local player = client:GetControllingPlayer()
	local team_number = player:GetTeamNumber()
	local SteamId = client:GetUserId()

	captain_clients[team_number] = client
	captain_name[team_number] = player:GetName()
	captain_id[team_number] = SteamId
	captain_exists[team_number] = true
	is_player_captain[SteamId] = true
	captain_alltalk[team_number] = true
	
	if(debugmode) then
		--self:NotifyGeneric( nil, "Captain Set: name: %s steamid: %s exists: %s iscaptain:%s", true, captain_name[team_number], captain_id[team_number], tostring(captain_exists[team_number]), tostring(is_player_captain[client:GetUserId()]))
	end
	
	if(not islive) then
		self:NotifyGeneric( nil, "%s is now captaining %ss.", true, player:GetName(), Plugin:GetTeamName(team_number, false))
	end
	--self:NotifyGeneric( player, "%s", true, captain_message)
	
	
	self:SendNetworkMessage( captain_clients[team_number], "SetCaptain", { steamid = SteamId, team = team_number, add = true }, true )
	
	Plugin: CheckCaptains()
end
function Plugin: RemoveCaptain(client)	
	if (not self.dt.enabled) then return end
	if (not client) then return end
	
	local player = client:GetControllingPlayer()
	local team_number = player:GetTeamNumber()
	
	if(debugmode) then
		Print("Captain Removed: name: %s steamid: %s exists: %s iscaptain:%s", captain_name[team_number], captain_id[team_number], tostring(captain_exists[team_number]), tostring(is_player_captain[client:GetUserId()]))
	end
	
	if(not islive) then
		self:NotifyGeneric( nil, "%s is no longer captain for %ss.", true, player:GetName(), Plugin:GetTeamName(team_number), false)
	end
	
	captain_clients[team_number] = 0
	captain_name[team_number] = 0
	captain_id[team_number] = 0
	captain_exists[team_number] = false
	is_player_captain[client:GetUserId()] = false
	captain_alltalk[team_number] = true
	
	self:SendNetworkMessage(client, "CloseCaptainMenu", {}, true)
	
	self.dt.sate = STATE_WAITING
end


function Plugin: SendAddPlayer(player)
	if (not self.dt.enabled) then return end
	if (not player) then return end
	
	local player_index = player:GetClient()
	local player_steamid = player_index:GetUserId()
	local player_name = player:GetName()
	
	
	if(captain_exists[TEAM_MARINE]) then 
		--self:NotifyGeneric( nil, "ADDING TO MARINE", true)
		self:SendNetworkMessage(captain_clients[TEAM_MARINE], "AddPlayer", { steamid = player_steamid, name = player_name}, true)
	end
	if(captain_exists[TEAM_ALIEN]) then
		--self:NotifyGeneric( nil, "ADDING TO ALIEN", true)
		self:SendNetworkMessage(captain_clients[TEAM_ALIEN], "AddPlayer", { steamid = player_steamid, name = player_name}, true)
	end
end
function Plugin: SendRemovePlayer(player)
	if (not self.dt.enabled) then return end
	if (not player) then return end

	local Player_Index = player:GetClient()
	local SteamId = Player_Index:GetUserId()
	local Player_Name = player:GetName()
	
	if(captain_exists[TEAM_MARINE]) then 
		self:SendNetworkMessage(captain_clients[TEAM_MARINE], "RemovePlayer", { steamid = SteamId, name =  Player_Name}, true)
	end
	if(captain_exists[TEAM_ALIEN]) then
		self:SendNetworkMessage(captain_clients[TEAM_ALIEN], "RemovePlayer", { steamid = SteamId, name =  Player_Name}, true)
	end
end
function Plugin: SendOpenCaptainMenu(client)
	--Tell this client to close his captain menu if he hasn't already
	if (not self.dt.enabled) then return end
	if (not client) then return end
	
	self:SendNetworkMessage(client, "OpenCaptainMenu", {}, true)
	
	self:SimpleTimer( 1, function()
		Plugin: CheckCaptains()
	end)
end
function Plugin: SendCloseCaptainMenu(client)
	--Tell this client to close his captain menu if he hasn't already
	if (not self.dt.enabled) then return end
	if (not client) then return end
	
	self:SendNetworkMessage(client, "CloseCaptainMenu", {}, true)
end
function Plugin: SendChangeCursor(client)
	--Tell this client to close his captain menu if he hasn't already
	if (not self.dt.enabled) then return end
	if (not client) then return end
	
	self:SendNetworkMessage(client, "ChangeCursor", {}, true)
end


local oldmarine = true
local oldalien = true
function Plugin: CheckAllTalk()
	if (not self.dt.enabled) then return end
	
	local marine_state = captain_alltalk[TEAM_MARINE]
	local alien_state = captain_alltalk[TEAM_ALIEN]
	
	--self:NotifyGeneric( nil, "CheckAllTalk: %s %s", true, tostring(captain_alltalk[TEAM_MARINE]), tostring(captain_alltalk[TEAM_ALIEN]))
	if(marine_state == alien_state and (marine_state ~= oldmarine or alien_state ~= oldalien)) then
		--Disable alltalk.
		option_alltalk = not option_alltalk
		Shared.ConsoleCommand( string.format( "sh_alltalkpregame %s", tostring(option_alltalk)) )
		if(option_alltalk) then
			self:NotifyGeneric( nil, "Alltalk has been enabled at the request of the captains.", true)
		else
			self:NotifyGeneric( nil, "Alltalk has been disabled at the request of the captains, they may agree to turn it back on.", true)
		end
		
		oldmarine = marine_state
		oldalien = alien_state
	end	

end
function Plugin: CheckCaptains()
	if (not self.dt.enabled) then return end
	
	--self:NotifyGeneric( nil, "marine:%s alien:%s", true, tostring(captain_exists[TEAM_MARINE]), tostring(captain_exists[TEAM_ALIEN]))
	
	--if(captain_exists[TEAM_MARINE] and captain_exists[TEAM_ALIEN]) then
	--	Plugin: ChooseRandomTeam()
	--end
	
	
	--set the state to picking
	Plugin: PopulatePlayerList()
	
	--send the captains the menu
	
end
function Plugin: PopulatePlayerList()
	if (not self.dt.enabled) then return end
	
	for _, player in ipairs(Shine:GetAllPlayers()) do
		local team_number = player:GetTeamNumber()
		if(team_number == TEAM_RR) then
			--loop through server looking for people in the readyroom.
			Plugin:SendAddPlayer(player)
			
			--self:NotifyGeneric(nil, "Loop: %s", true, plyr:GetName())
		end
	end
end


function Plugin: DoesClientStillExist(client)
	if(not client) then return false end
	
	return true
end
function Plugin: IsPlayerOnTeam(client)
	local player = client:GetControllingPlayer()
	local team_number = player:GetTeamNumber()
	
	if(team_number == 1 or team_number == 2) then return true end
end
function Plugin: GetTeamName(team_number, capital)
	if(team_number == 0) then
		if(capital) then
			return "ReadyRoom"
		else
			return "readyroom"
		end
	elseif(team_number == 1) then
		if(capital)then
			return "Marine"
		else
			return "marine"
		end
	elseif(team_number == 2) then
		if(capital)then
			return "Alien"
		else
			return "alien"
		end
	elseif(team_number == 3) then
		if(capital)then
			return "Spectate"
		else
			return "spectate"
		end
	end
end
function Plugin: GetOppositeTeam(team_number)
	if(team_number == 0 or team_number == 3) then return 0 end
	
	if(team_number == 1) then
		return 2
	elseif(team_number == 2) then
		return 1
	end
end
function Plugin: ClearCaptains()
	if (not self.dt.enabled) then return end
	
	for i=1, 2 do
		captain_clients[i] = 0
		captain_name[i] = 0
		captain_id[i] = 0
		captain_exists[i] = false
		captain_alltalk[i] = true
	end
	
	local client = {}
	for _, player in ipairs(Shine:GetAllPlayers()) do
		client = player:GetControllingPlayer()
		is_player_captain[client:GetUserId()] = false
	end
end

function Plugin: ChooseRandomTeam()
	local random_team = math.random(1, 2)
	local team_name = Plugin: GetTeamName(random_team, true)

	if(random_team == TEAM_MARINE) then
		Shine:NotifyDualColour( nil, 255, 255, 51,  "Marines",  200, 200, 200, "get first pick.", true, team_name)
	elseif (random_team == TEAM_ALIEN) then
		Shine:NotifyDualColour( nil, 255, 255, 51,  "Aliens",  200, 200, 200, "get first pick.", true, team_name)
	end
	--if(captain_exists[random_team]) then
		--Shine:NotifyDualColour( nil, 76, 153, 0,  "[NRP]",  255, 255, 51, "Randomly chose %ss (%s) for first pick.", true, team_name, captain_name[random_team] )
		--self:NotifyGeneric( nil, "Randomly chose %ss (%s) for first pick.", true, team_name, captain_name[random_team], false)
	--else
		--Shine:NotifyDualColour( nil, 76, 153, 0,  "[NRP]",  255, 255, 51, "Randomly chose %ss for first pick.", true, team_name )
		--self:NotifyGeneric( nil, "Randomly chose %ss for first pick.", true, team_name, false)
	--end
end

function Plugin: CreateCommands()

	local function CursorFix(client)
		if (not self.dt.enabled) then return end
		if (not client) then return end
		--if (not captain_exists[TEAM_MARINE] or not captain_exists[TEAM_ALIEN]) then self:NotifyGeneric( client, "Both teams need a captain to do a random.", true, false)
		
		local steamid = client:GetUserId()
		
		Plugin: SendChangeCursor()
	end
	local CommandCursorFix = self:BindCommand("sh_cursorfix", { "cursor" }, CursorFix, true)
	CommandCursorFix:Help( "Disables mouse cursor if it gets stuck on." )

	local function Random(client)
		if (not self.dt.enabled) then return end
		if (not client) then return end
		--if (not captain_exists[TEAM_MARINE] or not captain_exists[TEAM_ALIEN]) then self:NotifyGeneric( client, "Both teams need a captain to do a random.", true, false)
		
		--local steamid = client:GetUserId()
		--if(is_player_captain[steamid] == false) then return end --only allow captains to pick
		
		Plugin: ChooseRandomTeam()
	end
	local CommandRandom = self:BindCommand("sh_random", { "random", "cr", "rnd", "rand", "flip" }, Random, true)
	CommandRandom:Help( "Randomly chooses alien or marine for first pick." )

	local function Captain(client)
		if (not self.dt.enabled) then return end
		if (not client) then return end
		local player = client:GetControllingPlayer()
		local team_number = player:GetTeamNumber()
		local client_exists = captain_clients[team_number]
	
		if(captain_exists[team_number]) then
			if(not client_exists) then 
				captain_clients[team_number] = 0
				captain_name[team_number] = 0
				captain_id[team_number] = 0
				captain_exists[team_number] = false
				captain_alltalk[team_number] = true
				
				self.dt.sate = STATE_WAITING
				
				Plugin: SetCaptain(client)
				return
			end
			
			if(captain_clients[team_number] == client) then --is this person a captain?
				Plugin: RemoveCaptain(client)
				return
			else
				self:NotifyGeneric( player, "%s is already captain for %s", true, captain_name[team_number], Plugin:GetTeamName(team_number), false)
				return
			end
		end
		
		--they are OK to set as captain.
		Plugin: SetCaptain(client)
	end
	local CommandReady = self:BindCommand("sh_captain", { "cpt", "captain", "capt" }, Captain, true )
	CommandReady:Help( "Volunteer as the captain for your team." )
	
	local function OpenMenu( client)
		if not self.dt.enabled then return end
		
		
		local captain_player = client:GetControllingPlayer()
		local team_number = captain_player:GetTeamNumber()
		local steamid = client:GetUserId()
		if(not captain_exists[team_number]) then 
			Plugin: SetCaptain(client)
			return
		elseif (is_player_captain[steamid]) then
			Plugin: SendOpenCaptainMenu(client)
		end
		
	end
	local CommandAddPlayer = self:BindCommand( "sh_nrp_menu", "cmenu", OpenMenu, true )
	CommandAddPlayer:Help( "Command to open the menu." )
	
	
	local function PickPlayer( client, target )
		if not self.dt.enabled then return end
		
		
		local steamid = client:GetUserId()
		if(is_player_captain[steamid] == false) then return end --only allow captains to pick
		
		local target_player = target:GetControllingPlayer()
		
		if not target_player then return end --make sure his target exists
		
		if target_player:GetTeamNumber() ~= 0 then --make sure the target is in the readyroom
			self:NotifyGeneric(client:GetControllingPlayer(), "Player is no longer in the ready room, can not be picked.", true)
			return
		end
		
		local captain_player = client:GetControllingPlayer()
		local captain_team = captain_player:GetTeamNumber()
		
		local teamname = Plugin: GetTeamName(captain_team, false)
		
		if(debugmode) then
			--Print("%s was picked for %s by %s", target_player:GetName(), teamname, captain_player:GetName())
		end
		
		if(captain_team == 1) then--marine
			Shine:NotifyDualColour(nil, 90, 171, 237, "[NRP]", 200, 200, 200, "%s was picked for %s.", true, target_player:GetName(), teamname)
		elseif(captain_team == 2) then --alien
			Shine:NotifyDualColour(nil, 255, 165, 0, "[NRP]", 200, 200, 200, "%s was picked for %s.", true, target_player:GetName(), teamname)
			--self:NotifyGeneric(nil, "%s was picked for %s.", true, target_player:GetName(), teamname)
		end
		GetGamerules():JoinTeam( target_player, captain_team, nil, true )
	end
	local CommandAddPlayer = self:BindCommand( "sh_nrp_pickplayer", "captainpickplayer1", PickPlayer, true )
	CommandAddPlayer:AddParam{ Type = "client", NotSelf = true, IgnoreCanTarget = true }
	CommandAddPlayer:Help( "<player> Picks the given player for your team [this command is only available for captains]" )
	
	local function ToggleAlltalk( client )
		if not self.dt.enabled then return end
		local steamid = client:GetUserId()
		if(is_player_captain[steamid] == false) then return end --only allow captains to ready
		local player = client:GetControllingPlayer()
		local team_number = player:GetTeamNumber()
		local team_name = Plugin:GetTeamName(team_number, true)
		local opposite_team = Plugin:GetOppositeTeam(team_number)
		if(not captain_exists[opposite_team]) then return end
		--self:NotifyGeneric( nil, "%s alltalk", true, player:GetName())
		
		captain_alltalk[team_number] = not captain_alltalk[team_number]
		
		local myteam = captain_alltalk[team_number]
		local otherteam = captain_alltalk[opposite_team]
		--self:NotifyGeneric( nil, "1: %s %s", true, tostring(captain_alltalk[team_number]), tostring(captain_alltalk[opposite_team]))
		if(captain_alltalk[team_number] ~= captain_alltalk[opposite_team]) then --we are ready, they are not
		
			--self:NotifyGeneric( captain_clients[Plugin:GetOppositeTeam(team_number)], "%ss would like to %s alltalk.", true, team_name, tostring(captain_alltalk[team_number] and "enable" or "disable"))
			self:NotifyGeneric( nil, "%ss would like to %s alltalk.", true, team_name, tostring(captain_alltalk[team_number] and "enable" or "disable"))
		end
		
		Plugin: CheckAllTalk()
	end
	local CommandReady = self:BindCommand("sh_nrp_alltalk", "nrp_alltalk1", ToggleAlltalk, true )
	CommandReady:Help( "Offer to toggle alltalk on or off. Both captains must agree." )
end
function Plugin: NotifyGeneric(Player, String, Format, ...)
	--Shine:NotifyDualColour( Player, 255, 165, 0,  "[NRP]",  200, 200, 200, String, Format, ... )
	Shine:NotifyDualColour( Player, 76, 153, 0,  "[NRP]",  200, 200, 200, String, Format, ... )
end
function Plugin: ReceiveOnResolutionChanged( Client )
end


function Plugin: Cleanup()
	self:Disable()
	self.Enabled = false
end