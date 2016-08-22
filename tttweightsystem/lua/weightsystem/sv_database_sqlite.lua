if not SERVER then return end

include("sh_weightmanager.lua")
include("sh_playerweight.lua")

local function Message(msg)
    print("[TTT WeightSystem SQLite] ".. msg .. ".")
end

function DateTime()
    return os.date( "%y-%m-%d %H:%M:%S" )
end

function ExecuteQuery(str, callback)
	callback = callback or function() end

	local result = sql.Query(str)

	if result then
		callback(result)
	end
end

function CheckSQLiteTable()
    Message("Connected to database")
	
	ExecuteQuery("CREATE TABLE IF NOT EXISTS " .. WeightSystem.TableName .. " (Id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, SteamId BIGINT UNSIGNED NOT NULL, Weight SMALLINT UNSIGNED NOT NULL, LastUpdated DATETIME DEFAULT '" .. DateTime() .. "', PRIMARY KEY (Id))")
end

function UpdatePlayerWeight(ply, weight)
        local newWeight = weight or ply:GetWeight()
        if ply:IsPlayer() and not ply:IsBot() then
            ExecuteQuery("UPDATE " .. WeightSystem.TableName .. " SET Weight = " .. newWeight .. ", LastUpdated = '" .. DateTime() .. "' WHERE steamid = " .. ply:SteamID64())
        end
end

-- Connect database on Initialize
hook.Add("Initialize", "TTTKS_Initialize", function()
    CheckSQLiteTable()
end)

-- When player joins check if they have a record already, if not create one and set their default weight.
hook.Add("PlayerInitialSpawn", "TTTWS_PlayerInitialSpawn", function(ply)
    if ply:IsPlayer() and not ply:IsBot() then
        ExecuteQuery("SELECT Weight FROM " .. WeightSystem.TableName .. " WHERE SteamId = " .. ply:SteamID64(), function(data)
                if table.Count(data) > 0 then
                    Message(ply:GetName() .. " exists in database, setting player weight to: " .. data[1].Weight)
                    ply:SetWeight( data[1].Weight )
                else
                    local defaultWeight = DefaultWeight()
                    Message(ply:GetName() .. " does not exist in database, creating user and setting default weight to: " .. defaultWeight)
                    ExecuteQuery("INSERT INTO " .. WeightSystem.TableName .. " ( SteamId, Weight, LastUpdated ) VALUES ( '" .. ply:SteamID64() .. "', " .. defaultWeight .. ", '" .. DateTime() .. "' )")
                    ply:SetWeight( defaultWeight )
                end
        end)
   end
   
end)