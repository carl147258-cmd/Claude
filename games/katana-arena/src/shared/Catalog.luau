--!strict
-- ReplicatedStorage/Shared/Catalog (ModuleScript)
-- Everything the shop sells: swords, object sets and scenes. Prices are in coins.
-- The server validates every purchase against this table; the client only renders it.

export type ObjectKind = {
	Name: string,
	Shape: string, -- builder key in ObjectBuilder
	Radius: number, -- hit radius in studs (already scaled)
	Skin: Color3,
	Flesh: Color3, -- cut face and particle colour
	Points: number,
	Half: string?, -- "Ball" (default) or "Box"
	Burst: string?, -- "Juice" (default), "Fluff" (cotton + confetti) or "Sparkle" (sugar/plastic bits)
	IsBomb: boolean?,
}

export type SwordStyle = {
	Blade: { Color3 }, -- cycled per blade segment (stripes)
	BladeMaterial: Enum.Material,
	BladeNeon: boolean?,
	Edge: { Color3 }, -- cycled per segment
	Guard: Color3,
	Wrap: Color3,
	Glow: Color3,
	Curve: number, -- degrees per segment
	Width: number,
	Segments: number,
	Trail: { Color3 }, -- swipe streak / swoosh colours
}

export type Item = {
	Id: string,
	Name: string,
	Price: number,
	Description: string,
	Style: SwordStyle?,
	Kinds: { ObjectKind }?,
	Swatch: { Color3 }?,
	Rarity: string, -- key of Catalog.Rarities
	CoinBonus: number?, -- swords only: extra coins per point (0.1 = +10 %)
}

local OBJECT_SCALE = 2.3 -- objects are seen from behind the avatar, ~25 studs away

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function kind(
	name: string,
	shape: string,
	radius: number,
	skin: Color3,
	flesh: Color3,
	points: number,
	extra: { [string]: any }?
): ObjectKind
	local k: any = {
		Name = name,
		Shape = shape,
		Radius = radius * OBJECT_SCALE,
		Skin = skin,
		Flesh = flesh,
		Points = points,
	}
	if extra then
		for key, value in extra do
			k[key] = value
		end
	end
	return k
end

local Catalog = {}

Catalog.Categories = { "Swords", "Sets", "Scenes" }
Catalog.CategoryNames = { Swords = "Schwerter", Sets = "Objekte", Scenes = "Szenerien" }

