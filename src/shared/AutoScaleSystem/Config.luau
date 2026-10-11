-- ============================================================
--  Lokasi : ReplicatedStorage > AutoScaleSystem > Config(ModuleScript)
-- ============================================================

local Config = {}

-- ── Resolusi Dasar ────────────────────────────────────────────
Config.BASE_RESOLUTION_X = 1366
Config.BASE_RESOLUTION_Y = 768

-- ── Batas Scale ───────────────────────────────────────────────
Config.MIN_SCALE = 0.5   -- ★ Dinaikkan dari 0.35 untuk safety
Config.MAX_SCALE = 1.8   -- ★ Diturunkan dari 2.00 untuk mencegah terlalu besar

-- ── Kurva Boost ───────────────────────────────────────────────
Config.SMALL_SCREEN_BOOST = 0.35  -- ★ Sedikit dikurangi
Config.LARGE_SCREEN_SHRINK = 0.88 -- ★ Sedikit ditambah

-- ── Debug Mode ────────────────────────────────────────────────
Config.DEBUG_MODE = false  -- Set true untuk melihat log scale

return Config
