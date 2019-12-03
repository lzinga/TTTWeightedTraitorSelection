if not SERVER then return end

local function Message(msg)
    print("[TTT WeightSystem] ".. msg .. ".")
end

local storage = WeightSystem.StorageType
if storage == "sqlite" then
	Message("Loading with SQLite")
	include("sv_database_sqlite.lua")
elseif storage == "mysql" then
	Message("Loading with MySQL")
	include("sv_database_mysql.lua")
elseif storage == "json" then
	Message("Loading with JSON Tables")
	include("sv_database_json.lua")
else
	Message("Unknown storage type " .. storage)
end