Catalog.Swords = {
	{
		Id = "blutmond",
		Name = "Blutmond-Katana",
		Price = 0,
		Rarity = "Common",
		Description = "Dein erstes Katana.",
		Style = {
			Blade = { rgb(30, 30, 36) },
			BladeMaterial = Enum.Material.Metal,
			Edge = { rgb(255, 35, 70) },
			Guard = rgb(150, 112, 48),
			Wrap = rgb(150, 15, 35),
			Glow = rgb(255, 35, 70),
			Curve = 2.2,
			Width = 0.32,
			Segments = 7,
			Trail = { rgb(170, 60, 255), rgb(255, 35, 70) },
		},
	},
	{
		Id = "jade",
		Name = "Jade-Klinge",
		Price = 120,
		Rarity = "Common",
		Description = "Grün wie ein Bambuswald.",
		Style = {
			Blade = { rgb(40, 120, 80) },
			BladeMaterial = Enum.Material.Glass,
			Edge = { rgb(120, 255, 150) },
			Guard = rgb(200, 200, 190),
			Wrap = rgb(20, 70, 40),
			Glow = rgb(90, 255, 140),
			Curve = 0.6,
			Width = 0.34,
			Segments = 7,
			Trail = { rgb(20, 160, 90), rgb(160, 255, 170) },
		},
	},
	{
		Id = "eis",
		Name = "Eis-Klinge",
		Price = 700,
		Rarity = "Rare",
		CoinBonus = 0.05,
		Description = "Eiskalt und messerscharf.",
		Style = {
			Blade = { rgb(170, 225, 255) },
			BladeMaterial = Enum.Material.Ice,
			Edge = { rgb(230, 250, 255) },
			Guard = rgb(90, 150, 220),
			Wrap = rgb(30, 60, 120),
			Glow = rgb(120, 210, 255),
			Curve = 1.4,
			Width = 0.36,
			Segments = 8,
			Trail = { rgb(60, 140, 255), rgb(220, 250, 255) },
		},
	},
	{
		Id = "zuckerstange",
		Name = "Zuckerstangen-Schwert",
		Price = 450,
		Rarity = "Rare",
		CoinBonus = 0.05,
		Description = "Süß gestreift.",
		Style = {
			Blade = { rgb(240, 40, 50), rgb(250, 250, 250) },
			BladeMaterial = Enum.Material.SmoothPlastic,
			Edge = { rgb(255, 255, 255), rgb(255, 120, 140) },
			Guard = rgb(80, 200, 120),
			Wrap = rgb(250, 250, 250),
			Glow = rgb(255, 120, 150),
			Curve = 0,
			Width = 0.4,
			Segments = 8,
			Trail = { rgb(255, 60, 80), rgb(255, 255, 255) },
		},
	},
	{
		Id = "golddrache",
		Name = "Gold-Drachenschwert",
		Price = 1500,
		Rarity = "Epic",
		CoinBonus = 0.1,
		Description = "Breite Klinge, feuriges Glühen.",
		Style = {
			Blade = { rgb(230, 175, 50) },
			BladeMaterial = Enum.Material.Metal,
			Edge = { rgb(255, 130, 20) },
			Guard = rgb(160, 20, 20),
			Wrap = rgb(40, 10, 10),
			Glow = rgb(255, 120, 20),
			Curve = 1.0,
			Width = 0.5,
			Segments = 8,
			Trail = { rgb(255, 60, 0), rgb(255, 220, 80) },
		},
	},
	{
		Id = "laser",
		Name = "Laserschwert",
		Price = 2500,
		Rarity = "Epic",
		CoinBonus = 0.15,
		Description = "Reines Licht.",
		Style = {
			Blade = { rgb(80, 230, 255) },
			BladeMaterial = Enum.Material.Neon,
			BladeNeon = true,
			Edge = { rgb(220, 255, 255) },
			Guard = rgb(170, 175, 185),
			Wrap = rgb(40, 40, 45),
			Glow = rgb(60, 220, 255),
			Curve = 0,
			Width = 0.2,
			Segments = 9,
			Trail = { rgb(0, 140, 255), rgb(150, 255, 255) },
		},
	},
	{
		Id = "regenbogen",
		Name = "Regenbogen-Klinge",
		Price = 5000,
		Rarity = "Legendary",
		CoinBonus = 0.25,
		Description = "Die Legende.",
		Style = {
			Blade = { rgb(245, 245, 255) },
			BladeMaterial = Enum.Material.Glass,
			Edge = {
				rgb(255, 50, 50),
				rgb(255, 150, 30),
				rgb(255, 240, 40),
				rgb(60, 230, 80),
				rgb(40, 150, 255),
				rgb(150, 70, 255),
			},
			Guard = rgb(255, 255, 255),
			Wrap = rgb(120, 60, 200),
			Glow = rgb(255, 255, 255),
			Curve = 1.6,
			Width = 0.4,
			Segments = 9,
			Trail = { rgb(255, 50, 50), rgb(255, 240, 40), rgb(40, 150, 255), rgb(150, 70, 255) },
		},
	},
} :: { Item }

