# DCS-KillBorder

Version History
2.0.0 - initial KillBorder rework
2.1.0 - fixed distance calculation, added weapon killborder support, some changes to the mini manual
2.2.0 - changed loop to be event based, several removals of undefined behaviour, corrections in the mini manual
2.2.1 - removed debug message, worst bug ever fixed
2.2.2a - experimental sound support
Mini Manual
variables not mentioned here are internally managed and should not be fucked with
ReferenceGroup = the group used to generate the border, 2 units required, relative position of the units doesnt matter (lageunabhängig, wollte dieses wort immer schon mal verwenden haha :))
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
