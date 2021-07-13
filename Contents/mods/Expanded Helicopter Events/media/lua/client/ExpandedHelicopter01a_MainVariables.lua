---@class eHelicopter
eHelicopter = {}

---@field hoverOnTargetDuration number|boolean How long the helicopter will hover over the player, this is subtracted from every tick
eHelicopter.hoverOnTargetDuration = false

---@field searchForTargetDurationMS number How long the helicopter will search for last seen targets
eHelicopter.searchForTargetDuration = 30000

---@field shadow boolean | WorldMarkers.GridSquareMarker
eHelicopter.shadow = true

---@field crashType boolean
eHelicopter.crashType = {"UH1HCrash"}

---@field scrapAndParts table
eHelicopter.scrapAndParts = {} -- {["vehicleSection"]="Base.TYPE",["scrapItem"]="Base.TYPE"}

---@field crew table list of IDs and chances (similar to how loot distribution is handled)
---Example: crew = {"pilot", 100, "crew", 75, "crew", 50}
---If there is no number following a string a chance of 100% will be applied.
eHelicopter.crew = {"AirCrew", 100}

---@field dropItems table
eHelicopter.dropItems = false

---@field dropPackages table
eHelicopter.dropPackages = false

---@field eventSoundEffects table
eHelicopter.eventSoundEffects = {
	--{"hoverOverTarget"]=nil,["flyOverTarget"]=nil}
	--["lostTarget"]=nil, ["foundTarget"]=nil, ["droppingPackage"]=nil,
	--["additionalAttackingSound"]=nil, ["additionalFlightSound"]=nil,
	["attackSingle"] = "eHeli_machine_gun_fire_single",
	["attackLooped"] = "eHeli_machine_gun_fire_looped",
	["attackImpacts"] = "eHeli_fire_impact",
	["flightSound"] = "eHelicopter", ["crashEvent"] = "eHelicopterCrash"
}

---@field announcerVoice string
eHelicopter.announcerVoice = false

---@field randomEdgeStart boolean
eHelicopter.randomEdgeStart = false

---example: {["preset1"]=0,["preset2"]=25,["preset3"]=50} = at 0% (days out of cutoff day) preset1 is chosen, at 25% preset2 is chosen, etc.
---@field presetProgression table Table of presetIDs and corresponding % preset is compared to Days/CuttOffDay
eHelicopter.presetProgression = false

---Example: {"preset1",2,"preset2","preset3",4} = a list equal to {"preset1","preset1","preset2","preset3","preset3","preset3","preset3"}
---@field presetRandomSelection table Table of presetIDs and optional corresponding weight (weight is 1 if none found) in list to be chosen from.
eHelicopter.presetRandomSelection = false

---@field frequencyFactor number This is multiplied against the min/max day range; less than 1 results in higher frequency, more than 1 results in less frequency
eHelicopter.frequencyFactor = 1

---@field cutOffFactor number This is multiplied against eHelicopterSandbox.config.cutOffDay
eHelicopter.cutOffFactor = 1

---@field speed number
eHelicopter.speed = 0.08

---@field topSpeedFactor number speed x this = top "speed"
eHelicopter.topSpeedFactor = 3

---@field flightVolume number
eHelicopter.flightVolume = 75

---@field hostilePreference string
---set to 'false' for *none*, otherwise has to be 'IsoPlayer' or 'IsoZombie' or 'IsoGameCharacter'
eHelicopter.hostilePreference = false

---@field attackDelay number delay in milliseconds between attacks
eHelicopter.attackDelay = 85

---@field attackScope number number of rows from "center" IsoGridSquare out
--- **area formula:** ((Scope*2)+1) ^2
---
--- scope:⠀0=1x1;⠀1=3x3;⠀2=5x5;⠀3=7x7;⠀4=9x9
eHelicopter.attackScope = 1

---@field attackSpread number number of rows made of "scopes" from center-scope out
---**formula for ScopeSpread area:**
---
---((Scope * 2)+1) * ((Spread * 2)+1) ^2
---
--- **Examples:**
---
---⠀  ⠀*scope* 🡇
--- -----------------------------------
--- *spread*⠀🡆 ⠀ | 00 | 01 | 02 | 03 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀ ⠀| 00 | 01 | 09 | 25 | 49 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀ ⠀| 01 | 09 | 81 | 225 | 441 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀⠀  | 02 | 25 | 225 | 625 | 1225 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀  ⠀| 03 | 49 | 441 | 1225 | 2401 |
--- -----------------------------------
eHelicopter.attackSpread = 3