Catalog.Sets = {
	{
		Id = "fruechte",
		Name = "Früchte",
		Price = 0,
		Rarity = "Common",
		Description = "Melone, Orange, Apfel und mehr.",
		Kinds = {
			kind("Melone", "Melon", 1.45, rgb(52, 150, 60), rgb(245, 60, 80), 1),
			kind("Orange", "Orange", 0.95, rgb(255, 150, 25), rgb(255, 195, 80), 1),
			kind("Apfel", "Apple", 0.9, rgb(220, 30, 40), rgb(252, 242, 205), 1),
			kind("Zitrone", "Lemon", 0.85, rgb(255, 230, 50), rgb(255, 248, 160), 1),
			kind("Kiwi", "Kiwi", 0.8, rgb(130, 95, 55), rgb(135, 210, 65), 2),
			kind("Drachenfrucht", "Dragonfruit", 1.0, rgb(240, 45, 150), rgb(250, 250, 250), 3),
		},
	},
	{
		Id = "gemuese",
		Name = "Gemüse",
		Price = 150,
		Rarity = "Common",
		Description = "Tomate, Kürbis, Aubergine ...",
		Kinds = {
			kind("Tomate", "Tomato", 0.95, rgb(225, 35, 30), rgb(255, 90, 70), 1),
			kind("Kürbis", "Pumpkin", 1.35, rgb(245, 125, 20), rgb(255, 190, 80), 1),
			kind("Aubergine", "Eggplant", 1.0, rgb(85, 30, 110), rgb(240, 235, 200), 1),
			kind("Karotte", "Carrot", 0.95, rgb(255, 120, 20), rgb(255, 160, 60), 2),
			kind("Brokkoli", "Broccoli", 1.0, rgb(40, 130, 45), rgb(160, 210, 120), 3),
		},
	},
	{
		Id = "suessigkeiten",
		Name = "Süßigkeiten",
		Price = 600,
		Rarity = "Rare",
		Description = "Donut, Cupcake, Lolli ...",
		Kinds = {
			kind("Donut", "Donut", 1.1, rgb(215, 160, 95), rgb(255, 230, 190), 1, { Burst = "Sparkle" }),
			kind("Cupcake", "Cupcake", 1.0, rgb(255, 170, 210), rgb(140, 80, 50), 1, { Burst = "Sparkle" }),
			kind("Bonbon", "Candy", 0.85, rgb(60, 200, 255), rgb(200, 240, 255), 1, { Burst = "Sparkle" }),
			kind("Lolli", "Lollipop", 1.0, rgb(255, 80, 160), rgb(255, 230, 245), 2, { Burst = "Sparkle" }),
			kind("Eiskugel", "IceCream", 1.0, rgb(255, 200, 220), rgb(255, 245, 250), 3, { Burst = "Sparkle" }),
		},
	},
	{
		Id = "spielzeug",
		Name = "Spielzeug",
		Price = 1200,
		Rarity = "Epic",
		Description = "Wasserball, Würfel, Zauberwürfel ...",
		Kinds = {
			kind("Wasserball", "BeachBall", 1.2, rgb(240, 240, 240), rgb(250, 250, 250), 1, { Burst = "Sparkle" }),
			kind(
				"Würfel",
				"Dice",
				0.9,
				rgb(245, 245, 245),
				rgb(230, 230, 230),
				1,
				{ Half = "Box", Burst = "Sparkle" }
			),
			kind("Kreisel", "Top", 1.0, rgb(255, 210, 40), rgb(255, 240, 160), 1, { Burst = "Sparkle" }),
			kind(
				"Spielzeugauto",
				"Car",
				1.1,
				rgb(230, 30, 40),
				rgb(60, 60, 70),
				2,
				{ Half = "Box", Burst = "Sparkle" }
			),
			kind(
				"Zauberwürfel",
				"Cube",
				0.95,
				rgb(25, 25, 30),
				rgb(40, 40, 45),
				3,
				{ Half = "Box", Burst = "Sparkle" }
			),
		},
	},
	{
		Id = "kuscheltiere",
		Name = "Kuscheltiere",
		Price = 3500,
		Rarity = "Legendary",
		Description = "Teddy, Hase, Ente, Pinguin, Einhorn.",
		Kinds = {
			kind("Teddy", "Teddy", 1.15, rgb(160, 105, 60), rgb(250, 248, 240), 1, { Burst = "Fluff" }),
			kind("Hase", "Bunny", 1.0, rgb(245, 240, 235), rgb(250, 248, 240), 1, { Burst = "Fluff" }),
			kind("Ente", "Duck", 1.0, rgb(255, 215, 40), rgb(250, 248, 240), 1, { Burst = "Fluff" }),
			kind("Pinguin", "Penguin", 1.05, rgb(30, 32, 40), rgb(250, 248, 240), 2, { Burst = "Fluff" }),
			kind("Einhorn", "Unicorn", 1.05, rgb(250, 245, 255), rgb(250, 248, 240), 3, { Burst = "Fluff" }),
		},
	},
} :: { Item }

