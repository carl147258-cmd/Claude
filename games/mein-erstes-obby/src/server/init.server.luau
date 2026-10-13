-- ServerScriptService/Server (Script)
-- Entry point: all server modules are children of this script.

local CourseBuilder = require(script.CourseBuilder)
local PlayerData = require(script.PlayerData)
local Checkpoints = require(script.Checkpoints)
local Hazards = require(script.Hazards)
local Monetization = require(script.Monetization)

local course = CourseBuilder.BuildIfMissing()
Checkpoints.Start(course) -- before PlayerData.Start, so it hears every Loaded event
PlayerData.Start()
Hazards.Start()
Monetization.Start(Checkpoints)
