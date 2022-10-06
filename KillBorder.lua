KillBorder = {
	coalition = 0,
	side = 1,
	groupIdentifier = "",
	border = {a, c},
	flexiborder = {},
	loopID,
	checkTime,
	warnDistance,
	groupArray = {},
	punishType = 0,
	punishTimer,
	sound
}

function KillBorder:generate(ReferenceGroup, Coalition, Side, GroupIdentifier, Time, WarnDistance, PunishType, PunishTimer, Sound)
	-- trigger.action.outText("running", 10, false)
	self.coalition = Coalition
	self.side = Side
	self.groupIdentifier = GroupIdentifier
	self.checkTime = Time
	self.warnDistance = WarnDistance
	self.punishType = PunishType
	self.punishTimer = PunishTimer
	self.sound = "l10n/DEFAULT/" .. Sound
	
	local units = Group.getByName(ReferenceGroup):getUnits()
	local count = 0
	for key, value in pairs(units) do
		table.insert(self.flexiborder, value:getPoint())
		-- self.flexiborder.insert(value:getPoint())
		count = count + 1
	end
	local V = getV2(self.flexiborder[2], self.flexiborder[1])
	table.insert(self.flexiborder, 1, {x = V.x * 1000000 + self.flexiborder[2].x, z = V.z * 1000000 + self.flexiborder[2].z})
	count = count + 1

	V = getV2(self.flexiborder[count - 1], self.flexiborder[count])
	table.insert(self.flexiborder, {x = V.x * 1000000 + self.flexiborder[count - 1].x, z = V.z * 1000000 + self.flexiborder[count - 1].z})
	count = count + 1

	local i = 1
	while i < count do
		trigger.action.lineToAll(-1, i + 1000, self.flexiborder[i], self.flexiborder[i + 1], {1, 0, 0, 1}, 1, true)
		i = i + 1
	end
	trigger.action.textToAll(-1, 1000, {x = self.flexiborder[2].x - 6000, y = 0, z = self.flexiborder[2].z + 6000}, {1, 0, 0, 1}, {1, 0, 0, 0}, 20, true, 'PVP Border')
end

function KillBorder.playerLoop(args)
	if args.playerObject:isExist() then
		if args.self.groupArray[args.playerObject:getID()] == nil then
			args.self.groupArray[args.playerObject:getID()] = 0
		end
		local distance = args.self:getDistance(args.playerObject)
		if distance < 0 then
			trigger.action.outTextForUnit(args.playerObject:getID(), args.playerObject:getPlayerName() .. ' you are beyond the border of the allowed area, you will be punished!', args.self.checkTime - 2, false)
			if args.self.punishType == 0 then
				if args.self.groupArray[args.playerObject:getID()] >= args.self.punishTimer then
					args.self.groupArray[args.playerObject:getID()] = 0
					trigger.action.explosion(args.playerObject:getPoint(), 1)
				else
					args.self.groupArray[args.playerObject:getID()] = args.self.groupArray[args.playerObject:getID()] + args.self.checkTime 
				end
			elseif args.self.punishType == 1 then
				if args.self.groupArray[args.playerObject:getID()] == 0 then
					args.self.groupArray[args.playerObject:getID()] = 1
					trigger.action.explosion(args.playerObject:getPoint(), 10)
				end
			else
				--to be implemented
			end
		elseif math.abs(distance) < args.self.warnDistance then
			trigger.action.outTextForUnit(args.playerObject:getID(), args.playerObject:getPlayerName() .. ' you are ' .. math.floor(distance) .. 'm away from the border of the allowed area, passing the border will be punished!', args.self.checkTime - 2, false)
			trigger.action.outSoundForUnit(args.playerObject:getID(), args.self.sound)
		else
			args.self.groupArray[args.playerObject:getID()] = 0
		end
		args.self.loopID = timer.scheduleFunction(args.self.playerLoop, args, timer.getTime() + args.self.checkTime)
	end
end

function KillBorder.playerWarnLoop(args)
	if args.playerObject:isExist() then
		if args.self.groupArray[args.playerObject:getID()] == nil then
			args.self.groupArray[args.playerObject:getID()] = 1
		end
		local distance = args.self:getDistance(args.playerObject)
		if distance > 0 and args.self.groupArray[args.playerObject:getID()] > -1 then
			trigger.action.outTextForUnit(args.playerObject:getID(), args.playerObject:getPlayerName() .. ', you entered the PVP area!', 10, false)
			trigger.action.outSoundForUnit(args.playerObject:getID(), args.self.sound)
			args.self.groupArray[args.playerObject:getID()] = -1
		elseif distance < 0 and args.self.groupArray[args.playerObject:getID()] < 1 then
			trigger.action.outTextForUnit(args.playerObject:getID(), args.playerObject:getPlayerName() .. ', you left the PVP area!', 10, false)
			trigger.action.outSoundForUnit(args.playerObject:getID(), args.self.sound)
			args.self.groupArray[args.playerObject:getID()] = 1
		end
		args.self.loopID = timer.scheduleFunction(args.self.playerWarnLoop, args, timer.getTime() + args.self.checkTime)
	end
