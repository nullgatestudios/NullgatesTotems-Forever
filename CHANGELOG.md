# Changelog

All notable changes to Nullgate's Totems - Forever.

## [1.0.0-beta.3] - 2026-11-21

### Fixed

- No more "Auras cannot be accessed when secret" error. While the game hides a party member's buffs from addons, the party buff tooltip shows them as unknown, and the out-of-range warning waits.

## [1.0.0-beta.2] - 2026-11-21

### Fixed

- No more error when the game hides a party member's range from addons. That player is treated as in range.
- Buffs the game hides from addons, usually in combat, are skipped instead of causing an error.

## [1.0.0-beta.1] - 2026-11-20

First test version, looking for shamans to try it.

### New

- **Earth, Fire, Water and Air buttons**: each drops your chosen totem at the highest rank you know. Right-click a button to choose from the totems you know.
- **Drop All**: one press per totem drops all four chosen totems.
- **Timers** on every button, using the Forever durations (most totems last 5 minutes there), read from the client data.
- **Party buffs**: for totems that buff your party, the button shows how many have the buff, and the tooltip lists who has it, who's missing it and who's out of range.
- **Warnings** when a totem is about to expire, is destroyed early or you're out of its range, as a chat line or a sound.
- **Weapon imbue button and reminder**: casts your chosen imbue (Rockbiter, Flametongue, Frostbrand or Windfury Weapon) at your highest rank, and reminds you when it's missing or under 5 minutes.
- **Totem sets**: `/ntotem save <name>` and `/ntotem set <name>` switch all four choices at once.
- **Key bindings** for every button under Key Bindings > AddOns.
- **Settings** in its own window or inside Nullgate's Addon Config.
- **`/ntotem check`**: tests what the addon needs in your client and reports what the game says each time you drop a totem. Results are saved for bug reports.
- Available in English, Deutsch, Español, Français, Italiano, Português (Brasil), Русский, 한국어, 简体中文 and 繁體中文.

### Good to know

- Buttons can't change during combat. A totem chosen mid-fight is set as soon as combat ends.
