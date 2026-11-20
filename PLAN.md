# Nullgate's Totems - Forever: Plan

Status: planning, with no code written yet. Planned on 2026-11-20.

- **Folder:** `NullgatesTotems-Forever`
- **Saved variables:** `NullgatesTotemsDB` (per character)
- **Commands:** `/ntotem` and `/totems`

## Decisions made

- Shaman only: the addon stays off for other classes.
- Totem data (every totem and rank, element, duration, level, the party buff it gives) is generated from Forever client data (wago.tools), never typed by hand.
- Ships as 1.0.0-beta.1 for testers.

## Forever durations (client build 1.60.1.70532)

| Totem | Forever | Classic |
| :--- | :--- | :--- |
| Strength of Earth, Stoneskin, Tremor | 5 min | 2 min |
| Grace of Air, Windfury, Windwall | 5 min | 2 min |
| Mana Spring, Healing Stream | 5 min | 1 min |
| Fire, Frost and Nature Resistance | 5 min | 2 min |
| Flametongue Totem, Poison Cleansing, Disease Cleansing | 5 min | 2 min |
| Sentry | 5 min | 5 min |
| Earthbind, Grounding | 45 sec | 45 sec |
| Searing | 30 to 55 sec by rank | same |

Weapon imbue durations are decided by the server, not the client files, so the imbue reminder reads them live with `GetWeaponEnchantInfo()`.

## The constraint that shapes the design

Each element button is a **secure button** with its totem set in advance; the totem can only change **out of combat**. Drop All is a `/castsequence` macro of the four chosen totems with a short reset, rebuilt out of combat whenever a choice changes.

---

## Phase 0: Repo and checks

- Repo, README, plan, license, logo, CurseForge workflow, `/zips` packaging, tests.
- `/ntotem check` in-game self test. Confirm in the Forever client:
  - `GetTotemInfo(slot)` and `PLAYER_TOTEM_UPDATE`. If missing, timers come from tracking your own totem casts.
  - `/castsequence` in a secure macro button.
  - Totem buffs show on party members through their auras.

## Phase 1: Totem data

- Generator script: every totem by element and rank, with duration, level and party buff.
- Unit tests for picking the highest known rank.

## Phase 2: Buttons

- Four element buttons with flyout choice, key bindings, movable and lockable bar.
- Drop All button.

## Phase 3: Timers and range

- Timers with cooldown sweep; expiry, early-destroy and out-of-range warnings.
- Party range list for buff totems (greyed out when out of range).

## Phase 4: Imbues, sets, settings, languages, beta

- Weapon imbue reminder (missing or under a set time).
- Saved totem sets.
- Settings window and Nullgate's Addon Config page; the 10 client languages.
- DESCRIPTION.md, CHANGELOG.md, 1.0.0-beta.1.
