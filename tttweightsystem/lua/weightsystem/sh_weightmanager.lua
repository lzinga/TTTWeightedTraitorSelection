include("sh_playerweight.lua")

function DefaultWeight()
    return math.random(1, 5)
end

function UpdatePlayerDbWeights()
    for k,ply in pairs(player.GetAll()) do
            UpdatePlayerWeight(ply, ply:GetWeight())
    end
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
      if GetConVar("ttt_show_traitor_chance"):GetBool() then
		ply:PrintMessage( HUD_PRINTTALK, "Your chance to become traitor next round is: " .. GetPlayerTraitorChance( ply ) .. "%" )
      end
end