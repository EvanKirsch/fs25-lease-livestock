# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

To package the mod for distribution:
```
git archive -o FS25_LeaseLivestock.zip HEAD
```

The zip is dropped directly into the FS25 mods directory (this repo lives there), so the game loads the mod from source during development — no install step needed.

## Running / Testing

There is no automated test suite. Testing is done by launching Farming Simulator 25 and observing behavior in-game. Logs appear in the game's log file.

## Architecture

This is a Farming Simulator 25 Lua mod. FS25 loads `modDesc.xml` first, which declares the source files in load order:

1. `src/events/LL_AnimalLeaseEvent.lua` — network event for leasing animals
2. `src/cluster/LL_AnimalClusterLeased.lua` — patches `AnimalCluster` to add `isLeased` state, savegame persistence, and network sync
3. `src/LL_LeaseLivestock.lua` — main mod object; wires up periodic charges and creates the Lease button at `loadMap()` time
4. `src/LL_FinanceStatsExt.lua` — registers the `livestockLeasingCost` money type and finance stat
5. `src/gui/LL_AnimalScreen.lua` — patches `AnimalScreen` to show the Lease button and leased labels
6. `src/gui/LL_AnimalScreenDealer.lua` — adds lease logic to `AnimalScreenDealer` and `AnimalScreenDealerFarm`
7. `src/gui/LL_InGameMenuAnimalsFrame.lua` — patches `InGameMenuAnimalsFrame` to show leased labels in the animals overview

### Data model

Lease state lives directly on `AnimalCluster` via the `isLeased` boolean field, patched in `LL_AnimalClusterLeased.lua`. There is no separate lease registry. The lease rate is `ceil(buyPrice / 24)` where `buyPrice` is the buy price for a single animal at age 18 (`getAnimalBuyPrice(subTypeIndex, 18)`). Periodic charges multiply the per-animal rate by `cluster.numAnimals`. Savegame persistence is handled via the `AnimalCluster` XML save/load patches.

### Network flow

FS25 uses a client-authoritative request / server-validates pattern via `Event` subclasses:

- **Client --> Server**: `writeStream` serializes the request fields; `readStream` on the server deserializes and calls `run(connection)`.
- **Server --> Client**: `run` on the server validates, acts, then sends a reply event with only an `errorCode`; `run` on the client publishes the error code via `g_messageCenter` so the screen can update.
- Both events use `connection:getIsServer()` to branch read/write/run behavior within a single class.

### GUI integration constraint

`g_animalScreen` is constructed in FS25's `main.lua` before any mod `extraSourceFiles` are loaded, so `onGuiSetupFinished` has already fired. The Lease button is therefore cloned from `buttonBuy` in `LL_LeaseLivestock:loadMap()` (called by the engine after map load), not in the GUI file. `LL_AnimalScreen.lua` only adds behavior (overwritten functions and callbacks) — it never constructs widgets.

### Lua environment

The GIANTS engine Lua stub library is referenced in `.luarc.json` as a workspace library so the language server resolves FS25 globals (`g_currentMission`, `AnimalScreen`, `Event`, `Class`, etc.). The actual game runtime provides these globals; the stubs are for IDE support only.

## Translations

String keys are defined in `translations/translation_en.xml` (and `translation_de.xml`). All user-facing strings go through `g_i18n:getText("ll_<key>")`. Confirmation dialog text uses `string.namedFormat` with named placeholders (`{numAnimals}`, `{animalType}`, `{rate}`, `{totalRate}`).
