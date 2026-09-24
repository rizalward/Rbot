# TerraformЯ · engine + save law
**HARDCODE · Decider · Utah 2026-09-24 13:54 America/Denver**

One world. Online and offline are two radios on the same planet, not two planets.

## Law

1. **Same game engine** for online TerraformЯ and offline TerraformЯ.
   - One simulation / world loop / entity schema.
   - Network is a nerve. Airplane still runs the same engine.
   - Do not ship a web-only engine and a native-only engine that diverge.
2. **Compatible save format** across online and offline.
   - One world file (or a versioned family that always migrates forward).
   - A player who walks offline, then online, lands in the *same* world.
   - Split saves = split worlds = forbidden.
3. **BLUEFACE** is the permanent entry point to TerraformЯ.
   - Existing BLUEFACE icon stays the door.
   - Tap BLUEFACE → enter the world (engine + save).
   - Do not invent a second launcher tile for the same world.
4. **Smart Bar** (magic smart redwood bar) stays the interface that connects ЯBOT functions.
   - Talk, Garage, mint, vault, housed bots, later functions ride the bar.
   - Smart Bar is not the world door. BLUEFACE is.
   - Garage button remains upper-left on the bar (workshop / ability space).

## Seats (same engine, same save)

| Seat | Radio | Engine | Save |
|------|-------|--------|------|
| Mac RIZALBOT | online optional | TerraformЯ engine | same format |
| iOS ЯBOT | airplane first | same | same |
| Android ЯBOT | airplane first | same | same |
| Pages / rizal.info | preview / door chrome | must not fork a second sim | must not write an incompatible world |

Heart (GGUF) is the mouth. TerraformЯ engine is the world. Do not seat Grok as either.

## Save contract (v0 seed — fill fields, do not fork)

Working name: `terraformya.save.json` (or binary sibling with the same header).

Minimum header every seat must read:

```json
{
  "kind": "terraformya.save",
  "format": 1,
  "world_id": "",
  "updated": "",
  "engine": "terraformya",
  "engine_rev": "0.1",
  "offline_ok": true,
  "player": {},
  "chunk": {}
}
```

- `format` only increases. Readers must load `format <= current` and migrate.
- `world_id` is stable across radios. Never mint a second id because the radio changed.
- Online sync is optional replay / merge onto this file. It does not own a different schema.

## UI map

```
BLUEFACE icon  ──enter──►  TerraformЯ world (engine + save)
Smart Bar      ──bus──►    ЯBOT functions (Garage, talk, mint, vault, Scout, ЯMAX, …)
Garage button  ──room──►   workshop / create bots / shelf figures
Heart          ──mouth──►  local generate (not the world file)
```

## Refuse

- Two engines “just for web.”
- Cloud save that cannot open on airplane.
- Airplane save that online refuses.
- Replacing BLUEFACE with a generic Play / Store icon.
- Turning the Smart Bar into the game HUD / world door.
- Merging Rbot and PROJECTR trees to “solve” this. Essence + this save file is the handoff.

## Next (not done this stamp)

- Name the engine impl on Neo (folder + crate / target).
- Stamp `format: 1` reader on Mac · iOS · Android.
- Wire BLUEFACE tap → engine boot + last `world_id`.
- Keep Smart Bar chrome above the world; do not bury functions inside the terrain.
