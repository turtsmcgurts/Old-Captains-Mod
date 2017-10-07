local Shine = Shine
local Plugin = Plugin

local GetAllClients = Shine.GetAllClients
local GetClientByNS2ID = Shine.GetClientByNS2ID

local PlayerSteamIds = {} -- local steamid = PlayerSteamIds[playername]

local SGUI = Shine.GUI
local CaptainMenu = {}
local Player_List = {}

local STATE_WAITING = 1
local STATE_PICKING = 2
local STATE_PLAYING = 3


Shine.VoteMenu:EditPage( "Main", function( self )
    self:AddSideButton( "NRP Captain Menu", function()
		Shared.ConsoleCommand( string.format( "sh_nrp_menu") )
    end )
end ) 

local Colors = {
	Background = Colour(0.6, 0.6, 0.6, 0.4),
	Dark = Colour(0.2, 0.2, 0.2, 0.8),
	Highlight = Colour(0.5, 0.5, 0.5, 0.8),
    White = Colour(1.0, 1.0, 1.0, 1.0),
	PanelGray = Colour(0.49, 0.49, 0.49, 0.6)
}

local Skin = {
	Button = {
		ActiveCol = Colors.Highlight,
		InactiveCol = Colors.Dark,
		ModeText = Colour( 1, 1, 1, 1 )
	},
	Panel = {
		Default = Colors.Background,
		Dark = Colors.Dark,
		Gray = Colors.PanelGray
	}
}

function CaptainMenu:Create()
	if (Plugin.dt.state == STATE_PLAYING) then return end
	--if self.Created then return end
	
	local ScreenWidth = Client.GetScreenWidth()
	local ScreenHeight = Client.GetScreenHeight()
	
	local Panel = SGUI:Create("Panel")
	Panel:SetAnchor ("TopLeft")
	--Panel:SetSize	(Vector(ScreenWidth * 0.13, ScreenHeight * 0.455, 0)) --BEFORE ALLTALK BUTTON
	--Panel:SetPos	(Vector(ScreenWidth * 0.856, ScreenHeight * 0.41, 0))	 --BEFORE ALLTALK BUTTON
	Panel:SetSize	(Vector(ScreenWidth * 0.13, ScreenHeight * 0.45, 0))
	Panel:SetPos	(Vector(ScreenWidth * 0.865, ScreenHeight * 0.34, 0))
	
	Panel:SkinColour()
	self.Panel = Panel
	local PanelSize = Panel:GetSize()		
	--local Skin = SGUI:GetSkin()
	
	local TitlePanel = SGUI:Create( "Panel", Panel )
	TitlePanel:SetSize( Vector( PanelSize.x, 40, 0 ) )
	--TitlePanel:SetColour( Skin.WindowTitle )
	TitlePanel:SetColour(Skin.Panel.Default)
	TitlePanel:SetAnchor( "TopLeft" )
	local TitlePanelSize = TitlePanel:GetSize()

	local TitleLabel = SGUI:Create( "Label", TitlePanel )
	TitleLabel:SetAnchor( "CentreMiddle" )
	TitleLabel:SetFont( Fonts.kAgencyFB_Small )
	TitleLabel:SetText( "Captain Menu" )
	TitleLabel:SetTextAlignmentX( GUIItem.Align_Center )
	TitleLabel:SetTextAlignmentY( GUIItem.Align_Center )
	TitleLabel:SetPos( Vector( -18, 0, 0 ) )
	--TitleLabel:SetColour( Skin.BrightText )
	TitleLabel:SetColour( Skin.Button.ModeText )
	
	local CloseButton = SGUI:Create( "Button", TitlePanel )
	CloseButton:SetSize( Vector( 36, 36, 0 ) )
	CloseButton:SetText( "X" )
	CloseButton:SetAnchor( "TopRight" )
	CloseButton:SetPos( Vector( -38, 2, 0 ) )
	CloseButton.UseScheme = false
	--CloseButton:SetActiveCol( Skin.CloseButtonActive )
	--CloseButton:SetInactiveCol( Skin.CloseButtonInactive )
	--CloseButton:SetTextColour( Skin.BrightText )
	CloseButton:SetActiveCol( Skin.Button.ActiveCol )
	CloseButton:SetInactiveCol( Skin.Button.InactiveCol )
	CloseButton:SetTextColour( Skin.Button.ModeText )

	function CloseButton.DoClick()
		Panel:SetIsVisible(false)
	end
	
	local ListPanel = SGUI:Create( "Panel", Panel )
	ListPanel:SetSize( Vector( PanelSize.x - 6, ((PanelSize.y - TitlePanelSize.y) - 45), 0 ) )
	ListPanel:SetPos( Vector( 3, TitlePanelSize.y + 3, 0 ) )
	--ListPanel:SetColour( Skin.WindowTitle )
	ListPanel:SetColour( Skin.Panel.Dark )
	ListPanel:SetAnchor( "TopLeft" )
	ListPanel:SkinColour()
	local ListPanelSize = ListPanel:GetSize()
	
	self.ListItems = {}
	--local List = SGUI:Create( "List", Panel )
	local List = ListPanel:Add( "List" )
	List:SetAnchor( "TopLeft" )
	List:SetPos( Vector( 0, 0, 0 ) )
	List:SetColumns( 1, "Player List" )
	List:SetSpacing( 1.0 )
	List:SetSize( Vector( ListPanelSize.x, ListPanelSize.y, 0 ) )
	List.ScrollPos = Vector( -10, 0, 0 )
	
	self.ListItems = List

		
	local PickButton = SGUI:Create( "Button", Panel )
	local PickButtonSize = PickButton:GetSize()
	PickButton:SetText( "Pick Player" )
	PickButton:SetAnchor( "BottomLeft" )
	PickButton:SetSize( Vector( PanelSize.x - 6, 35, 0 ) )
	--PickButton:SetPos( Vector( 0, -(PickButtonSize.y*2), 0 ) )
	PickButton:SetPos( Vector( 3, -38, 0 ) )
	PickButton.UseScheme = false
	--PickButton:SetActiveCol( Skin.CloseButtonActive )
	--PickButton:SetInactiveCol( Skin.CloseButtonInactive )
	--PickButton:SetTextColour( Skin.BrightText )
	PickButton:SetActiveCol( Skin.Button.ActiveCol )
	PickButton:SetInactiveCol( Skin.Button.InactiveCol )
	PickButton:SetTextColour( Skin.Button.ModeText )
	
	function PickButton.DoClick()
		local selected_row = List:GetSelectedRow()
		if(not selected_row) then Print("(PickButton.DoClick) selected_row false") return end
		local index = selected_row.Index
		local Rows = List.Rows
		local steamid = PlayerSteamIds[Rows[index]:GetColumnText(1)]
		Print("Selected row index %i. Player '%s' (%s)", selected_row.Index, Rows[index]:GetColumnText(1), steamid)
		Shared.ConsoleCommand( string.format( "sh_nrp_pickplayer %s", steamid ) )
	end


	
	
	--SGUI:EnableMouse( true )
	self.Created = true
