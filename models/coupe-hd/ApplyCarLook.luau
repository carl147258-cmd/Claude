-- Run once in Studio's Command Bar (Script tab -> Command Bar) after importing coupe.glb.
-- Select the imported model in the Explorer first. It sets Roblox materials by MeshPart name.
local Selection = game:GetService("Selection")
local model = Selection:Get()[1]
assert(model, "Select the imported car model in the Explorer first")

local LOOK = {
	Paint = { Color = Color3.fromRGB(14, 14, 17), Material = Enum.Material.SmoothPlastic, Reflectance = 0.15 },
	Gloss = { Color = Color3.fromRGB(10, 10, 11), Material = Enum.Material.SmoothPlastic, Reflectance = 0.1 },
	Glass = { Color = Color3.fromRGB(30, 33, 38), Material = Enum.Material.Glass, Reflectance = 0.25, Transparency = 0.15 },
	Trim = { Color = Color3.fromRGB(12, 12, 13), Material = Enum.Material.SmoothPlastic, Reflectance = 0 },
	Chrome = { Color = Color3.fromRGB(110, 110, 115), Material = Enum.Material.Metal, Reflectance = 0.3 },
	Tyre = { Color = Color3.fromRGB(24, 24, 24), Material = Enum.Material.Rubber, Reflectance = 0 },
	Rim = { Color = Color3.fromRGB(84, 72, 60), Material = Enum.Material.Metal, Reflectance = 0.2 },
	Brake = { Color = Color3.fromRGB(120, 120, 124), Material = Enum.Material.Metal, Reflectance = 0.1 },
	Lens = { Color = Color3.fromRGB(60, 64, 72), Material = Enum.Material.Glass, Reflectance = 0.4 },
	LED = { Color = Color3.fromRGB(235, 245, 255), Material = Enum.Material.Neon, Reflectance = 0 },
	Tail = { Color = Color3.fromRGB(90, 8, 12), Material = Enum.Material.Glass, Reflectance = 0.3 },
	TailLED = { Color = Color3.fromRGB(220, 20, 30), Material = Enum.Material.Neon, Reflectance = 0 },
}

local changed = 0
for _, part in model:GetDescendants() do
	if part:IsA("MeshPart") then
		-- names look like "Paint", "Glass" or "WheelFL_Rim"
		local key = part.Name:match("_(%a+)$") or part.Name
		local look = LOOK[key]
		if look then
			for prop, value in look do
				part[prop] = value
			end
			if key ~= "Plate" then
				local sa = part:FindFirstChildOfClass("SurfaceAppearance")
				if sa then
					sa:Destroy() -- plain colours instead of imported flat textures
				end
			end
			changed += 1
		end
	end
end
print(`Car look applied to {changed} MeshParts`)
