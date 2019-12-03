if not SERVER then return end

require("mysqloo")
include("sh_weightmanager.lua")
include("sh_playerweight.lua")

local function Message(msg)
    print("[TTT WeightSystem MySQL] ".. msg .. ".")
end

function DateTime()
    return os.date( "%y-%m-%d %H:%M:%S" )
end

local db = mysqloo.connect(WeightSystem.Database.Host, WeightSystem.Database.User, WeightSystem.Database.Password, WeightSystem.Database.DatabaseName, WeightSystem.Database.Port)
local queue = {}

function SaveTable()
	Message("SaveTable() Call ignored, only used in JSON")
end

function DatabaseExists()
	ExecuteQuery("SELECT count(*) FROM information_schema.tables WHERE table_name = '" .. WeightSystem.Database.TableName .. "'", function(data)
                if table.Count(data) <= 0 then
                    Message(WeightSystem.Database.TableName .. " table does NOT exist")
					return false
                else
					Message(WeightSystem.Database.TableName .. " exists")
					return true
                end
        end)
		
		return false -- if it could not run most likely failed.
end

function ExecuteQuery(str, callback)
				
        callback = callback or function() end
        local q = db:query(str)
        function q:onSuccess(data)
                callback(data)
        end
 
        function q:onError(err)
                local status = db:status()
                if status == mysqloo.DATABASE_NOT_CONNECTED or status == mysqloo.DATABASE_CONNECTING then
                        Message("Inserting missed query into queue: " .. str)
                        table.insert( queue, { str, callback } )

                        if status == mysqloo.DATABASE_NOT_CONNECTED then
                                Message("Attempting reconnect to database!")
                                db:connect()
                        end
                        return
                end
        end
        q:start()
end

function db:onConnected()
    Message("Connected to database")
	DatabaseExists()
	
	ExecuteQuery("CREATE TABLE IF NOT EXISTS " .. WeightSystem.Database.TableName .. " (Id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, SteamId BIGINT UNSIGNED NOT NULL, " ..
				 "Weight SMALLINT UNSIGNED NOT NULL, " ..
				 "InnocentRounds SMALLINT UNSIGNED NOT NULL, " ..
				 "TraitorRounds SMALLINT UNSIGNED NOT NULL, " ..
				 "DetectiveRounds SMALLINT UNSIGNED NOT NULL, " ..
				 "RoundsPlayed SMALLINT UNSIGNED NOT NULL, " ..
				 "RoundsSinceTraitor SMALLINT UNSIGNED NOT NULL, " ..
				 "LastUpdated DATETIME DEFAULT '" .. DateTime() .. "', PRIMARY KEY (Id))")

    Message("Running commands that were lost")
    for k, v in pairs( queue ) do
        ExecuteQuery( v[ 1 ], v[ 2 ] )
    end
    queue = {}
    -- Delete records older then 3 weeks, just clean out the database a little bit.
    ExecuteQuery("DELETE FROM " .. WeightSystem.Database.TableName .. " WHERE DATEDIFF(CURDATE(), LastUpdated) >= 21")
end
 
function db:onConnectionFailed(err)

	for k,v in pairs(player.GetAll()) do
	v:PrintMessage( HUD_PRINTTALK, "[Weight System] Could not connect to database, please ensure the settings are filled out properly.")
	end

    Message("Connection to database failed")
end

function ResetTable()
	Message("Resetting weight table")
	
	ExecuteQuery("DROP TABLE IF EXISTS " .. WeightSystem.Database.TableName)
	
	db:connect()
end

function UpdatePlayerDatabase(ply, weight)
        local newWeight = weight or ply:GetWeight()
		local innocent = ply:GetInnocentCount()
		local traitor = ply:GetTraitorCount()
		local detective = ply:GetDetectiveCount()
		local rounds = ply:GetRoundsPlayed()
		local tRounds = ply:GetRoundsSinceTraitorCount()		
        if ply:IsPlayer() and not ply:IsBot() then
            ExecuteQuery("UPDATE " .. WeightSystem.Database.TableName .. " SET Weight = " .. newWeight .. ", " ..
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
    db:connect()
end)

-- When player joins check if they have a record already, if not create one and set their default weight.
hook.Add("PlayerInitialSpawn", "TTTWS_PlayerInitialSpawn", function(ply)
    if ply:IsPlayer() and not ply:IsBot() then
        ExecuteQuery("SELECT * FROM " .. WeightSystem.Database.TableName .. " WHERE SteamId = " .. ply:SteamID64(), function(data)
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
                    ExecuteQuery("INSERT INTO " .. WeightSystem.Database.TableName .. " ( SteamId, Weight, InnocentRounds, TraitorRounds, DetectiveRounds, RoundsPlayed, RoundsSinceTraitor, LastUpdated ) " ..
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
