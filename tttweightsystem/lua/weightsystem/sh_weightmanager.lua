include("sh_playerweight.lua")

function DefaultWeight()
	local playerCount = 0
	for k,ply in pairs(player.GetAll()) do
		if IsValid(ply) and (not ply:IsBot()) then
			playerCount += 1
		end
	end

    return math.random(1, 10) * math.random(1, playerCount / 2)
end

function UpdatePlayerDbWeights()
    for k,ply in pairs(player.GetAll()) do
		UpdatePlayerDatabase(ply, ply:GetWeight())
    end
	
	SaveTable()
end

function GetActivePlayersTotalWeight()
    local totalWeight = 0

    for k,ply in pairs(player.GetAll()) do
        if IsValid(ply) and (ply:GetWeight() ~= nil) and (not ply:IsBot()) then
          totalWeight = totalWeight + ply:GetWeight()
        end
    end
	
    return totalWeight
end

function GetPlayerTraitorChance( ply )
	if IsValid(ply) then
		return math.floor( (ply:GetWeight() / GetActivePlayersTotalWeight()) * 100 )
	end
end

-- Tells player their chance to become traitor.
function TellPlayersTraitorChance(ply)
	  if GetConVar("ttt_ws_show_round_statistics"):GetBool() then
		ply:PrintMessage( HUD_PRINTTALK, "Round Statistics: You have played " .. ply:GetRoundsPlayed() .. " round(s). Assigned Roles: Innocent: " .. 
										  ply:GetInnocentCount() .. ", Traitor: " .. ply:GetTraitorCount() .. ", Detective: " .. ply:GetDetectiveCount() .. 
										  ". It has been " .. ply:GetRoundsSinceTraitorCount() .. " round(s) since you have been a Traitor.")
	  end
      if GetConVar("ttt_show_traitor_chance"):GetBool() then
		ply:PrintMessage( HUD_PRINTTALK, "Your chance to become traitor next round is: " .. GetPlayerTraitorChance( ply ) .. "%" )
      end
end