
--------------- Hud function implementations ---------------

local function drawphasebars(v, stplayer, cam)
    
    if(stplayer.isvalid == false and stplayer.mo.skin ~= "wraith") then
        
    end
    local emptybar = v.cachePatch("BAR_EMPTY")
    local fullbar = v.cachePatch("BAR_FULL")

    local xbarsize, ybarsize = 32*FRACUNIT, 32*FRACUNIT

    local x, y = 210*FRACUNIT, 170*FRACUNIT

    local xscale, yscale = 2*FRACUNIT, 2*FRACUNIT

    --Drawing static empty bar 
    v.drawStretched(x, y, xscale, yscale, emptybar)
    --Drawing dynamic full bar 
    v.drawCropped(x, y, xscale, yscale, fullbar, 0, nil, 0, 0, FixedMul(FixedDiv(stplayer.mo.phasejuice, stplayer.mo.max_phasejuice), xbarsize), ybarsize)
end


--------------- Hud function definitions ---------------


hud.add(drawphasebars, "game")
