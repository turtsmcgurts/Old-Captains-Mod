local Plugin = {}

function Plugin:SetupDataTable()
	self:AddDTVar( "boolean", "enabled", 1 )
	self:AddDTVar( "boolean", "islive", 0 )
	self:AddDTVar( "integer (1 to 3)", "state", 1 ) -- 1 waiting for captains ||| 2 Picking ||| 3 Gamestart
	
	local PlayerData = {
		steamid =	"string (64)",
		name	=	"string (64)"
	}
	
	local PlayerPickedData = {
		captain = 	"string (64)",
		steamid =	"string (64)",
		name	=	"string (64)"
	}
	
	local RenamedPlayerData = {
		steamid 	=	"string (64)",
		new_name	=	"string (64)",
		old_name	=	"string (64)"
	}
	
	self:AddNetworkMessage("SetCaptain", { steamid = "string (255)", team = "integer (1 to 2)" }, "Client" )
	self:AddNetworkMessage("AddPlayer", PlayerData, "Client" )
	self:AddNetworkMessage("RemovePlayer", PlayerData, "Client" )
	self:AddNetworkMessage("PlayerRenamed", RenamedPlayerData, "Client" )
	--self:AddNetworkMessage("OpenCaptainMenu", {}, "Client" )
	self:AddNetworkMessage("CloseCaptainMenu", {}, "Client" )
	self:AddNetworkMessage("OpenCaptainMenu", {}, "Client" )
	self:AddNetworkMessage("ChangeCursor", {}, "Client" )
	
	self:AddNetworkMessage( "OnResolutionChanged", {}, "Server")
end

function Plugin:NetworkUpdate( Key, Old, New )
	if Server then return end
	
	--Key is the variable name, Old and New are the old and new values of the variable.
	--Print( "%s has changed from %s to %s.", Key, tostring( Old ), tostring( New ) )
	
	self:ChangeState(Old, New)
end

function Plugin:Initialise()
	self.Enabled = true
	return true
end

Shine:RegisterExtension( "nrpcaptains", Plugin )