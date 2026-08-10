# :cow: LL - Farming Simulator 25 Lease Livestock
(WIP - [prerelease download](https://github.com/EvanKirsch/fs25-lease-livestock/releases/latest))
Lease livestock from animal dealers instead of buying outright. Leased animals appear in separate sections on the animal screen and are tracked on the finances screen under "Livestock Leasing". Lease payments are charged each in-game period.

![screenshot 1](https://github.com/EvanKirsch/fs25-lease-livestock/blob/master/screenshots/Screenshot_1.png)

## :spiral_notepad: Implementation Details

### Buy/Lease Mode Toggle
The animal screen's buy tab gets a mode toggle button (default hotkey: Left Shift) next to the normal Buy button.
- **Buy Mode** : The default behavior - animals are purchased outright at full price.
- **Lease Mode** : Every animal card in the list shows its lease rate per period instead of its buy price, and the Buy button becomes a Lease button that leases the selected animals into the barn instead of buying them.

### Terminating a Lease
Leased animals are tagged "(Leased)" everywhere they appear - the sell list, the info box, and the in-game menu's Animals overview. Selling a leased animal terminates the lease instead: the Sell button becomes a "Terminate Lease" button, and confirming refunds the current period's lease fee with no transport fee deducted.

## :gear: Manual Install Instructions
1. Download `FS25_LeaseLivestock.zip` from the [latest release](https://github.com/EvanKirsch/fs25-lease-livestock/releases/latest) on the releases page
1. Move your downloaded copy of `FS25_LeaseLivestock.zip` to `Documents\My Games\Farming Simulator 2025\mods`

## :hammer_and_wrench: Manual Build Instructions
`git archive -o FS25_LeaseLivestock.zip HEAD`

## :rocket: Release
Create and push a tag on the desired release commit following the pattern `[0-9]+.[0-9]+.[0-9]+.[0-9]+`

```bash
git tag <tagname>
git push origin <tagname>
```
