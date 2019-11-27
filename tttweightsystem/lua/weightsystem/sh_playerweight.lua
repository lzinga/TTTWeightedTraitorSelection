PLAYER = FindMetaTable "Player"
	local sv_cheats = GetConVar("sv_cheats")

	function PLAYER:IsVerified()
		isVerified = false
		for i = 1, #WeightSystem.GroupPermissions do
			local groupToCheck = WeightSystem.GroupPermissions[i]
			
			-- User is in group
			isVerified = (self:IsUserGroup( groupToCheck ) and IsValid(self)) or sv_cheats:GetBool()
			if isVerified then break end
		end
		
		if not isVerified then
			 self:PrintMessage(HUD_PRINTCONSOLE, "You do not have access to that command.")
		end
		
		return isVerified
	end

	
function PLAYER:GetWeight()
	local weight = self.Weight
	if weight == nil then
		weight = DefaultWeight()
	end
	return weight
end

function PLAYER:GetRoundsPlayed()
	return self:GetNWInt("TTTWeightSystem_RoundsPlayed") 
end

function PLAYER:GetInnocentCount()
	return self:GetNWInt("TTTWeightSystem_InnocentCount") 
end

function PLAYER:GetDetectiveCount()
	return self:GetNWInt("TTTWeightSystem_DetectiveCount") 
end

function PLAYER:GetTraitorCount()
	return self:GetNWInt("TTTWeightSystem_TraitorCount")
end

-- Phantom139: Added
function PLAYER:GetRoundsSinceTraitorCount()
	return self:GetNWInt("TTTWeightSystem_NonTraitorRoundsCount") 
end

function SetPlayerFunModeScale( ply )
	if GetConVar("ttt_weight_system_fun_mode"):GetBool() then
		local min = 1.2
		local max = 1.4
		local percentage = ((max - min) * (ply:GetTraitorChance() / 100)) + min		
		
		local bones = {
			"ValveBiped.Bip01_Spine",
			"ValveBiped.Bip01_Spine1",
			"ValveBiped.Bip01_Spine2",
			"ValveBiped.Bip01_Spine4",
			"ValveBiped.Bip01_L_Clavicle",
			"ValveBiped.Bip01_R_Clavicle"
		}
		
		for i = 1, #bones do
			ply:ManipulateBoneScale( ply:LookupBone(bones[i]), Vector( percentage, percentage, percentage ) )
		end
				
	end
end

function SetFunModeScaleAllPlayers()
	if GetConVar("ttt_weight_system_fun_mode"):GetBool() then
		for k,v in pairs(player.GetAll()) do
			SetPlayerFunModeScale( v )
		end
	end
end

function GetActivePlayersTotalWeight()
	local totalWeight = 0
	for k,ply in pairs(player.GetAll()) do
		if IsValid(ply) and (ply:GetWeight() ~= nil) then
			totalWeight = totalWeight + ply:GetWeight()
		end
	end
	return totalWeight
end

function PLAYER:GetTraitorChance()
	if IsValid(self) then
		return math.floor( (self:GetWeight() / GetActivePlayersTotalWeight()) * 100 )
	end
end

if SERVER then

	util.AddNetworkString("WeightSystem_ResetTable")
	net.Receive("WeightSystem_ResetTable", function(len, ply)
		if(ply:IsAdmin()) then
			ResetTable()
		end
	end)

	util.AddNetworkString("WeightSystem_WeightInfo")
    net.Receive("WeightSystem_WeightInfo", function(len, ply)
		SendWeightInfo( ply, "WeightSystem_WeightInfo")
    end)
	
	util.AddNetworkString("WeightSystem_WeightInfoUpdated")
    net.Receive("WeightSystem_WeightInfoUpdated", function(len, ply)
		SendWeightInfo( ply, "WeightSystem_WeightInfoUpdated")
    end)

	-- Function for Sending WeightInfo
	function SendWeightInfo( ply, netBuffer)
		net.Start(netBuffer)
		if not ply:IsVerified() then
			net.WriteBool(false)
			net.Send( ply )
		else
			net.WriteBool(true)
			for k, v in pairs( player.GetAll()) do
				net.WriteEntity(v)
				net.WriteUInt(v:GetWeight(), 16)
				net.WriteUInt(v:GetTraitorChance(), 16)
			end
			net.Send( ply )
		end
	end
	
	util.AddNetworkString("WeightSystem_SetWeight")
    net.Receive("WeightSystem_SetWeight", function(len, ply)
		net.Start("WeightSystem_SetWeight")
		local playerToUpdate = net.ReadEntity()
		local weightToUse = net.ReadUInt(16)
		if not ply:IsVerified() then
			net.WriteBool(false)
			net.Send( ply )
		else
			net.WriteBool(true)
			playerToUpdate:SetWeight( weightToUse )
			SetPlayerFunModeScale( playerToUpdate ) -- Set players model weight, fun mode.
			net.Send( ply )
			
			for k,v in pairs(player.GetAll()) do
				if v:IsVerified() then
					if v:GetName() == playerToUpdate:GetName()then
						v:PrintMessage( HUD_PRINTTALK, ply:GetName() .. " set his weight to: " .. weightToUse)
					else
						v:PrintMessage( HUD_PRINTTALK, ply:GetName() .. " set " .. playerToUpdate:GetName() .. "s weight to: " .. weightToUse)
					end
				end
			end
		end
    end)

	util.AddNetworkString("WeightSystem_SetDefaultWeight")
    net.Receive("WeightSystem_SetDefaultWeight", function(len, ply)
		net.Start("WeightSystem_SetDefaultWeight")
		local playerToUpdate = net.ReadEntity()
		if not ply:IsVerified() then
			net.WriteBool(false)
			net.Send( ply )
		else
			net.WriteBool(true)
			local defaultWeight = DefaultWeight()
			playerToUpdate:SetWeight( defaultWeight )
			net.Send( ply )
			
			for k,v in pairs(player.GetAll()) do
				if v:IsVerified() then
					if ply:GetName() == playerToUpdate:GetName()then
						v:PrintMessage( HUD_PRINTTALK, ply:GetName() .. " reset his weight to a default value of: " .. defaultWeight)
					else
						v:PrintMessage( HUD_PRINTTALK, ply:GetName() .. " set " .. playerToUpdate:GetName() .. "s weight to: " .. weightToUse)
					end
				end
			end
		end
    end)
		
	function PLAYER:SetWeight( weight )
		self.Weight = weight
	end
	
	function PLAYER:AddWeight( weight )
		self.Weight = self:GetWeight() + weight
	end
		
	function PLAYER:SetRoundsPlayed( count )
		return self:SetNWInt("TTTWeightSystem_RoundsPlayed", count) 
	end
	
	function PLAYER:SetInnocentCount( count )
		self:SetNWInt("TTTWeightSystem_InnocentCount", count)
	end
	
	function PLAYER:SetDetectiveCount( count )
		self:SetNWInt("TTTWeightSystem_DetectiveCount", count)
	end
	
	function PLAYER:SetTraitorCount( count )
		self:SetNWInt("TTTWeightSystem_TraitorCount", count)
	end
	
	-- Phantom139: Added
	function PLAYER:SetRoundsSinceTraitorCount( count )
		self:SetNWInt("TTTWeightSystem_NonTraitorRoundsCount", count)
	end	
end
