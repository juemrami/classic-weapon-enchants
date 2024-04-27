local _, 
    ---@type ClassicWeaponEnchants
    addon = ...;

-- data ripped from following tables for respective clients. check on new builds for updates.
--  https://wago.tools/db2/SpellItemEnchantment?build=1.15.2.54332&locale=enUS
--  https://wago.tools/db2/SpellEffect?build=1.15.2.54332&locale=enUS 
--  https://wago.tools/db2/ItemEffect?build=1.15.2.54332&locale=enUS
--  https://wago.tools/db2/ItemSparse?build=1.15.2.54332&locale=enUS
--  https://wago.tools/db2/SpellName?build=1.15.2.54332&locale=enUS

---@type ClassicWeaponEnchants.ItemImbues
local tempEnchantItems = {
    -- Misc
    [221362] = {spellID = 446637, enchant = 7327}, -- Weapon Cleaning Cloth
    -- Poisons
    [2892] = { spell = 2823, enchant = 7 },        -- Deadly Poison
    [2893] = { spell = 2824, enchant = 8 },        -- Deadly Poison II
    [8984] = { spell = 11355, enchant = 626 },     -- Deadly Poison III
    [8985] = { spell = 11356, enchant = 627 },     -- Deadly Poison IV
    [20844] = { spell = 25351, enchant = 2630 },   -- Deadly Poison V
    [3775] = { spell = 3408, enchant = 22 },       -- Crippling Poison
    [3776] = { spell = 11202, enchant = 603 },     -- Crippling Poison II
    [5237] = { spell = 5761, enchant = 35 },       -- Mind-numbing Poison
    [6951] = { spell = 8693, enchant = 23 },       -- Mind-numbing Poison II
    [9186] = { spell = 11399, enchant = 643 },     -- Mind-numbing Poison III
    [6947] = { spell = 8679, enchant = 323 },      -- Instant Poison
    [6949] = { spell = 8686, enchant = 324 },      -- Instant Poison II
    [6950] = { spell = 8688, enchant = 325 },      -- Instant Poison III
    [8926] = { spell = 11338, enchant = 623 },     -- Instant Poison IV
    [8927] = { spell = 11339, enchant = 624 },     -- Instant Poison V
    [8928] = { spell = 11340, enchant = 625 },     -- Instant Poison VI
    [10918] = { spell = 13219, enchant = 703 },    -- Wound Poison
    [10920] = { spell = 13225, enchant = 704 },    -- Wound Poison II
    [10921] = { spell = 13226, enchant = 705 },    -- Wound Poison III
    [10922] = { spell = 13227, enchant = 706 },    -- Wound Poison IV
    -- Sharpening Stones
    [2862] = { spell = 2828, enchant = 40 },       -- Rough Sharpening Stone
    [2863] = { spell = 2829, enchant = 13 },       -- Coarse Sharpening Stone
    [2871] = { spell = 2830, enchant = 14 },       -- Heavy Sharpening Stone
    [3239] = { spell = 3112, enchant = 19 },       -- Rough Weightstone
    [3240] = { spell = 3113, enchant = 20 },       -- Coarse Weightstone
    [3241] = { spell = 3114, enchant = 21 },       -- Heavy Weightstone
    [7964] = { spell = 9900, enchant = 483 },      -- Solid Sharpening Stone
    [7965] = { spell = 9903, enchant = 484 },      -- Solid Weightstone
    [12404] = { spell = 16138, enchant = 1643 },   -- Dense Sharpening Stone
    [12643] = { spell = 16622, enchant = 1703 },   -- Dense Weightstone
    [18262] = { spell = 22756, enchant = 2506 },   -- Elemental Sharpening Stone
    [23122] = { spell = 28891, enchant = 2684 },   -- Consecrated Sharpening Stone
    [211845] = { spell = 430392, enchant = 7098 }, -- Blackfathom Sharpening Stone
    -- Oils
    [3824] = { spell = 3594, enchant = 25 },       -- Shadow Oil
    [3829] = { spell = 3595, enchant = 26 },       -- Frost Oil
    [20744] = { spell = 25117, enchant = 2623 },   -- Minor Wizard Oil
    [20745] = { spell = 25118, enchant = 2624 },   -- Minor Mana Oil
    [20746] = { spell = 25119, enchant = 2626 },   -- Lesser Wizard Oil
    [20747] = { spell = 25120, enchant = 2625 },   -- Lesser Mana Oil
    [20748] = { spell = 25123, enchant = 2629 },   -- Brilliant Mana Oil
    [20749] = { spell = 25122, enchant = 2628 },   -- Brilliant Wizard Oil
    [20750] = { spell = 25121, enchant = 2627 },   -- Wizard Oil
    [23123] = { spell = 28898, enchant = 2685 },   -- Blessed Wizard Oil
    [211848] = { spell = 430585, enchant = 7099 }, -- Blackfathom Mana Oil
}
---@type ClassicWeaponEnchants.SpellImbues
local tempEnchantSpells = {
    [8017] = { enchant = 29 },    -- Rockbiter Weapon I
    [8018] = { enchant = 6 },     -- Rockbiter Weapon II
    [8019] = { enchant = 1 },     -- Rockbiter Weapon III
    [10399] = { enchant = 503 },  -- Rockbiter Weapon IV
    [16314] = { enchant = 1663 }, -- Rockbiter Weapon V
    [16315] = { enchant = 683 },  -- Rockbiter Weapon VI
    [16316] = { enchant = 1664 }, -- Rockbiter Weapon VII
    [8024] = { enchant = 5 }, -- Flametongue Weapon I
    [8027] = { enchant = 4 }, -- Flametongue Weapon II
    [8030] = { enchant = 3 }, -- Flametongue Weapon III
    [16339] = { enchant = 523 },  -- Flametongue Weapon IV
    [16341] = { enchant = 1665 }, -- Flametongue Weapon V
    [16342] = { enchant = 1666 }, -- Flametongue Weapon VI
    [8033] = { enchant = 2 },     -- Frostbrand Weapon I
    [8038] = { enchant = 12 },    -- Frostbrand Weapon II
    [10456] = { enchant = 524 },  -- Frostbrand Weapon III
    [16355] = { enchant = 1667 }, -- Frostbrand Weapon IV
    [16356] = { enchant = 1668 }, -- Frostbrand Weapon V
    [8232] = { enchant = 283 },   -- Windfury Weapon I
    [8235] = { enchant = 284 },   -- Windfury Weapon II
    [10486] = { enchant = 525 },  -- Windfury Weapon III
    [16362] = { enchant = 1669 }, -- Windfury Weapon IV
    -- [7434] = { enchant = 31 }, -- Imbue Weapon - Beastslayer I
    -- [7439] = { enchant = 28 }, -- Imbue Cloak - Minor Resistance I
    -- [7448] = { enchant = 63 }, -- Imbue Chest - Lesser Absorb I
    -- [7451] = { enchant = 64 }, -- Imbue Chest - Minor Spirit I
    -- [7769] = { enchant = 244 }, -- Imbue Bracers - Minor Wisdom OLD I
    -- [7853] = { enchant = 252 }, -- Imbue Chest - Lesser Spirit I
    -- [7855] = { enchant = 253 }, -- Imbue Chest - Absorb I
    -- [7865] = { enchant = 257 }, -- Imbue Cloak - Lesser Protection I
    -- [399699] = { enchant = 2506 }, -- S03 - Runecarving Test - Sharpen Helm - Critical I
    -- [400104] = { enchant = 6785 }, -- Engrave Pants - Shadowstep I
    -- [402861] = { enchant = 6751 }, -- Engrave Pants - Shadowfiend I
    -- [403446] = { enchant = 6788 }, -- Engrave Pants - Commanding Shout I
    -- [410013] = { enchant = 6849 }, -- Engrave Bracers - Hammer of the Righteous I
    -- [410014] = { enchant = 6850 }, -- Engrave Chest - Divine Storm I
    -- [410104] = { enchant = 6884 }, -- Engrave Gloves - Lava Lash I
    -- [416084] = { enchant = 6992 }, -- Engrave Belt - Aspect of the Viper I
    -- [425170] = { enchant = 7020 }, -- Engrave Pants - Icy Veins I
    -- [429247] = { enchant = 7092 }, -- Engrave Helm - Improved Sanctuary I
    -- [429251] = { enchant = 7088 }, -- Engrave Helm - Fanaticism I
    -- [429255] = { enchant = 7090 }, -- Engrave Bracers - Purifying Power I
    -- [429304] = { enchant = 7093 }, -- Engrave Helm - Deep Freeze I
    -- [429306] = { enchant = 7094 }, -- Engrave Helm - Temporal Anomaly I
    -- [429309] = { enchant = 7096 }, -- Engrave Bracers - Displacement I
    -- [431673] = { enchant = 7112 }, -- Engrave Bracers - Despair I
    -- [431745] = { enchant = 7115 }, -- Engrave Helm - Backdraft I
}
addon.ItemImbues = tempEnchantItems
addon.SpellImbues = tempEnchantSpells
