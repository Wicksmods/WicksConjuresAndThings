# Wick's Conjures and Things - Changelog

## Unreleased

### Portals and teleports

- A panel of every destination you can reach, left-click to teleport and
  right-click to open the portal. Read out of your own spellbook rather
  than a list of cities written into the addon: Forever is Classic plus
  its own changes, so a hardcoded list would be a guess, and reading the
  book gets faction right without asking.
- Teleport and portal rune counts in the header, and a destination whose
  rune has run out is dimmed, since that is what actually stops the cast.
- Rune rows join the pre-pull checklist as the spells do. A mage below
  twenty has no teleports and one below forty has no portals, so neither
  row sits there grey for twenty levels.
- Open it with /wcj portals, the Portals button on the rations panel, a
  middle-click on the minimap button, or a keybind.

## 0.9.0

One version across the suite for the Forever beta. Every addon carried a
number of its own that said nothing about how finished it was, so they are
aligned here and the suite goes to 1.0.0 together at launch.

## 0.1.0 - 2026-09-19 (Forever, beta)

### First cut of the mage kit on WickCore

- Requires WickCore. Interface 16001.
- Rations at a glance: every conjured item in your bags, counted, with a
  low mark you set. Found by name rather than a table of item IDs, so
  every rank counts and a changed ID does not break it.
- A conjure key for water and one for food, plus the mana gem, each
  bound to the best rank you know.
- Reagent watch: arcane powder and the teleport and portal runes, amber
  when they run low.
- Compact strip: rations, gem and powder on one row. Click a segment to
  conjure, right-click for the full panel.
- Talents, a five row pre-pull checklist (armor, Arcane Intellect, water
  and food, a gem, powder), racials and the cooldown bar.
