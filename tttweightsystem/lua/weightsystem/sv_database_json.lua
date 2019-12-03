if not SERVER then return end

include("sh_weightmanager.lua")
include("sh_playerweight.lua")

local function Message(msg)
    print("[TTT WeightSystem JSON] " .. msg .. ".")
end

function DateTime()
    return os.date( "%y-%m-%d %H:%M:%S" )
end

function SaveTable()
	local tab = util.TableToJSON( WeightSystem.table )
	file.Write("weightsystem/table.json", tab)
	Message("JSON Table Saved...")
end

function ResetTable()
	Message("Resetting weight table")
	
	table.Empty(WeightSystem.table)
	
	createWeightTable()
end

function createWeightTable()
	if table.IsEmpty(WeightSystem.table) then
		WeightSystem.table = {}
	else
		Message("Weight Table is not Empty...")
	end
end

function UpdatePlayerDatabase(ply, weight)
	local newWeight = weight or ply:GetWeight()
	local innocent = ply:GetInnocentCount()
	local traitor = ply:GetTraitorCount()
	local detective = ply:GetDetectiveCount()
	local rounds = ply:GetRoundsPlayed()
	local tRounds = ply:GetRoundsSinceTraitorCount()		
	if ply:IsPlayer() and not ply:IsBot() then
		WeightSystem.table[util.SteamIDFrom64(tostring(ply:SteamID64()))] = {
			Weight = newWeight,
			InnocentRounds = innocent,
			TraitorRounds = traitor,
			DetectiveRounds = detective,
			RoundsPlayed = rounds,
			RoundsSinceTraitor = tRounds,
			LastUpdated = DateTime(),
		}
	end
end

-- Connect database on Initialize
hook.Add("Initialize", "TTTKS_Initialize", function()
    createWeightTable()
end)

-- When player joins check if they have a record already, if not create one and set their default weight.
hook.Add("PlayerInitialSpawn", "TTTWS_PlayerInitialSpawn", function(ply)

	-- Message(WeightSystem.table)

    if ply:IsPlayer() and not ply:IsBot() then
		-- Check the table for their record
		if WeightSystem.table[util.SteamIDFrom64(ply:SteamID64())] then
			Message("Found table data for " .. ply:GetName())
			ply:SetWeight( WeightSystem.table[util.SteamIDFrom64(tostring(ply:SteamID64()))]["Weight"] )
			ply:SetInnocentCount( WeightSystem.table[util.SteamIDFrom64(tostring(ply:SteamID64()))]["InnocentRounds"] )
			ply:SetTraitorCount( WeightSystem.table[util.SteamIDFrom64(tostring(ply:SteamID64()))]["TraitorRounds"] )
			ply:SetDetectiveCount( WeightSystem.table[util.SteamIDFrom64(tostring(ply:SteamID64()))]["DetectiveRounds"] )
			ply:SetRoundsPlayed( WeightSystem.table[util.SteamIDFrom64(tostring(ply:SteamID64()))]["RoundsPlayed"] )
			ply:SetRoundsSinceTraitorCount( WeightSystem.table[util.SteamIDFrom64(tostring(ply:SteamID64()))]["RoundsSinceTraitor"] )			
		else
			Message("No data for " .. ply:GetName())
			ply:SetWeight( defaultWeight )
			ply:SetInnocentCount( 0 )
			ply:SetTraitorCount( 0 )
			ply:SetDetectiveCount( 0 )
			ply:SetRoundsPlayed( 0 )
			ply:SetRoundsSinceTraitorCount( 0 )
			UpdatePlayerDatabase(ply, defaultWeight)
		end
		
   end
   
end)