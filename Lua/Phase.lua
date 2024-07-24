-- 
-- 		Creates two circles which are kept around the player during the phase state
--
-- 	The first circle is small created by the lantern, it damages any enemy or monitor on contact
-- 
-- 	The second circle is larger and created by darkness. If enemy or monitor gets into this area, a tenticle would spawn at 
-- player's location that would grab an snatch the enemy towards the player.

freeslot("S_PHASE")



local PHASE_GRAB_FLAGS = MF_ENEMY
local PHASE_DAMAGE_FLAGS = MF_BOSS|MF_MONITOR

local LEVITATION_MOMZ = 2*FRACUNIT
local PHASE_ACCELERATION = 10*FRACUNIT

local DARKNESS_DISTANCE_MAX = 300*FRACUNIT
local DARKNESS_DISTANCE_MIN = 75*FRACUNIT
local LIGHT_DISTANCE_MAX = DARKNESS_DISTANCE_MIN

--[[
local function A_OnLevitation(playmo)
	playmo.can_levitate = false
	playmo.acceleration = skins[playmo.skin].acceleration*10
end
]]--

--Levitation is used continuously while holding jump button in the air
states[S_PHASE] = {
	sprite = SPR_PLAY,
	frame = SPR2_RUN_|FF_FULLBRIGHT|FF_ADD|FF_ANIMATE,
	-- action = A_OnLevitation,
	tics = 9999,
	nextstate = S_PLAY_FALL
}



--[[
// Levitation on timer with a deadly fog around you,
// damaging with the fog increases levitation timer
]]--


--[[
--Tries to find a target in the fixed_t radius around the player
local function FindTarget(player, min_distance, max_distance) 
	if(player.valid == true and player.mo.valid == true) then
	
		local enemy = nil

		searchBlockmap("objects", function(playmo, foundmo)
			
			local found_distance = R_PointToDist2(playmo.x, playmo.y, foundmo.x, foundmo.y)

			if(min_distance <= found_distance and found_distance <= max_distance) then
				enemy = foundmo
				return false 
			end
		
		end, player.mo, player.mo.x+max_distance*5000, player.mo.x-max_distance*5000, player.mo.y+max_distance*5000, player.mo.y-max_distance*5000)
		
		return enemy
	end
end
]]--


--Tries to find and mark yet umarked targed in the fixed_t radius around the player
local function darkmarkowner(player, min_distance, max_distance) 
	if(player.valid == true and player.mo.valid == true) then

		searchBlockmap("objects", function(playmo, foundmo)
			
			local found_distance = R_PointToDist2(playmo.x, playmo.y, foundmo.x, foundmo.y)

			if(min_distance <= found_distance and found_distance <= max_distance
			and foundmo.darkmarkowner == nil
			and foundmo.flags & PHASE_GRAB_FLAGS) then

				foundmo.darkmarkowner = player.mo

				return true 
			end
		
		end, player.mo, player.mo.x+max_distance*5000, player.mo.x-max_distance*5000, player.mo.y+max_distance*5000, player.mo.y-max_distance*5000)
	end
end


addHook("MobjThinker", 
	function(mo)

		--Behavior for the marked enemy
		if(mo.valid == true and mo.darkmarkowner ~= nil) then
			--Canceling the mark for certain conditions
			if(R_PointToDist2(mo.x, mo.y, mo.darkmarkowner.x, mo.darkmarkowner.y) > DARKNESS_DISTANCE_MAX or 
			mo.darkmarkowner.state ~= S_PHASE) then
				mo.darkmarkowner = nil
			else 
			--performing mark's behavior
				P_InstaThrust(mo, R_PointToAngle2(mo.x, mo.y, mo.darkmarkowner.x, mo.darkmarkowner.y), mo.darkmarkowner.player.speed/2 + 20*FRACUNIT)
			end
		end
	end)


addHook("PlayerSpawn", 
	function(player)
		player.mo.prevstate = player.mo.state
	end)