end

function CaptainMenu:Destroy()
	--self.Created = false
	
	--if self.Visible then
	--	self:SetIsVisible( false )
	--end
	
	--if(self.Panel) then 
	--	self.Panel:SetIsVisible( false )
	--end
	self.Panel:SetParent()
	self.Panel:Destroy()
	Print("Menu Destroyed")
end
--[[
function CaptainMenu:UpdateList(Message)
	if not self.Created then 
		Plugin:SimpleTimer( 1, function() self:UpdateList( Message ) end )
		return
	end

	local steamid = Message.steamid
	local List = self.ListItems
	local Rows = List.Rows
	
	
	for i = 1, List.RowCount do
		Print("%s %s", Rows[i]:GetColumnText(2), Message.steamid)
		if (Rows[i]:GetColumnText(2) == Message.steamid) then
			Print ("Removed %s", Message.steamid)
			List:RemoveRow(i)
			break
		end
	end
	
	List:AddRow(Message.name, Message.steamid)
end --]]

function CaptainMenu:AddToList(Message)
	if(Plugin.dt.state == STATE_PLAYING) then return end
	CaptainMenu:RemoveFromList(Message)
	if not self.Created then 
		Plugin:SimpleTimer( 1, function() self:AddToList( Message ) end )
		return
	end
	local steamid = Message.steamid
	local List = self.ListItems
	local Rows = List.Rows
	
	--Print("Added %s (%s) to playerlist at index %i.", Message.name, steamid, List.RowCount+1)
	PlayerSteamIds[Message.name] = steamid
	List:AddRow(Message.name)
