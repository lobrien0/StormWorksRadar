--[[
Program Function: Radar for Stormworks
Author: Luke O'Brien
Version: Alpha 1.0

Channel inputs:
there are 32 channels that can be read from the game.
each channel can have a Boolean and a Number value.

Radar Inputs:
The radar can scan a maxium of 8 targets at a time.
The information is stored in the following format:
    Ch.1: Boolean - targets detected
    Ch.1: Number - distance to target
    Ch.2: Number - azmuth to target
    Ch.3: Number - elevation to target
    Ch.4: Number - Time since last scanned

This information is writen to the channels in block of 4. 
ex: 1-4, 5-8, 9-12, etc..
The following only allows for 7 targets to be scanned, this way we can
read in other information from the game, such as where the radars rotation is. 

Other Inputs:
Ch.32: Number - Rotation of the radar in degree (converted to Radians)
]]--

-- Stores each target as a table
targets = {}

-- used to update target information only when re-scanned
resetTgt = {false, false, false, false, false, false, false}

-- max range displayed (going to switch to input from game)
range = 1000

-- Counts the number of targets stored
function numberTargets()
    count = 0
    for x, y in ipairs(targets) do
        count = count + 1
    end
    return count
end

--[[ **ORIGIONAL FUNCTION**
--Rids targets that are just before the radar wand
function ridTargets(rotat)
    for x, y in pairs(targets) do
        negRotationA = (rotat + math.pi) % (2*math.pi)
        negRotationB = (rotat + math.pi/2) % (2*math.pi)
        if (negRotationA > y[2]) and (negRotationB < y[2]) and (not y[4]) then 
            y[4] = true
        elseif y[4] and y[5] and (rotat > y[2]) then
            targets[x] = nil
        end
        if y[4] and (rotat < y[2]) then
            y[5] = true
        end
    end
end
]]--

-- **TEST** I worry that small movements will cause a line of targets from 1 entity
function ridTargets(rotat)
    for x, y in pairs(targets) do 
        negTarget = ((y[2] - 0.2) + (2*math.pi)) % (2*math.pi)
        posTarget = (y[2] + 0.2) % (2*math.pi)
        if (rotat > negTarget) and (rotat < posTarget) and input.getbool(1) then
            targets[x] = nil
        end
    end
end

-- Scans all channels for targets
function getTargets(rotat)
    for i = 1,25,4 do
        temp = {}
        if input.getBool(i) and (not resetTgt[(i+3)/4]) then
            resetTgt[(i+3)/4] = true
            temp[1] = input.getNumber(i)
            temp[2] = (input.getNumber(i+1)*(2*math.pi)) % (2*math.pi)
            temp[3] = input.getNumber(i+2)
            temp[4] = false
            temp[5] = false
            table.insert(targets, temp)
        elseif not input.getBool(i) then
            resetTgt[(i+3)/4] = false
        end
    end
end

-- Every tick run in game, this function is called
function onTick()
    rotation = (input.getNumber(32) * (2*math.pi)) % (2*math.pi)
    refTargets(rotation)
    ridTargets(rotation)
end

-- Called when a change is to be displayed
function onDraw()
    width = screen.getWidth()
    height = screen.getHeight()

    -- Calculates center point on screen
    pad = width - height
    xpoint = (width/2) + (pad/2)
    ypoint = height/2
    cpoint = math.min(width,height)/2

    -- math shortcuts
    quart = math.pi/2

    -- Draws the radar circle (and the center point)
    screen.setColor(0, 255, 0)
    screen.drawCircle(xpoint, ypoint, (math.min(width,height)/2))
    screen.setColor(255, 255, 255)
    screen.drawCircle(xpoint, ypoint, 1)

    -- Draws the radar sweep wand (double check math)
    screen.setColor(0, 255, 0)
    screen.drawLine(xpoint, ypoint, xpoint + (math.cos(rotation-quart) * cpoint), ypoint + (math.sin(rotation-quart) * cpoint))

    -- Draws the targets
    screen.setColor(255, 0, 0)
    for x, y in ipairs(targets) do 
        distance = y[1]
        azmuth = y[2]
        screen.drawCircleF(xpoint + (math.cos(azmuth-quart) * (distance/range) * cpoint), ypoint + (math.sin(azmuth-quart) * (distance/range) * cpoint), 2)
    end

    -- Draws Target distance on left side if pad
	screen.setColor(255,255,255)
    if pad > 0 then
        for x, y in ipairs(targets) do
            yDraw = (x*20)-20
            screen.drawText(0, yDraw, "TGT[" .. x .. "]:")
            screen.drawText(0, yDraw+10, math.floor(y[1]))
        end
		--screen.drawText(0,0, "Tgts:")
		--screen.drawText(0,10, numberTargets())
    end

end