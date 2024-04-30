local _, 
    ---@class ClassicWeaponEnchants
    addon = ...;

---@alias SpellID integer
---@alias EnchantID integer
---@alias ItemID integer
---@alias ClassicWeaponEnchants.ItemImbues {[ItemID]: {spell: SpellID, enchant: EnchantID}}
---@alias ClassicWeaponEnchants.SpellImbues {[SpellID]: {enchant: EnchantID}}

-- spellID isnt used atm in favor of the API GetItemSpell(itemID) which returns the same spellID for the item.
-- enchantID isnt used atm but its can be used to check for the remaining duration of an enchant. (GetWeaponEnchantInfo returns the enchantID)
---@see GetWeaponEnchantInfo

---@type ClassicWeaponEnchants.ItemImbues
local tempEnchantItems = {
    [6213] = {spell = 7407, enchant = 1}, -- Test Sharpening Stone
    [2862] = {spell = 2828, enchant = 40}, -- Rough Sharpening Stone
    [2863] = {spell = 2829, enchant = 13}, -- Coarse Sharpening Stone
    [2871] = {spell = 2830, enchant = 14}, -- Heavy Sharpening Stone
    [2892] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [2893] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [8984] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [8985] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [20844] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [22053] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [22054] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [43232] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [43233] = {spell = 2823, enchant = 7}, -- Deadly Poison
    [3239] = {spell = 3112, enchant = 19}, -- Rough Weightstone
    [3240] = {spell = 3113, enchant = 20}, -- Coarse Weightstone
    [3241] = {spell = 3114, enchant = 21}, -- Heavy Weightstone
    [3775] = {spell = 3408, enchant = 22}, -- Crippling Poison
    [3776] = {spell = 3408, enchant = 22}, -- Crippling Poison
    [3824] = {spell = 3594, enchant = 25}, -- Shadow Oil
    [3829] = {spell = 3595, enchant = 26}, -- Frost Oil
    [22522] = {spell = 28017, enchant = 2678}, -- Superior Wizard Oil
    [5237] = {spell = 5761, enchant = 35}, -- Mind-Numbing Poison
    [28420] = {spell = 34339, enchant = 2954}, -- Fel Weightstone
    [6529] = {spell = 8087, enchant = 263}, -- Shiny Bauble
    [69907] = {spell = 99315, enchant = 263}, -- Corpse Worm
    [6530] = {spell = 8088, enchant = 264}, -- Nightcrawlers
    [6811] = {spell = 8532, enchant = 264}, -- Aquadynamic Fish Lens
    [6532] = {spell = 8090, enchant = 265}, -- Bright Baubles
    [7307] = {spell = 9092, enchant = 265}, -- Flesh Eating Worm
    [33820] = {spell = 43699, enchant = 265}, -- Weather-Beaten Fishing Hat
    [35713] = {spell = 43699, enchant = 265}, -- Ninja Hook [PH]
    [6533] = {spell = 8089, enchant = 266}, -- Aquadynamic Fish Attractor
    [34861] = {spell = 45731, enchant = 266}, -- Sharpened Fish Hook
    [62673] = {spell = 87646, enchant = 266}, -- Feathered Lure
    [6947] = {spell = 8679, enchant = 323}, -- Instant Poison
    [6949] = {spell = 8679, enchant = 323}, -- Instant Poison
    [6950] = {spell = 8679, enchant = 323}, -- Instant Poison
    [8928] = {spell = 8679, enchant = 323}, -- Instant Poison
    [8926] = {spell = 8679, enchant = 323}, -- Instant Poison
    [8927] = {spell = 8679, enchant = 323}, -- Instant Poison
    [21927] = {spell = 8679, enchant = 323}, -- Instant Poison
    [43230] = {spell = 8679, enchant = 323}, -- Instant Poison
    [43231] = {spell = 8679, enchant = 323}, -- Instant Poison
    [7964] = {spell = 9900, enchant = 483}, -- Solid Sharpening Stone
    [7965] = {spell = 9903, enchant = 484}, -- Solid Weightstone
    [10918] = {spell = 13219, enchant = 703}, -- Wound Poison
    [10920] = {spell = 13219, enchant = 703}, -- Wound Poison
    [10921] = {spell = 13219, enchant = 703}, -- Wound Poison
    [10922] = {spell = 13219, enchant = 703}, -- Wound Poison
    [22055] = {spell = 13219, enchant = 703}, -- Wound Poison
    [43234] = {spell = 13219, enchant = 703}, -- Wound Poison
    [43235] = {spell = 13219, enchant = 703}, -- Wound Poison
    [12404] = {spell = 16138, enchant = 1643}, -- Dense Sharpening Stone
    [12643] = {spell = 16622, enchant = 1703}, -- Dense Weightstone
    [18262] = {spell = 22756, enchant = 2506}, -- Elemental Sharpening Stone
    [20744] = {spell = 25117, enchant = 2623}, -- Minor Wizard Oil
    [20745] = {spell = 25118, enchant = 2624}, -- Minor Mana Oil
    [20746] = {spell = 25119, enchant = 2626}, -- Lesser Wizard Oil
    [20747] = {spell = 25120, enchant = 2625}, -- Lesser Mana Oil
    [20748] = {spell = 25123, enchant = 2629}, -- Brilliant Mana Oil
    [20749] = {spell = 25122, enchant = 2628}, -- Brilliant Wizard Oil
    [20750] = {spell = 25121, enchant = 2627}, -- Wizard Oil
    [22521] = {spell = 28013, enchant = 2677}, -- Superior Mana Oil
    [23122] = {spell = 28891, enchant = 3593}, -- Consecrated Sharpening Stone
    [23123] = {spell = 28898, enchant = 3592}, -- Blessed Wizard Oil
    [23528] = {spell = 29452, enchant = 2712}, -- Fel Sharpening Stone
    [23529] = {spell = 29453, enchant = 2713}, -- Adamantite Sharpening Stone
    [23559] = {spell = 32274, enchant = 2718}, -- Lesser Rune of Warding
    [25521] = {spell = 32282, enchant = 2791}, -- Greater Rune of Warding
    [25679] = {spell = 32426, enchant = 2795}, -- Comfortable Insoles
    [28421] = {spell = 34340, enchant = 2955}, -- Adamantite Weightstone
    [30696] = {spell = 37360, enchant = 3093}, -- Scourgebane
    [31535] = {spell = 38615, enchant = 3102}, -- Bloodboil Poison
    [34538] = {spell = 45395, enchant = 3265}, -- Blessed Weapon Coating
    [34539] = {spell = 45397, enchant = 3266}, -- Righteous Weapon Coating
    [36899] = {spell = 47904, enchant = 3298}, -- Exceptional Mana Oil
    [46006] = {spell = 64401, enchant = 3868}, -- Glow Worm
    [67404] = {spell = 98849, enchant = 4264}, -- Glass Fishing Bobber
    [68049] = {spell = 95244, enchant = 4225}, -- Heat-Treated Spinning Lure
}

---@type ClassicWeaponEnchants.SpellImbues
local tempEnchantSpells = {
    [8024] = { enchant = 5 }, -- Flametongue Weapon
    [8232] = { enchant = 283 }, -- Windfury Weapon
    [8033] = { enchant = 2 }, -- Frostbrand Weapon
    [29702] = { enchant = 2720 }, -- Greater Ward of Shielding
    [36503] = { enchant = 2655 }, -- Enchant Shield
    [35886] = { enchant = 3014 }, -- Windfury Weapon
    [8017] = { enchant = 3021 }, -- Rockbiter Weapon
    [51730] = { enchant = 3345 }, -- Earthliving Weapon
    [56308] = { enchant = 2713 }, -- Sharpen Blade
    [51320] = { enchant = 3289 }, -- Riding Crop (Test Version)
}

addon.ItemImbues = tempEnchantItems
addon.SpellImbues = tempEnchantSpells