end
--[[
function KillBorder:getDistance(object)
	return (self.border.a * object:getPoint().z - object:getPoint().x + self.border.c) / math.sqrt((self.border.a)^2 + 1) * self.side
end
--]]
function getMinDistance(A, B, P)
    local AB = getV2(A, B)
    
    local BP = getV2(B, P)

   	local AP = getV2(A, P)

    local AB_BP = AB.x * BP.x + AB.z * BP.z
    local AB_AP = AB.x * AP.x + AB.z * AP.z
 
    if AB_BP > 0 then
        return v2Magnitude(BP)
    elseif AB_AP < 0 then
		return v2Magnitude(AP)
    else
		return math.abs(AB.x * AP.z - AB.z * AP.x) / v2Magnitude(AB)
	end
end

function KillBorder:getDistance(object)
	local min = v2Magnitude(getV2(object:getPoint(), self.flexiborder[2]))
	local P = 2
	for key, value in pairs(self.flexiborder) do
		local grid = coord.LLtoMGRS(coord.LOtoLL({x = value.x, y = 0, z = value.z}))
		-- trigger.action.outTextForUnit(object:getID(), 'point ' .. key .. ', dist ' .. v2Magnitude(getV2(object:getPoint(), value)) .. ', exact point ' .. grid.UTMZone .. ' ' .. grid.MGRSDigraph .. ' ' .. grid.Easting .. ' ' .. grid.Northing, 10, false)
		if v2Magnitude(getV2(object:getPoint(), value)) < min then
			min = v2Magnitude(getV2(object:getPoint(), value))
			P = key
		end
	end
	local A = P - 1
	local B = P + 1
	local PA = getV2(self.flexiborder[P], self.flexiborder[A])
	local PB = getV2(self.flexiborder[P], self.flexiborder[B])
	local PC = getV2(self.flexiborder[P], object:getPoint())
	local dist = math.min(getMinDistance(self.flexiborder[P], self.flexiborder[A], object:getPoint()), getMinDistance(self.flexiborder[P], self.flexiborder[B], object:getPoint()))

	local PCrelPA = getV2Relation(PC, PA)
	local PCrelPB = getV2Relation(PC, PB)

	if (PCrelPA < 0 and PCrelPB > 0) then
		-- trigger.action.outTextForUnit(object:getID(), 'case 1, point ' .. P .. ', dist ' .. min, 10, false)
		return dist * -1
	elseif ((getV2Relation(PA, PB) < 0) and ((PCrelPA > 0 and PCrelPB > 0) or (PCrelPA < 0 and PCrelPB < 0))) then
		-- trigger.action.outTextForUnit(object:getID(), 'case 2, point ' .. P .. ', dist ' .. min, 10, false)
		return dist * -1
	end
	return dist
end

function getV2(A, B)
	return {x = B.x - A.x, z = B.z - A.z}
end

function v2Magnitude(V)
	return math.sqrt(V.x^2 + V.z^2)
end

function getV2Relation(V1, V2)
	--dot = a.x*-b.y + a.y*b.x
	return V1.x * (-1 * V2.z) + V1.z * V2.x
end

function KillBorder:checkValidity(event)
	if event.initiator ~= nil then
		if (event.initiator:getCoalition() == self.coalition or self.coalition == 0) and string.find(event.initiator:getGroup():getName(), self.groupIdentifier) ~= nil then
			return true
		else
			return false
		end
	end
end

function KillBorder.weaponLoop(args)
	--trigger.action.outText("weapon", 10, false)
	if args.weaponObject:isExist() == true then
		if args.self:getDistance(args.weaponObject) < 0 then
			args.weaponObject:destroy()
		else
			timer.scheduleFunction(args.self.weaponLoop, args, timer.getTime() + args.self.checkTime)
		end
	end
end

function KillBorder:onEvent(event)
	if event.id == 1 and self:checkValidity(event) == true then
		self.weaponLoop({self = self, weaponObject = event.weapon})
	elseif event.id == 15 and self:checkValidity(event) == true then
		-- trigger.action.outTextForUnit(event.initiator:getID(), 'started playerloop for ' ..  event.initiator:getPlayerName(), 10, false)
		self.playerLoop({self = self, playerObject = event.initiator})
	elseif event.id == 15 then
		self.playerWarnLoop({self = self, playerObject = event.initiator})
	end
end

function KillBorder:start()
	world.addEventHandler(self)
end

function KillBorder:stop()
	timer.removeFunction(self.loopID)
	world.removeEventHandler(self)
end
--				  ReferenceGroup, 	Coalition,  Side,  GroupIdentifier, Time, WarnDistance, PunishType, PunishTimer, Sound
KillBorder:generate("Ground-1", 		0, 		 -1, 	    "PVP", 		 5,   	50000, 		   0,		   60, 	"testsound.ogg")
KillBorder:start()