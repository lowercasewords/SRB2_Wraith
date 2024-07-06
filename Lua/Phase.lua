
freeslot("S_PHASE")


local LEVITATION_MOMZ = -2*FRACUNIT
--[[
local function A_OnLevitation(playmo)
	playmo.can_levitate = false
	playmo.acceleration = skins[playmo.skin].acceleration*10
end
]]--

--Levitation is used continuously while holding jump button in the air
states[S_PHASE] = {
	sprite = SPR_PLAY,
	frame = SPR2_RUN_|FF_TRANS50,
	-- action = A_OnLevitation,
	tics = -1,
	nextstate = S_PLAY_FALL
}


--[[
// Levitation on timer with a deadly fog around you,
// damaging with the fog increases levitation timer
]]--


addHook("PreThinkFrame", 
	function()
		for player in players.iterate() do
			if(player.mo.skin == "wraith") then


				--Record holding spin
				if(player.cmd.buttons & BT_SPIN) then
					player.spinheld = $+1
				else
					player.spinheld = 0
				end

				--Record holding jump
				if(player.cmd.buttons & BT_JUMP) then
					player.jumpheld = $+1
				else
					player.jumpheld = 0
				end




				--[[
				if(player.mo.state ~= S_PHASE) then --If not in phase state yet...
					
					--Phasing..
					if(player.spinheld >= 1) then 
						player.mo.state = S_PHASE
					end
					-- print("switching...")
				end
				]]--
			end
		end
	end
)

addHook("PostThinkFrame", 
	function()
		for player in players.iterate() do
			if(player.mo.skin == "wraith") then

				--If not in phase state yet...
				if(player.mo.state ~= S_PHASE) then 
					
					--Phasing...
					if(player.spinheld >= 1 and player.mo.state ~= player.mo.info.painstate and player.mo.state ~= player.mo.info.deathstate) then 
						player.mo.state = S_PHASE
					end
					
				end
			end
			if(player.mo.state == S_PHASE) then  

				--Levitation
				if(not P_IsObjectOnGround(player.mo)) then
					player.mo.momz = LEVITATION_MOMZ
				end

				--Getting out of the phase state prematurely if let go of the spin button
				if(player.spinheld == 0) then
					player.mo.state = states[player.mo.state].nextstate
				end
			end
		end 
	end)

--Levitation script
addHook("PlayerThink", 
	function(player)
		if(player.valid == true and player.mo.valid == true) then
			
			

			--[[
			if(player.mo.state ~= S_LEVITATION) then
				--Levitation is allowed on the next jump press in the air
				if(player.spinheld == 0 and player.lastbuttons & BT_JUMP and not P_IsObjectOnGround(player.mo)) then
					print("prepare")
					player.can_levitate = true
					
				--Levitation is canceled before it could've been used 
				elseif(player.mo.eflags & MFE_JUSTHITFLOOR) then
					print("stop1")
					player.can_levitate = false	
				

				--Levitation is triggered by going into the state
				elseif(player.can_levitate == true and player.spinheld >= 1) then
					print("start")
					player.can_levitate = false
					-- player.mo.acceleration = skins[player.mo.skin].acceleration*10
					player.mo.state = S_LEVITATION
				end
			else
				--Levitation is stopped when touched the ground or letting go of jump 
				if(player.spinheld == 0) then
					print("stop2")
					player.mo.state = states[player.mo.state].nextstate
					-- player.acceleration = skins[player.mo.skin].acceleration			

				--Continuous behavior of the Levitation State
				else
					print("levitating")
					player.mo.momz = LEVITATION_MOMZ
				end
			end
			]]--
		end
	end
)