# Nullgate's Totems - Forever

> **Status: planning.** No code yet. See [PLAN.md](PLAN.md).

**Nullgate's Totems** is a shaman addon for **World of Warcraft: Forever**. Four element buttons drop the totems you choose at your highest rank, with timers, a party range list and a weapon imbue reminder.

Totem durations come from the Forever client, where most totems last 5 minutes instead of Classic's 1 to 2.

---

## How It Works

1. **Choose a totem for each element**: right-click or hover an Earth, Fire, Water or Air button to pick from the totems you know.
2. **Click a button** (or press its key binding) to drop that totem at your highest rank, or use **Drop All** to place all four, one press per totem.
3. **Watch the timers**: each button shows the time left on its totem and warns you before it expires.

Buttons can't change in combat, so a totem chosen mid-fight is set as soon as combat ends.

---

## Features

- **Element buttons** with a choice flyout, key bindings and a movable bar.
- **Drop All** button for your four chosen totems.
- **Totem timers** and warnings when a totem is about to expire, is destroyed early, or you've moved out of its range.
- **Party range list**: for totems that buff your party, see who has the buff and who is out of range.
- **Weapon imbue reminder** for Rockbiter, Flametongue, Frostbrand and Windfury Weapon.
- **Totem sets**: save sets such as "Raid melee" or "Fire resist" and switch all four choices at once.
- **Settings** in its own window or inside Nullgate's Addon Config.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/ntotem` or `/totems` | Open the settings. |
| `/ntotem set <name>` | Switch to a saved totem set. |
| `/ntotem lock` / `/ntotem unlock` | Lock or unlock the bar. |
| `/ntotem reset` | Reset the bar's position. |
| `/ntotem check` | Test what the addon needs in your game client and save the results. |

---

## Installation

Not released yet. Once it is:

1. Download the latest release from CurseForge or the GitHub releases page.
2. Extract the `NullgatesTotems-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a shaman and type `/ntotem`.

---

## Part of the Nullgate Addon Suite

- **Nullgate's Addon Config**: one settings hub and profile manager for the whole suite.
- **Nullgate's Raid Buffs**, **Cooldowns**, **Restock**, **Quest Tracker** and more.

---

## License

Source-available, all rights reserved. See [LICENSE.md](LICENSE.md).
