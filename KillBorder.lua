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

--[[
Version History
2.0.0 - initial KillBorder rework
2.1.0 - fixed distance calculation, added weapon killborder support, some changes to the mini manual
2.2.0 - changed loop to be event based, several removals of undefined behaviour, corrections in the mini manual
2.2.1 - removed debug message, worst bug ever fixed
2.2.2a - experimental sound support

Mini Manual
variables not mentioned here are internally managed and should not be fucked with

ReferenceGroup = the group used to generate the border, 2 units required, relative position of the units doesnt matter

coalition/Coalition = 0 check all coalitions
coalition/Coalition = 1 check just red coalition
coalition/Coalition = 2 check just blu coalition

side/Side = 1 kill everything above the border
side/Side = -1 kill everything below the border

groupIdentifier/GroupIdentifier = "String" targeted group names must contain this

checkTime/Time = seconds delay between border checks

warnDistance/WarnDistance = the distance at which a warning text will be displayed, distance function was wonky but is fixed now, measurements is most likely in metres

punishType/PunishType = 0 tiny explosion every few seconds
punishType/PunishType = 1 instant kill
punishType/PunishType = 2 back to spectators, not supported yet

punishTimer/PunishTimer = time between punishments if punishType == 0

sound/Sound = soundfile to be played, has to be in the mission file with the following path l10n/DEFAULT/file, ogg and wav files should be possible
--]]

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

	-- local x1
	-- local y1

	-- if units[1]:getPoint().z < units[2]:getPoint().z then
	-- 	x1 = units[1]:getPoint().z
	-- 	y1 = units[1]:getPoint().x
	-- 	x2 = units[2]:getPoint().z
	-- 	y2 = units[2]:getPoint().x
	-- else
	-- 	x2 = units[1]:getPoint().z
	-- 	y2 = units[1]:getPoint().x
	-- 	x1 = units[2]:getPoint().z
	-- 	y1 = units[2]:getPoint().x
	-- end

	-- self.border.a = (y2-y1)/(x2-x1)
	-- self.border.c = y1 - self.border.a * x1

	-- trigger.action.lineToAll(-1, 69420, {x = self.border.a * 1000000 + self.border.c, y = 500, z = 1000000}, {x = self.border.a * -1000000 + self.border.c, y = 500, z = -1000000}, {1, 0, 0, 1}, 1, true)
	-- trigger.action.textToAll(-1, 42069, {x = units[1]:getPoint().x - 6000, y = units[1]:getPoint().y, z = units[1]:getPoint().z + 6000}, {1, 0, 0, 1}, {1, 0, 0, 0}, 20, true, 'PVP Border')
	for key, value in units do
		self.flexiborder.insert(value:getPoint())
	end
end

function KillBorder.playerLoop(args)
	if args.playerObject:isExist() then
		if args.self.groupArray[args.playerObject:getID()] == nil then
			args.self.groupArray[args.playerObject:getID()] = 0
		end
		local x0 = args.playerObject:getPoint().z
		local y0 = args.playerObject:getPoint().x
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
			trigger.action.outTextForUnit(args.playerObject:getID(), args.playerObject:getPlayerName() .. ' you are ' .. distance .. 'm away from the border of the allowed area, passing the border will be punished!', args.self.checkTime - 2, false)
			trigger.action.outSoundForUnit(args.playerObject:getID(), args.self.sound)
		else
			args.self.groupArray[args.playerObject:getID()] = 0
		end

		args.self.loopID = timer.scheduleFunction(args.self.playerLoop, args, timer.getTime() + args.self.checkTime)
	end
end

function KillBorder:getDistance(object)
	


	return (self.border.a * object:getPoint().z - object:getPoint().x + self.border.c) / math.sqrt((self.border.a)^2 + 1) * self.side
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
		self.playerLoop({self = self, playerObject = event.initiator})
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