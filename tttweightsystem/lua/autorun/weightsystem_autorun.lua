local version = "1.2.0"

WeightSystem = WeightSystem or {}
WeightSystem.VERSION = version
CreateConVar("ttt_traitor_chance_command", "!TC", FCVAR_ARCHIVE, "Command that allows users to see their traitor chance when typing in the command.")
WeightSystem.TraitorChanceCommand = GetConVarString("ttt_traitor_chance_command")
WeightSystem.StorageType = "json" --This can be 'mysql', 'sqlite', or 'json'
WeightSystem.TableName = "TTT_WeightSystem"

if SERVER then

	local function Message(msg)
		print("[TTT WeightSystem] ".. msg .. ".")
	end

	-- Create weightsystem folder in data
	if not file.IsDir("weightsystem", "DATA") then
		file.CreateDir("weightsystem")
	end

	if WeightSystem.StorageType == "mysql" then
		-- Create database.txt if it doesn't exist ( gives a template for the user )
		if not file.Exists( "weightsystem/database-template.txt", "DATA") then
			local CreateDBTemplate = { Host = "[HostName]", Port = 3306, User = "[Username]", Password = "[Password]", DatabaseName = "[DatabaseName]", TableName = WeightSystem.TableName }
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
	end
	
	-- Phantom139: Added code block for custom "json" storage type
	if WeightSystem.StorageType == "json" then
		if file.Exists( "weightsystem/table.json", "DATA") then
			local dbContent = file.Read("weightsystem/table.json", "DATA")
			local wTable = util.JSONToTable( dbContent )
			WeightSystem.table = wTable
		else
			WeightSystem.table = {}
			Message("Could not find table.json file, assuming empty" )
		end
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
			{ GroupName = "[GroupName]", MinWeight = 0, MaxWeight = 10, cappedWeight = -1 },
			{ GroupName = "[AnotherGroupName]", MinWeight = 5, MaxWeight = 10, cappedWeight = -1 }
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


if CLIENT then
	hook.Add("InitPostEntity", "TTTWS_updatecheck", function()
			http.Fetch("https://raw.githubusercontent.com/lzinga/TTTWeightedTraitorSelection/master/tttweightsystem/lua/autorun/weightsystem_autorun.lua", function(body)
				local str = string.match(body, "[^\n]+")
				local ver = str:sub(18, -3)
				local major, minor, patch = ver:match("(%d+)%.(%d+)%.(%d+)")
				major = tonumber(major) or 0
				minor = tonumber(minor) or 0
				patch = tonumber(patch) or 0
				local curmajor, curminor, curpatch = version:match("(%d+)%.(%d+)%.(%d+)")
				curmajor = tonumber(curmajor) or 0
				curminor = tonumber(curminor) or 0
				curpatch = tonumber(curpatch) or 0
				local msg
				if major > curmajor then
					msg = [[
	A new major version of TTT Weight System is
	available (%%%%%%%%).
	]]
				elseif minor > curminor then
					msg = [[
	A new minor version of TTT Weight System is
	available (%%%%%%%%).
	]]
				elseif patch > curpatch then
					msg = [[
	A new patch is available for
	TTT Weight System (%%%%%%%%).
	]]
				else
					msg = [[
	[TTT Weight System] is up to date (%%%%%%%%).
	]]
				end
				if msg then
					msg = string.gsub(msg, "%%+", ver)
					for w in string.gmatch(msg, "[^\n]+") do
						LocalPlayer():PrintMessage(HUD_PRINTTALK , w .. string.rep(" ", 32 - #w))
					end
				end
			end)
	end)
end