addHook("PlayerThink", 
	function(player)
		if(player.valid == true and player.mo.valid == true) then

			
					--Current order in a single tic
				--Going into phase
				--Changing from phase state to any other
				--While in the phase
				--Detecting when just entered the phase (doesn't work if state tics is -1)
				--Getting out of the phase state prematurely if let go of the spin button

					--Better order
				--Getting out of the phase state prematurely if let go of the spin button
				--Changing from phase state to any other
				--Going into phase
				--Detecting when just entered the phase (doesn't work if state tics is -1)
				--While in the phase


				-- print("	   before prev:"..player.mo.prevstate)
				-- print("	   before state:"..player.mo.state)	


				--Getting out of the phase state prematurely if let go of the spin button
				if(player.mo.state == S_PHASE and player.spinheld == 0) then
					player.mo.state = states[player.mo.state].nextstate
				end

				--Changing from phase state to any other
				if(player.mo.prevstate == S_PHASE and player.mo.prevstate ~= player.mo.state) then
					
					-- print("stop levitation")
					player.acceleration = skins[player.mo.skin].acceleration
					
					--[[
					player.mo.color = skins[player.mo.skin].prefcolor
					player.mo.renderflags = $ &~RF_FULLBRIGHT &~RF_NOCOLORMAPS
					player.mo.blendmode = AST_COPY
					]]--
				end

				--Going into phase
				if(player.mo.state ~= S_PHASE and player.spinheld >= 1 and player.mo.state ~= player.mo.info.painstate and player.mo.state ~= player.mo.info.deathstate) then 
					-- print("to phase from "..player.mo.state)
					player.mo.state = S_PHASE
				end

				--Detecting when just entered the phase (doesn't work if state tics is -1)
				if(player.mo.state == S_PHASE and states[player.mo.state].tics == player.mo.tics) then
					-- print("on changed")
					player.acceleration = $*3--PHASE_ACCELERATION
				end


				--While in the phase
				if(player.mo.state == S_PHASE) then
					
					--Upper momentum
					if(player.mo.momz <= 5*FRACUNIT and player.jumpheld >= 1) then
						-- player.mo.momz = $+FRACUNIT
						P_SetObjectMomZ(player.mo, 2*LEVITATION_MOMZ, false)
					-- elseif(player.mo.z - player.mo.floorz == 30*FRACUNIT) then
					-- 	P_SetObjectMomZ(player.mo, 0, false)

					--Checking how high the player is relative to the floor below
					elseif(player.mo.z - player.mo.floorz < 30*FRACUNIT) then
						-- print("move up!")
						
						-- if(player.mo.floorrove ~= nil and player.mo.floorrover.b_slope ~= nil) then
						-- 	print(player.mo.floorrover.b_slope.zdelta)
						-- end

						P_SetObjectMomZ(player.mo, FRACUNIT, true)

					--Downwards momentum
					elseif(not P_IsObjectOnGround(player.mo)) then--if(player.mo.momz < 0) then
						P_SetObjectMomZ(player.mo, -LEVITATION_MOMZ, false)
					end
					
					--Marking the enemy
					darkmarkowner(player, DARKNESS_DISTANCE_MIN, DARKNESS_DISTANCE_MAX)
					
					--[[
					--Try to find an enemy
					local enemy = FindTarget(player, DARKNESS_DISTANCE_MIN, DARKNESS_DISTANCE_MAX)

					--If an enemy is found, grab it
					if(enemy ~= nil and enemy.flags & PHASE_GRAB_FLAGS) then
						P_InstaThrust(enemy, R_PointToAngle2(enemy.x, enemy.y, player.mo.x, player.mo.y), player.speed/2 + 20*FRACUNIT)
					end

					--Tries to find an enemy
					enemy = FindTarget(player, 0, LIGHT_DISTANCE_MAX)
					--If an enemy is found, damage it
					if(enemy ~= nil and enemy.flags & PHASE_DAMAGE_FLAGS) then
						P_DamageMobj(enemy, player.mo, player.mo)
					end
					]]--

				end


				-- print("		after prev:"..player.mo.prevstate)
				-- print("		after state:"..player.mo.state)			
				
				player.mo.prevstate = player.mo.state 
		end
	end)

addHook("MobjCollide", 
	function(playmo, enemy) 
		--Damaging the marked (grabed) enemies or mic objects while in phase
		print("collided")
		if(enemy.valid == true and (enemy.darkmarkowner == playmo
		or (enemy.flags & PHASE_DAMAGE_FLAGS ~= 0 and enemy.health > 0))) then
			print("hit!")
			P_DamageMobj(enemy, playmo, playmo, 1)
		end
	end, 
	MT_PLAYER)


addHook("MobjDamage", 
	function(playmo, enemy_inflictor, enemy_source, damage, damagetype) 
		--Player won't get damaged by marked (grabed) enemies while in phase
		if(enemy_inflictor.valid == true and playmo.state == S_PHASE and 
		(enemy_inflictor.darkmarkowner == playmo or enemy_source.flags|MF_BOSS == enemy_source.flags)) then
			-- print("don't hit	")
			return true
		end
	end, 
	MT_PLAYER)

addHook("MobjMoveBlocked", function(mobj, thing, line)
end)


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


				

			end
		end
	end
)


--[[
addHook("PlayerThink", 
	function(player) 
		if(player.valid == true and player.mo.skin == "wraith") then
			FindTarget(player, DARKNESS_RADIUS)
		end
	end)
]]--


addHook("PostThinkFrame", 
	function()
		for player in players.iterate() do
			if(player.mo.skin == "wraith") then
				
			end	
		end 
	end)



--[[
--Levitation script
addHook("PlayerThink", 
	function(player)
		if(player.valid == true and player.mo.valid == true) then
			
			
			
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
		end
	end
)
]]--