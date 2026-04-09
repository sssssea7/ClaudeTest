# PikachuPet — Setup (5 minutes)

The Swift sources are ready. Xcode project files are intentionally not generated (the `.pbxproj` format is fragile to hand-edit). You'll create a fresh Xcode project and drag the sources in.

## 1. Make the Xcode project
1. Open **Xcode** → *File ▸ New ▸ Project…*
2. Choose **macOS ▸ App** → **Next**.
3. Product Name: `PikachuPet`. Interface: **SwiftUI**. Language: **Swift**. Uncheck tests/Core Data. **Next** → save it inside this `PikachuPet/` folder (let Xcode create its own subfolder; it's fine to overwrite or merge).

## 2. Replace the boilerplate sources
In Finder, delete the `ContentView.swift` and `PikachuPetApp.swift` Xcode created. Then in Xcode, right-click the `PikachuPet` group → **Add Files to "PikachuPet"…** and add all six files from this folder's `PikachuPet/` subdirectory:

- `PikachuPetApp.swift`
- `AppDelegate.swift`
- `PetModel.swift`
- `PetState.swift`
- `PetView.swift`
- `SpriteView.swift`

## 3. Set `LSUIElement` so there's no Dock icon
In the project's target → **Info** tab → add row **Application is agent (UIElement)** = **YES**. (Or replace the generated `Info.plist` with the one in this folder.)

## 4. (Optional) Add real Pikachu sprites
Without sprites the app runs and shows a ⚡ emoji placeholder. To use real art:
1. Grab PNGs from https://pokemondb.net/sprites/pikachu (right-click → save image).
2. In Xcode open `Assets.xcassets` → drag the PNGs in and rename them:
   - `pikachu_idle`
   - `pikachu_eat`
   - `pikachu_play`
   - `pikachu_sleep`

Naming matters — `SpriteView.swift` looks them up by these exact names.

## 5. Run
Press **⌘R**. A small Pikachu floats near the top-right of your screen. Right-click him for **Feed / Play / Reset / Quit**. Drag him anywhere.

## Tuning
Stat decay rates and the sleep/wake thresholds live at the top of `PetModel.swift`. Tweak to taste.
