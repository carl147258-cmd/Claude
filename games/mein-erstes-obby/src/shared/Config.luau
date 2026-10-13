--!strict
-- ReplicatedStorage/Shared/Config (ModuleScript)
-- Settings read by both server and client.

return {
	-- Number of stages the CourseBuilder generates.
	StageCount = 15,

	-- Developer Product ID for "Skip stage". 0 = disabled (button hidden).
	-- Create it at create.roblox.com -> your experience -> Monetization -> Developer Products.
	SkipStageProductId = 0,

	-- Change the name (e.g. "_v2") to reset all progress.
	DataStoreName = "ObbyData_v1",

	-- Seconds between automatic saves.
	AutosaveInterval = 90,
}