---@field attackHitChance number multiplied against chance to hit in attacking
eHelicopter.attackHitChance = 85

---@field attackDamage number damage dealt to zombies/players on hit (gets randomized to: attackDamage * random(1 to 1.5))
eHelicopter.attackDamage = 20

---// UNDER THE HOOD STUFF //---

---This function, when called stores the above listed variables, on game load, for reference later
---
---NOTE: Any variable which is by default `nil` can't be loaded over - consider making it false if you need it
---@param listToSaveTo table
---@param checkIfNotIn table
function eHelicopter_variableBackUp(listToSaveTo, checkIfNotIn)--, debugID)
	for k,v in pairs(eHelicopter) do
		if ((not checkIfNotIn) or (checkIfNotIn[k] == nil)) then
			--[DEBUG]] print("EHE: "..debugID..": "..k.." = ".."("..type(v)..") "..tostring(v))
			--tables have to be copied piece by piece or risk creating a direct reference link
			if type(v) == "table" then
				--[DEBUG]] print("--- "..k.." is a table (#"..#v.."); generating copy:")
				local tmpTable = {}
				for kk,vv in pairs(v) do
					--[DEBUG]] print( "------ "..kk.." = ".."("..type(vv)..") "..tostring(vv))
					tmpTable[kk] = vv
				end
				listToSaveTo[k]=tmpTable
			else
				listToSaveTo[k]=v
			end
		end
	end
end

--store "initial" vars to reference when loading presets
eHelicopter_initialVars = {}
eHelicopter_variableBackUp(eHelicopter_initialVars, nil, "initialVars")

--the below variables are to be considered "temporary"
---@field height number
eHelicopter.height = 7
---@field state string
eHelicopter.state = false
---@field crashing
eHelicopter.crashing = false
---@field timeUntilCanAnnounce number
eHelicopter.timeUntilCanAnnounce = -1
---@field preflightDistance number
eHelicopter.preflightDistance = false
---@field announceEmitter FMODSoundEmitter | BaseSoundEmitter
eHelicopter.announceEmitter = false
---@field lastAnnouncedLine string
eHelicopter.lastAnnouncedLine = false
---@field heldEventSoundEffectEmitters table
eHelicopter.heldEventSoundEffectEmitters = {}
---@field target IsoObject
eHelicopter.target = false
---@field trueTarget IsoGameCharacter
eHelicopter.trueTarget = false
---@field timeSinceLastSeenTarget number
eHelicopter.timeSinceLastSeenTarget = -1
---@field timeSinceLastRoamed number
eHelicopter.timeSinceLastRoamed = -1
---@field attackDistance number
eHelicopter.attackDistance = false
---@field targetPosition Vector3 "position" of target, pair of coordinates which can utilize Vector3 math
eHelicopter.targetPosition = false
---@field lastMovement Vector3 consider this to be velocity (direction/angle and speed/step-size)
eHelicopter.lastMovement = false
---@field currentPosition Vector3 consider this a pair of coordinates which can utilize Vector3 math
eHelicopter.currentPosition = false
---@field lastAttackTime number
eHelicopter.lastAttackTime = -1
---@field hostilesToFireOnIndex number
eHelicopter.hostilesToFireOnIndex = 0
---@field hostilesToFireOn table
eHelicopter.hostilesToFireOn = {}
---@field hostilesAlreadyFiredOn table
eHelicopter.hostilesAlreadyFiredOn = {}
---@field lastScanTime number
eHelicopter.lastScanTime = -1
---@field shadowBobRate number
eHelicopter.shadowBobRate = 0.05
---@field timeSinceLastShadowBob number
eHelicopter.timeSinceLastShadowBob = -1

--This stores the above "temporary" variables for resetting eHelicopters later
eHelicopter_temporaryVariables = {}
eHelicopter_variableBackUp(eHelicopter_temporaryVariables, eHelicopter_initialVars, "temporaryVariables")

--ID must not be reset ever
---@field ID number
eHelicopter.ID = 0