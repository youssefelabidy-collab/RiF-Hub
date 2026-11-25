local Config = {
    AutoFarmEgg = true,
    AutoBestEgg = true,
    NoMonsterDamage = true,
    AutoTreadmill = true,

    TargetEggName = "GoldenEgg",
    EggTeleportDelay = 0.14,
    BestEggInterval = 0.22,
    EggAttributePriority = { "Power", "Multiplier", "Value", "RarityScore" },

    MonsterFolderName = "Monsters",
    MonsterSafeRadius = 20,
    MonsterLiftHeight = 10,
    TreadmillPartName = "SpeedTreadmill",
    TreadmillDelay = 0.16,

    EggsFolderName = "Eggs",

    -- هامش عشوائي لتفادي النمط الثابت
    TimingJitter = 0.06,
    PositionJitter = 0.65,
}

return Config