Catalog.Scenes = {
	{
		Id = "blutmond",
		Name = "Blutmond-Nacht",
		Price = 0,
		Rarity = "Common",
		Description = "Roter Mond über den Gipfeln.",
		Swatch = { rgb(255, 70, 60), rgb(40, 15, 40) },
	},
	{
		Id = "kirschbluete",
		Name = "Kirschblüten-Tempel",
		Price = 200,
		Rarity = "Common",
		Description = "Rosa Bäume, Pagode und Teich.",
		Swatch = { rgb(255, 180, 210), rgb(120, 190, 255) },
	},
	{
		Id = "strand",
		Name = "Sonnenstrand",
		Price = 500,
		Rarity = "Rare",
		Description = "Meer, Palmen und Sonne.",
		Swatch = { rgb(255, 220, 120), rgb(40, 170, 230) },
	},
	{
		Id = "skyline",
		Name = "Skyline-Stadt",
		Price = 1200,
		Rarity = "Epic",
		Description = "Neonlichter einer Großstadt.",
		Swatch = { rgb(255, 60, 200), rgb(20, 20, 60) },
	},
	{
		Id = "unterwasser",
		Name = "Unterwasser",
		Price = 1800,
		Rarity = "Epic",
		Description = "Korallen, Fische und Blasen.",
		Swatch = { rgb(60, 220, 230), rgb(10, 50, 120) },
	},
	{
		Id = "weltraum",
		Name = "Weltraum",
		Price = 4500,
		Rarity = "Legendary",
		Description = "Planeten und Sterne.",
		Swatch = { rgb(170, 90, 255), rgb(5, 5, 20) },
	},
} :: { Item }

Catalog.Defaults = { Swords = "blutmond", Sets = "fruechte", Scenes = "blutmond" }

-- Rarity tiers: shop cards glow in the tier colour.
Catalog.Rarities = {
	Common = { Name = "Gewöhnlich", Color = rgb(170, 170, 180) },
	Rare = { Name = "Selten", Color = rgb(60, 150, 255) },
	Epic = { Name = "Episch", Color = rgb(180, 80, 255) },
	Legendary = { Name = "Legendär", Color = rgb(255, 190, 40) },
} :: { [string]: { Name: string, Color: Color3 } }

-- Daily login reward: index = day of the current streak (a missed day restarts at 1).
Catalog.DailyRewards = { 50, 75, 100, 150, 200, 250, 400 }

-- Robux offers. Create them in the Creator Dashboard (Monetization) and paste the ids
-- here; an id of 0 keeps the offer greyed out in the shop.
Catalog.Robux = {
	DoubleCoins = { PassId = 0, Robux = 149, Name = "Doppelte Münzen" },
	CoinPacks = {
		{ ProductId = 0, Coins = 500, Robux = 25 },
		{ ProductId = 0, Coins = 1500, Robux = 69 },
		{ ProductId = 0, Coins = 5000, Robux = 199 },
	},
}

function Catalog.CoinPackByProduct(productId: number): { ProductId: number, Coins: number, Robux: number }?
	for _, pack in Catalog.Robux.CoinPacks do
		if pack.ProductId ~= 0 and pack.ProductId == productId then
			return pack
		end
	end
	return nil
end

Catalog.Bomb = kind("Bombe", "Bomb", 1.0, rgb(25, 25, 30), rgb(255, 120, 0), 0, { IsBomb = true })

local function list(category: string): { Item }?
	return (Catalog :: any)[category]
end

function Catalog.IsCategory(category: any): boolean
	return category == "Swords" or category == "Sets" or category == "Scenes"
end

function Catalog.Find(category: string, id: any): Item?
	local items = list(category)
	if not items or typeof(id) ~= "string" then
		return nil
	end
	for _, item in items do
		if item.Id == id then
			return item
		end
	end
	return nil
end

-- Kind index 0 is the bomb in every set.
function Catalog.GetKind(setId: string, index: number): ObjectKind?
	if index == 0 then
		return Catalog.Bomb
	end
	local set = Catalog.Find("Sets", setId)
	return set and set.Kinds and set.Kinds[index]
end

return Catalog