end
function CaptainMenu:RemoveFromList(Message)
	if(Plugin.dt.state == STATE_PLAYING) then return end
	if not self.Created then 
		Plugin:SimpleTimer( 1, function() self:RemoveFromList( Message ) end )
		return
	end
	local List = self.ListItems
	local Rows = List.Rows
		
	for i = 1, List.RowCount do
		local name = Rows[i]:GetColumnText(1) --works
		local target_steamid = PlayerSteamIds[name]
		--Print("(Remove Check Print for '%s' at index %i) %s and %s", Rows[i]:GetColumnText(1), i, target_steamid, Message.steamid)
		--Print("%s %s", target_steamid, Message.steamid)
		if (target_steamid == Message.steamid) then
			--Print ("Removed %s (%s)", Message.name, Message.steamid)
			List:RemoveRow(i)	
			break
		end
	end
end


function Plugin:ReceiveChangeCursor()
	SGUI:EnableMouse(false)
end
function Plugin:ReceiveOpenCaptainMenu(Message)
	--if(self.dt.state == STATE_PLAYING) then return end
	--if(not CaptainMenu:Created) then
		CaptainMenu:Create()
	--end
	CaptainMenu:SetIsVisible(true)
end
function Plugin:ReceiveAddPlayer(Message)
	--if(self.dt.state == STATE_PLAYING) then return end
	local SteamId = Message.steamid
	if not SteamId then return end
	local Name = Message.name
	
	
	CaptainMenu:AddToList(Message)
end
function Plugin:ReceiveRemovePlayer(Message)
	--if(self.dt.state == STATE_PLAYING) then return end
	CaptainMenu:RemoveFromList(Message)
end
function Plugin:ReceiveCloseCaptainMenu(Message)
	--if(self.dt.state == STATE_PLAYING) then return end
	--CaptainMenu:SetIsVisible(false)
	
	CaptainMenu:Destroy()
end
function Plugin:ReceiveSetCaptain(Message)
	--if(self.dt.state == STATE_PLAYING) then return end
	--Print("%s is the new captain for %i", Message.steamid, Message.team)
	local SteamId = Message.steamid
	if not SteamId then return end
	local Name = Message.name
	
	CaptainMenu:Create()
	--CaptainMenu:SetIsVisible(true)
end
function Plugin:ReceivePlayerRenamed(Message)
	--if(self.dt.state == STATE_PLAYING) then return end
	local steamid = Message.steamid
	if not steamid then return end
	local new_name = Message.new_name
	local old_name = Message.old_name
	Print("PlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamedPlayerRenamed")
	if(PlayerSteamIds[old_name] ~= 0) then
		--PlayerSteamIds[old_name] = 0
		--PlayerSteamIds[new_name] = steamid
	end
	
	if not self.Created then 
		Plugin:SimpleTimer( 1, function() self:ReceivePlayerRenamed( Message ) end )
		return
	end
	local List = self.ListItems
	local Rows = List.Rows
	
	
	for i = 1, List.RowCount do
		local row = Rows[i]:GetColumnText(1)
		--local target_steamid = PlayerSteamIds[row]
		--Print("%s %s", target_steamid, Message.steamid)
		--if (target_steamid == Message.steamid) then
			--Print ("Removed %s", Message.steamid)
		--	List:RemoveRow(i)
		--	List:AddRow(new_name)
		--	break
		--end
	end
end


function Plugin:ChangeState( OldState, NewState )
	--if(self.dt.state == STATE_PLAYING) then return end
end

function CaptainMenu:SetIsVisible( Bool )	
	--if(Plugin.dt.state == STATE_PLAYING) then return end
	if(self.Panel) then 
		self.Panel:SetIsVisible( Bool )
	end

	self.Visible = Bool
end

function Plugin:Initialise()
	--Player_List = GetAllClients()
	--local Clients, Count = Shine.GetAllClients()
	--Plugin:Notify( nil, "Count %i", Count)
	
	--CaptainMenu:Create()
	--CaptainMenu:SetIsVisible( false )
	
	self.Enabled = true
	return true
end

function Plugin:OnResolutionChanged()
	--if(self.dt.state == STATE_PLAYING) then return end
	CaptainMenu:Destroy()
	CaptainMenu:Create()
	self:SendNetworkMessage( "OnResolutionChanged", {}, true )
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )

	CaptainMenu:Destroy()
end


