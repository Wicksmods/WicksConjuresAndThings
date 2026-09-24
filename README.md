# Wick's Conjures and Things

> Mage loadout kit for World of Warcraft: Forever. Rations and reagents at a glance, one-key conjuring, portals and teleports, talents, pre-pull checklist, racials.

Part of the **[Wick suite](https://github.com/Wicksmods/WickSuite)**: precision addons built around a single fel-green-on-deep-purple aesthetic. Built on [WickCore](https://github.com/Wicksmods/WickCore).

## What it is

A mage's setup is stock. Water, food, a gem, an armor spell, and the
powder and runes the group spells eat. All of it is counting and casting
out of combat, which is exactly the kind of work Forever still allows.

- **Rations.** Every conjured item in your bags, counted, with a low mark
  you set. They are found by name rather than a table of item IDs, so
  every rank counts and a changed ID cannot break it.
- **Conjure keys.** One for water, one for food, and the mana gem, each
  bound to the best rank you know and rebound as you learn better ones.
- **Reagents.** Arcane powder and the teleport and portal runes, amber
  when they run low.
- **Portals and teleports.** Every destination you know, in one panel.
  Left-click a row to teleport, right-click to open the portal for the
  group. The list is read out of your own spellbook rather than a table
  of cities, so it is the places you actually have and never the other
  faction's. Rune counts along the top, and a destination whose rune has
  run out is dimmed.
- **Compact strip.** Rations, gem and powder on one row, meant to stay on
  screen. Click a segment to conjure, right-click for the full panel.
- **Talents.** Export, import, save and apply builds through Blizzard's
  own parser.
- **Pre-pull checklist.** Armor, Arcane Intellect, water and food, a gem,
  powder, and the teleport and portal runes once you have learned the
  spells that spend them. Rows go quiet the moment combat starts.
- **Racials** and the shared **cooldown bar**.

## Install

Requires **[WickCore](https://github.com/Wicksmods/WickCore)**. Extract both
folders into the Forever client's `Interface\AddOns\`.

## Usage

Bind **Conjure water**, **Conjure food**, **Toggle rations panel** and
**Toggle portals panel** under Key Bindings, AddOns. A middle-click on the
minimap button opens the portals too.

| Command | Effect |
|---|---|
| `/wcj` | Rations panel |
| `/wcj kit` | Talents, checklist, racials |
| `/wcj portals` | Teleports and portals |
| `/wcj cd` | The cooldown bar |
| `/wcj strip` | Show or hide the compact strip |
| `/wcj low <count>` | Rations read as low under this |
| `/wcj status` | Diagnostics |

`/wconjures` is an alias.

## Compatibility

World of Warcraft: Forever, 1.60.x, Interface 16001. Requires WickCore.

## License

MIT for code (see [LICENSE](LICENSE)). Brand chrome and the "Wick's" wordmark are trademarked, see [TRADEMARK.md](https://github.com/Wicksmods/WickSuite/blob/main/TRADEMARK.md). Racial data from [talentsforever.com](https://talentsforever.com) (CC BY 4.0) via WickCore.
