-- ============================================================
-- PoseConfig.lua
-- Config daftar animasi Pose (39 animasi)
-- Path: ReplicatedStorage > Emotes > PoseConfig
-- ============================================================

local PoseConfig = {
	{ name = "2017X Point", animationId = "rbxassetid://93810591156861" },
	{ name = "Chill Guy", animationId = "rbxassetid://107466254930590" },
	{ name = "Elegant Picture", animationId = "rbxassetid://113345525010569" },
	{ name = "Fashionable Pretty", animationId = "rbxassetid://133076490374907" },
	{ name = "For the Pic", animationId = "rbxassetid://117336874204710" },
	{ name = "Wall Lean", animationId = "rbxassetid://113694692828125" },
	{ name = "Cower", animationId = "rbxassetid://4940563117" },
	{ name = "Jumping Wave", animationId = "rbxassetid://10714378156" },
	{ name = "Sad", animationId = "rbxassetid://131737004503275" },
	{ name = "Sleep Face", animationId = "rbxassetid://10714360343" },
	{ name = "Spiderman", animationId = "rbxassetid://123888267685221" },
	{ name = "Squat Sit", animationId = "rbxassetid://84129863420846" },
	{ name = "Fantano Squat", animationId = "rbxassetid://124972507696792" },
	{ name = "Cute Hips", animationId = "rbxassetid://117181705578424" },
	{ name = "sit", animationId = "rbxassetid://86898753801433" },
	{ name = "Spiderman Hanging", animationId = "rbxassetid://82468904268739" },
	{ name = "Shinra Pose", animationId = "rbxassetid://121514889513586" },
	{ name = "Fashion", animationId = "rbxassetid://93106139772346" },
	{ name = "Sit 2", animationId = "rbxassetid://102544119718369" },
	{ name = "Kid tantrum", animationId = "rbxassetid://86339673982616" },
	{ name = "Police Vest Rest", animationId = "rbxassetid://83026903211659" },
	{ name = "Bang Head", animationId = "rbxassetid://89060597619453" },
	{ name = "Sweet Hug V2", animationId = "rbxassetid://118264035209903" },
	{ name = "girl idle pose", animationId = "rbxassetid://89439480855309" },
	{ name = "FF Push Up", animationId = "rbxassetid://76988349893259" },
	{ name = "Bored", animationId = "rbxassetid://10713992055" },
	{ name = "Spider Swing", animationId = "rbxassetid://120676400102543" },
	{ name = "Sleeping Soundly", animationId = "rbxassetid://121641415206650" },
	{ name = "Swinging", animationId = "rbxassetid://78512680384025" },
	{ name = "Fetal Crying", animationId = "rbxassetid://87595043597341" },
	{ name = "sitting idle pose", animationId = "rbxassetid://112618514893492" },
	{ name = "Adventure Pose", animationId = "rbxassetid://105286298891700" },
	{ name = "Hero Landing", animationId = "rbxassetid://10714360164" },
	{ name = "Sweet Sit V1", animationId = "rbxassetid://75141049180386" },
	{ name = "sit and hug", animationId = "rbxassetid://117154715182434" },
	{ name = "Pose 1", animationId = "rbxassetid://90198206120117" },
	{ name = "Handstand Pose", animationId = "rbxassetid://75102478510616" },
	{ name = "doll idle pose", animationId = "rbxassetid://75578209828688" },
	{ name = "Nonchalant Sit", animationId = "rbxassetid://124882373076963" },
}

-- Lookup dictionary by name & aliases
PoseConfig.Lookup = {}
for _, item in ipairs(PoseConfig) do
	item.id = item.animationId
	PoseConfig[item.name] = item.animationId
	PoseConfig.Lookup[item.name] = item.animationId
end

-- Support trailing space alias for Cower if referenced from legacy audit
if PoseConfig["Cower"] then
	PoseConfig["Cower  "] = PoseConfig["Cower"]
	PoseConfig.Lookup["Cower  "] = PoseConfig["Cower"]
end

return PoseConfig
