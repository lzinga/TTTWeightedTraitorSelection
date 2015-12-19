CreateConVar("ttt_traitor_chance_command", "!TC", FCVAR_ARCHIVE, "Command that allows users to see their traitor chance when typing in the command.")

WeightSystem = WeightSystem or {}
WeightSystem.VERSION = "1.0.8"
WeightSystem.TraitorChanceCommand = GetConVarString("ttt_traitor_chance_command")


if SERVER then

	local function Message(msg)
		print("[TTT WeightSystem] ".. msg .. ".")
	end

	-- Create weightsystem folder in data
	if not file.IsDir("weightsystem", "DATA") then
		file.CreateDir("weightsystem")
	end

	-- Create database.txt if it doesn't exist ( gives a template for the user )
	if not file.Exists( "weightsystem/database-template.txt", "DATA") then
		local CreateDBTemplate = { Host = "[HostName]", Port = 3306, User = "[Username]", Password = "[Password]", DatabaseName = "[DatabaseName]", TableName = "TTT_WeightSystem" }
		local dbJson = util.TableToJSON( CreateDBTemplate ) -- Convert the player table to JSON
		file.Write( "weightsystem/database-template.txt", dbJson )
	end
	if file.Exists( "weightsystem/database.txt", "DATA") then
		local dbContent = file.Read("weightsystem/database.txt", "DATA")
		local Database = util.JSONToTable( dbContent )
		WeightSystem.Database = Database
	else
		Message("Could not find database.txt file" )
	end
	

		-- Make it so file exists no matter what.
	if not file.Exists( "weightsystem/groupperms.txt", "DATA") then
		local createGroupPerms = { "superadmin", "admin" }
		local groupPermsJson = util.TableToJSON( createGroupPerms ) -- Convert the table to JSON
		file.Write( "weightsystem/groupperms.txt", groupPermsJson )
		Message ( "Group Permissions file did not exist, creating it with default settings" )
	end
	if file.Exists( "weightsystem/groupperms.txt", "DATA") then
		local groupContent = file.Read("weightsystem/groupperms.txt", "DATA")
		local group = util.JSONToTable( groupContent )
		WeightSystem.GroupPermissions = group
		Message ( "Group Permissions Found" )
	end
	
	
	-- Create group weight
	if not file.Exists( "weightsystem/groupweight-template.txt", "DATA") then
		local customGroupWeightsTemplate = {
			{ GroupName = "[GroupName]", MinWeight = 0, MaxWeight = 10 },
			{ GroupName = "[AnotherGroupName]", MinWeight = 5, MaxWeight = 10 }
		}
		local gwJson = util.TableToJSON( customGroupWeightsTemplate )
		file.Write( "weightsystem/groupweight-template.txt", gwJson)
	end
	if file.Exists( "weightsystem/groupweight.txt", "DATA") then
		-- Load json from database.txt and place it into table.
		local groupWeightContent = file.Read("weightsystem/groupweight.txt", "DATA")
		local groupweightValues = util.JSONToTable( groupWeightContent )
		WeightSystem.GroupWeight = groupweightValues
		Message( "Loaded Extra Group Weight Settings")
	end
	
	AddCSLuaFile()
	Message("Version " .. WeightSystem.VERSION .. " is loading." )
	include("weightsystem/sv_init.lua")
else
	include("weightsystem/cl_init.lua")
end