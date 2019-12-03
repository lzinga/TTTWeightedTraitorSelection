include("sh_playerweight.lua")
include("sh_weightmanager.lua")

 function UpdateMenu()
	net.Start("WeightSystem_WeightInfoUpdated")
	net.SendToServer()
 end
 
net.Receive("WeightSystem_WeightInfo", function(len)
	net.Start("WeightSystem_WeightInfo")
	if net.ReadBool() then
		Frame = vgui.Create( "DFrame" )
		Frame:SetTitle( "TTT Weight Logs" )
		Frame:SetSize( 450, 400 )
		Frame:SetDraggable(true)
		Frame:SetKeyboardInputEnabled(false)
		Frame:MakePopup()
		Frame:Center()
		
		local tabSheet = vgui.Create( "DPropertySheet", Frame )
		tabSheet:Dock( FILL )
		
		local weightList = vgui.Create( "DListView", tabSheet)
		weightList:SetPos(10, 30)
		weightList:SetSize(430, 360)
		weightList:SetMultiSelect( false )
		weightList:AddColumn( "Player" )
		weightList:AddColumn( "Weight" )
		weightList:AddColumn( "Traitor Chance" )
		weightList.OnRowRightClick = function ( panel, line )
			local menu = DermaMenu()
			menu:AddOption( "Get Players SteamID", GetSteamId( weightList:GetLine(line):GetValue(1) ) )
			menu:AddOption( "Reset Weight to Default", function()
				net.Start("WeightSystem_SetDefaultWeight")
				net.WriteEntity( GetPlayerObjectFromName( weightList:GetLine(line):GetValue(1) ) )
				net.SendToServer()
				UpdateMenu()
			end)
			menu:AddOption( "Set Weight", function()
				Derma_StringRequest(
				"Player Weight",
				"Set Player Weight To:",
				"",
				function( text )
					local variable = (tonumber(text) or -1)
					
					-- Disallow weights over 10k
					if variable > 10000 then
						variable = 10000
					end
					
					if variable >= 0 then
						net.Start("WeightSystem_SetWeight")
						net.WriteEntity( GetPlayerObjectFromName( weightList:GetLine(line):GetValue(1) ) )
						net.WriteUInt( variable, 16)
						net.SendToServer()
						UpdateMenu()
					else
						Derma_Message( "You did not enter a proper integer.", "Error", "OK" )
					end
				end,
				function( text )  end)
			
			
			end)
			menu:Open()
		end
		
		for i = 1, #player.GetAll() do
			local pply = net.ReadEntity()
			local playerWeight = net.ReadUInt(16)
			local playerTraitorChance = net.ReadUInt(16)	
			weightList:AddLine(pply:GetName(), playerWeight, playerTraitorChance )
		end
		
		local rolePanel = vgui.Create( "DPanel", tabSheet )
		rolePanel:SetPos( 10, 30 )
		rolePanel:SetSize(400, 360)
		
		local roleList = vgui.Create( "DListView", rolePanel)
		roleList:SetPos(10, 45)
		roleList:SetSize(400, 275)
		roleList:SetMultiSelect( false )
		roleList:AddColumn( "Player" )
		roleList:AddColumn( "Rounds Played" )
		roleList:AddColumn( "Innocent" )
		roleList:AddColumn( "Detective" )
		roleList:AddColumn( "Traitor" )
		for k, v in pairs(player.GetAll()) do
			roleList:AddLine(v:GetName(), v:GetRoundsPlayed(), v:GetInnocentCount(),  v:GetDetectiveCount(), v:GetTraitorCount() )
		end
		
		local roleListRefresh = vgui.Create("DButton", rolePanel)
		roleListRefresh:SetText("Refresh")
		roleListRefresh:SetSize(400, 25)
		roleListRefresh:SetPos(10, 10)
		roleListRefresh.DoClick = function()
		roleList:Clear()
			for k, v in pairs(player.GetAll()) do
				roleList:AddLine(v:GetName(), v:GetRoundsPlayed(), v:GetInnocentCount(),  v:GetDetectiveCount(), v:GetTraitorCount() )
			end
		end
	
		
		-- Update records
		net.Receive("WeightSystem_WeightInfoUpdated", function(len)
			if not IsValid(Frame) then return end
			if net.ReadBool() then
				weightList:Clear()
				for i = 1, #player.GetAll() do
					local pply = net.ReadEntity()
					local playerWeight = net.ReadUInt(16)
					local playerTraitorChance = net.ReadUInt(16)
					weightList:AddLine(pply:GetName(), playerWeight, playerTraitorChance)
				end
			end
		end)
		
		tabSheet:AddSheet( "Weights", weightList )
		tabSheet:AddSheet( "Role Count", rolePanel )
	else
		Derma_Message( "You do not have permission.", "Error", "OK" )
	end
end)

net.Receive("WeightSystem_SetWeight", function( len )
	if not net.ReadBool() then
		Derma_Message( "You do not have permission.", "Error", "OK" )
	end
end)


	
local function TryOpenMenu( ply )
	net.Start("WeightSystem_WeightInfo")
	net.SendToServer()
end
concommand.Add("ttt_weightlogs", TryOpenMenu)

local function TryResetTable( ply)
	net.Start("WeightSystem_ResetTable")
	net.SendToServer()
end
concommand.Add("ttt_weightreset", TryResetTable)


function GetPlayerObjectFromName( plyName )
	for k, v in pairs(player.GetAll()) do
		if v:GetName() == plyName then
			return v
		end
	end
	Derma_Message( "Could not get the player object.", "Error", "OK" )
end

function GetSteamId( plyName )
	for k, v in pairs(player.GetAll()) do
		if v:GetName() == plyName then
			SetClipboardText(v:SteamID())
			return
		end
	end
	Derma_Message( "Could not get the SteamID", "Error", "OK" )
end