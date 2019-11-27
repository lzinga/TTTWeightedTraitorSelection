AddCSLuaFile("cl_init.lua")
AddCSLuaFile("sh_playerweight.lua")
AddCSLuaFile("sh_weightmanager.lua")

include("sv_database.lua")
include("sh_weightmanager.lua")
include("sh_playerweight.lua")
include("sv_message.lua")

CreateConVar("ttt_karma_increase_weight", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Enables karma increased weight. Set ttt_karma_increase_weight_threshold for the minimum karma needed.")
CreateConVar("ttt_karma_increase_weight_threshold", "950", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Minimum karma for giving very little bonus weight to the player. Has a chance to give 0 extra weight. (default 950, based off of default max karma)")
CreateConVar("ttt_show_traitor_chance", "1", FCVAR_ARCHIVE, "At the beginning of every round it will show the chance of the player being traitor in the next round (default 1)")
CreateConVar("ttt_weight_system_fun_mode", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Sets the players player model scale to the players weight, physically making them their weight. Would not suggest this to be active on serious games. (Default 0)")
CreateConVar("ttt_ws_show_round_statistics", "1", FCVAR_ARCHIVE, "At the beginning of every round, it will show the statistics of a player's rounds and role counts (default 1)")


function AddWeightForGroups()
	if WeightSystem.GroupWeight ~= nil then
		for i = 1, #WeightSystem.GroupWeight do
			for k,v in pairs(player.GetAll()) do
				if not v:IsSpec() and IsValid(v) then
					local groupName = WeightSystem.GroupWeight[i].GroupName
					if v:IsUserGroup( groupName ) then
						local minWeight = WeightSystem.GroupWeight[i].MinWeight
						local maxWeight = WeightSystem.GroupWeight[i].MaxWeight
						local weight = math.random(minWeight, maxWeight)
						if not (weight == 0) then
							v:AddWeight( weight )
							Message( v:GetName() .. " was given extra weight for being in group: " .. groupName )
						end
					end
				end
			end
		end
	end
end

function findLowestGroupWeight(v)
	local lowest = 999999
	if WeightSystem.GroupWeight ~= nil then
		for i = 1, #WeightSystem.GroupWeight do
			if not v:IsSpec() and IsValid(v) then
				local groupName = WeightSystem.GroupWeight[i].GroupName
				if v:IsUserGroup( groupName ) then
					local groupCap = WeightSystem.GroupWeight[i].cappedWeight
					if groupCap < lowest then
						lowest = groupCap
					end
				end
			end
		end
	end
	return lowest
end

math.randomseed( os.time() )
local function shuffleTable( t )
	local rand = math.random 
	local iterations = #t
	local j
    
	for i = iterations, 2, -1 do
		j = rand(i)
		t[i], t[j] = t[j], t[i]
	end
end

hook.Add("TTTBeginRound", "TTTWS_BeginRound", function()
	-- Set players role count
	for k,v in pairs(player.GetAll()) do
		-- Send weight info to all players (Only admins will be able to get right message).
		SendWeightInfo( v, "WeightSystem_WeightInfoUpdated")
		TellPlayersTraitorChance( v )

		SetFunModeScaleAllPlayers() -- Will only happen if the convar is set.
	end
   
end)

hook.Add("PlayerSay", "TTTWS_PlayerSay", function(ply, text, teamOnly)
	if string.find(string.lower(text), string.lower(WeightSystem.TraitorChanceCommand)) then
		TellPlayersTraitorChance(ply)
	end
end)

function SelectPlayerForTraitor( choices, prev_roles )
	local totalWeight = 0
	--local minimumWeight = math.floor((totalWeight * .2))

	for k, v in pairs(choices) do
		totalWeight = totalWeight + v:GetWeight()
	end
	print( "Total Weight: " .. totalWeight )
	
	local r = math.random(1, totalWeight)
	print( "Amount to beat: " .. r)
	
	local defaultT
	local lastChance
	
	for k,v in pairs(choices) do
		
		-- Sets the currently being validated player as the default T to be returned.
		defaultT = v
		
		-- Check to see if the randomly selected number minus the current players weight is less then 0 it means they win the role.
		print( v:GetName() .. ": " .. r .. " - " .. v:GetWeight() .. " = " .. r - v:GetWeight())

		if (r - v:GetWeight()) <= 0 then
			
			-- Set the last chance player to current player, if it ends up not accepting a player to return it will return the last known person in loop.
			 lastChance = v
			if IsValid(v) and ( (not table.HasValue(prev_roles[ROLE_TRAITOR], v)) or ( math.random(1, 3) == 2) ) then
				return v
			end
		end
		r = r - v:GetWeight()
	end
	
	if lastChance ~= nil then
		return lastChance
	end
	
	return defaultT
end


-- Overwrite functions
GetTraitorCount = nil
GetDetectiveCount = nil
hook.Add( "Initialize", "TTTWS_Initialize", function ()
	
	-- Find the GetTraitorCount and GetDetectiveCount functions
	for i = 1, math.huge do
		local k, v = debug.getupvalue( SelectRoles, i )
		if k == "GetTraitorCount" then
			GetTraitorCount = v
		end
		if k == "GetDetectiveCount" then
			GetDetectiveCount = v
		end
		
		if GetTraitorCount ~= nil and GetDetectiveCount ~= nil or k == nil then
			break
		end
	end

	-- Select Roles
	function SelectRoles()
		local choices = {}
		local prev_roles = {
			[ROLE_INNOCENT] = {},
			[ROLE_TRAITOR] = {},
			[ROLE_DETECTIVE] = {}
		}

		if not GAMEMODE.LastRole then GAMEMODE.LastRole = {} end

		-- Get Choices and set to innocent
		for k,v in pairs(player.GetAll()) do
			-- if IsValid(v) and (not v:IsSpec()) and (not v:IsBot()) then
			if IsValid(v) and (not v:IsSpec()) then
				-- save previous role and sign up as possible traitor/detective
				local r = GAMEMODE.LastRole[v:UniqueID()] or v:GetRole() or ROLE_INNOCENT

				table.insert(prev_roles[r], v)

				table.insert(choices, v)

				v:SetRoundsPlayed( v:GetRoundsPlayed() + 1)			
			end
			-- Set everyone to innocent.
			v:SetRole(ROLE_INNOCENT)
		end

		-- determine how many of each role we want
		local choice_count = #choices
		local traitor_count = GetTraitorCount(choice_count)
		local det_count = GetDetectiveCount(choice_count)

		if choice_count == 0 then return end

		print("Choice Count: " .. choice_count)
		print("Traitor Count: " .. traitor_count)
		print("Detective Count: " .. det_count)

		-- first select traitors
		local ts = 0
		while ts < traitor_count do
			shuffleTable(choices)

			selectedPlayer = SelectPlayerForTraitor( choices, prev_roles )
			selectedPlayer:SetRole( ROLE_TRAITOR )
			selectedPlayer:SetWeight( DefaultWeight() )
			table.RemoveByValue( choices, selectedPlayer )
			ts = ts + 1

			selectedPlayer:SetTraitorCount( selectedPlayer:GetTraitorCount() + 1 )
			-- Phantom139: Added
			selectedPlayer:SetRoundsSinceTraitorCount( 0 )			
		end

		-- now select detectives, explicitly choosing from players who did not get
		-- traitor, so becoming detective does not mean you lost a chance to be
		-- traitor
		local ds = 0
		local min_karma = GetConVarNumber("ttt_detective_karma_min") or 0

		while (ds < det_count) and (#choices >= 1) do

			-- sometimes we need all remaining choices to be detective to fill the
			-- roles up, this happens more often with a lot of detective-deniers
			if #choices <= (det_count - ds) then
				for k, pply in pairs(choices) do
					if IsValid(pply) then
						pply:SetRole(ROLE_DETECTIVE)
						pply:SetDetectiveCount( pply:GetDetectiveCount() + 1 )
						pply:SetRoundsSinceTraitorCount( pply:GetRoundsSinceTraitorCount() + 1 )				  
					end
				end

				break -- out of while
			end

			local pick = math.random(1, #choices)
			local pply = choices[pick]

			-- we are less likely to be a detective unless we were innocent last round
			if (IsValid(pply) and
				((pply:GetBaseKarma() > min_karma and
				table.HasValue(prev_roles[ROLE_INNOCENT], pply)) or
				math.random(1,3) == 2)) then

				-- if a player has specified he does not want to be detective, we skip
				-- him here (he might still get it if we don't have enough
				-- alternatives)
				if not pply:GetAvoidDetective() then
					pply:SetRole(ROLE_DETECTIVE)
					pply:SetDetectiveCount( pply:GetDetectiveCount() + 1 )
					pply:SetRoundsSinceTraitorCount( pply:GetRoundsSinceTraitorCount() + 1 )			   
					ds = ds + 1
				end

				table.remove(choices, pick)
			end
		end

		-- Update all innocent players to have increased weight
		for k,v in pairs(choices) do
			if IsValid(v) and (not v:IsSpec()) and v:GetRole() == ROLE_INNOCENT then		
				-- Phantom139: Update the player role stats
				v:SetInnocentCount( v:GetInnocentCount() + 1 )
				v:SetRoundsSinceTraitorCount( v:GetRoundsSinceTraitorCount() + 1 )				
				-- If the players karma is greater then the server threshold add weight to him.
				if GetConVar("ttt_karma_increase_weight"):GetBool() and v:GetBaseKarma() > GetConVar("ttt_karma_increase_weight_threshold"):GetInt() then
					local extra = math.random(0, 2)
					v:AddWeight( extra )
					print(v:GetName() .. " was given " .. extra .. " extra weight for having good karma.")
				end
				-- Phantom139: Added this block of code here to restrict players chances if they are in a group to the group's cap.
				if v:GetTraitorChance() > findLowestGroupWeight(v) then
					print(v:GetName() .. " is capped by a group restriction, no additional weight granted.")
				else
					-- Give normal amount of weight
					v:AddWeight( math.random(6, 10) )
					-- Phantom139: Added a block here to add additional weight for "streaks" of not being a traitor.
					if v:GetRoundsSinceTraitorCount() >= math.random(3, 5) then
						local bonusWeight = math.floor(math.pow(1.75, v:GetRoundsSinceTraitorCount()))
						v:AddWeight( bonusWeight )
						print(v:GetName() .. " was given " .. bonusWeight .. " extra weight for being on a streak of not being the traitor. ( " .. v:GetRoundsSinceTraitorCount() .. " rounds)")
					end
				end			
			end
		end

		AddWeightForGroups()

		-- Phantom139: Move the update DB statement here to address the bug where the table doesn't save on the last round of a match.
		UpdatePlayerDbWeights()
		
		-- Update the Database weights.
		GAMEMODE.LastRole = {}

		for _, ply in pairs(player.GetAll()) do
			-- initialize credit count for everyone based on their role
			ply:SetDefaultCredits()

			-- store a uid -> role map
			GAMEMODE.LastRole[ply:UniqueID()] = ply:GetRole()
			end
		end -- End of SelectRoles()
end)
