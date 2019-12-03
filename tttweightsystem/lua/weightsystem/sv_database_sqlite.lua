if not SERVER then return end

include("sh_weightmanager.lua")
include("sh_playerweight.lua")

local function Message(msg)
    print("[TTT WeightSystem SQLite] ".. msg .. ".")
end

function DateTime()
    return os.date( "%y-%m-%d %H:%M:%S" )
end

function SaveTable()
	Message("SaveTable() Call ignored, only used in JSON")
end

function ExecuteQuery(str, callback)
	callback = callback or function() end

	Message("ExecuteQuery(" .. str ..")")

	local result = sql.Query(str)

	if result then
		Message("Result: " .. result)
		callback(result)
	end
end

function ResetTable()
	Message("Resetting weight table")
	
	ExecuteQuery("DROP TABLE IF EXISTS " .. WeightSystem.TableName)
	
	CheckSQLiteTable()
end

function CheckSQLiteTable()
    Message("Connected to database")
	
	ExecuteQuery("CREATE TABLE IF NOT EXISTS " .. WeightSystem.TableName .. " (Id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, " ..
				 "SteamId BIGINT UNSIGNED NOT NULL, " ..
				 "Weight SMALLINT UNSIGNED NOT NULL, " ..
				 "InnocentRounds SMALLINT UNSIGNED NOT NULL, " ..
				 "TraitorRounds SMALLINT UNSIGNED NOT NULL, " .. 
				 "DetectiveRounds SMALLINT UNSIGNED NOT NULL, " .. 
				 "RoundsPlayed SMALLINT UNSIGNED NOT NULL, " .. 
				 "RoundsSinceTraitor SMALLINT UNSIGNED NOT NULL, " .. 
	             "LastUpdated DATETIME DEFAULT '" .. DateTime() .. "', PRIMARY KEY (Id))")
end

function UpdatePlayerDatabase(ply, weight)
        local newWeight = weight or ply:GetWeight()
		local innocent = ply:GetInnocentCount()
		local traitor = ply:GetTraitorCount()
		local detective = ply:GetDetectiveCount()
		local rounds = ply:GetRoundsPlayed()
		local tRounds = ply:GetRoundsSinceTraitorCount()
        if ply:IsPlayer() and not ply:IsBot() then
            ExecuteQuery("UPDATE " .. WeightSystem.TableName .. " SET Weight = " .. newWeight .. ", " ..
						 "InnocentRounds = " .. innocent .. ", " ..
						 "TraitorRounds = " .. traitor .. ", " ..
						 "DetectiveRounds = " .. detective .. ", " ..
						 "RoundsPlayed = " .. rounds .. ", " ..
						 "RoundsSinceTraitor = " .. tRounds .. ", " ..
						 "LastUpdated = '" .. DateTime() .. "' WHERE steamid = " .. ply:SteamID64())
        end
end

-- Connect database on Initialize
hook.Add("Initialize", "TTTKS_Initialize", function()
    CheckSQLiteTable()
end)

-- When player joins check if they have a record already, if not create one and set their default weight.
hook.Add("PlayerInitialSpawn", "TTTWS_PlayerInitialSpawn", function(ply)
    if ply:IsPlayer() and not ply:IsBot() then
        ExecuteQuery("SELECT * FROM " .. WeightSystem.TableName .. " WHERE SteamId = " .. ply:SteamID64(), function(data)
                if table.Count(data) > 0 then
                    Message(ply:GetName() .. " exists in database, setting player weight to: " .. data[1].Weight .. ", Round Data: " ..
							"(" .. data[1].InnocentRounds .. ", " .. data[1].TraitorRounds .. ", " .. data[1].DetectiveRounds .. ", " ..
							data[1].RoundsPlayed .. ", " .. data[1].RoundsSinceTraitor .. ")")
                    ply:SetWeight( data[1].Weight )
					ply:SetInnocentCount( data[1].InnocentRounds )
					ply:SetTraitorCount( data[1].TraitorRounds )
					ply:SetDetectiveCount( data[1].DetectiveRounds )
					ply:SetRoundsPlayed( data[1].RoundsPlayed )
					ply:SetRoundsSinceTraitorCount( data[1].RoundsSinceTraitor )					
                else
                    local defaultWeight = DefaultWeight()
                    Message(ply:GetName() .. " does not exist in database, creating user and setting default weight to: " .. defaultWeight)
                    ExecuteQuery("INSERT INTO " .. WeightSystem.TableName .. " ( SteamId, Weight, InnocentRounds, TraitorRounds, DetectiveRounds, RoundsPlayed, RoundsSinceTraitor, LastUpdated ) " ..
								 "VALUES ( '" .. ply:SteamID64() .. "', " .. defaultWeight .. ", 0, 0, 0, 0, 0, '" .. DateTime() .. "' )")
                    ply:SetWeight( defaultWeight )
					ply:SetInnocentCount( 0 )
					ply:SetTraitorCount( 0 )
					ply:SetDetectiveCount( 0 )
					ply:SetRoundsPlayed( 0 )
					ply:SetRoundsSinceTraitorCount( 0 )
                end
        end)
   end
   
end)
