# Quick Build · iOS (Hotwire Native shell)

This is the iOS shell for Quick Build. It is intentionally minimal — five tabs
backed by [`hotwire-native-ios`](https://github.com/hotwired/hotwire-native-ios),
each pointing at a Rails URL. All UI comes from the Rails backend (variant
`:mobile`); the shell only contributes the native nav/tab chrome and the
`Hotwire Native` user-agent suffix.

## What's in this directory

```
ios/
├── README.md                       ← this file
└── QuickBuildMobile/
    ├── AppDelegate.swift           ← Hotwire.config + path-configuration load
    ├── SceneDelegate.swift         ← installs MainTabBarController
    ├── MainTabBarController.swift  ← 5 tabs (Inicio · Proyectos · Buscar · Biblio · Perfil)
    ├── AppEnvironment.swift        ← backend URLs (override via Info.plist QB_BASE_URL)
    ├── Info.plist
    └── path-configuration.json     ← offline fallback; the live config lives at /configurations/ios_v1
```

There is intentionally **no `.xcodeproj`** checked in — create it locally in
Xcode and add these source files. See the setup steps below.

## Setup

1. **Create the Xcode project**
   - Xcode → File → New → Project → iOS · App
   - Product Name: `QuickBuildMobile`
   - Interface: Storyboard (we drop the main storyboard in step 3)
   - Language: Swift
   - Save it inside `ios/` (so the project sits at `ios/QuickBuildMobile.xcodeproj`)
2. **Add the Hotwire Native package** (File → Add Package Dependencies)
   - URL: `https://github.com/hotwired/hotwire-native-ios`
   - Up to next major from `1.0.0`
3. **Wire the source files**
   - Delete the generated `Main.storyboard` and the `Main storyboard file base name`
     entry from Info.plist (we use `SceneDelegate.swift` directly).
   - Add every `.swift` file from `ios/QuickBuildMobile/` to the target.
   - Replace the generated `Info.plist` with the one in this folder, or merge
     `QB_BASE_URL`, the `UIApplicationSceneManifest`, and
     `NSAppTransportSecurity` keys into yours.
   - Add `path-configuration.json` to the target's *Copy Bundle Resources*
     phase so the offline fallback ships with the app.
4. **Run**
   - Pick an iPhone 15 simulator and ⌘R. The first launch hits
     `http://localhost:3000/configurations/ios_v1`, builds the navigator
     rules from it, and routes each tab to its Rails URL.
   - Physical devices on the LAN: set the user-defined build setting
     `QB_BASE_URL` to `http://<your-mac-lan-ip>:3000`.

## How it talks to the backend

- **UA suffix.** `AppDelegate` sets `Hotwire.config.applicationUserAgent` to
  start with `"Hotwire Native iOS;"`. Rails' `hotwire_native_app?` helper
  matches `/(Turbo|Hotwire) Native/`, which flips `request.variant` to
  `:mobile` in `ApplicationController#set_mobile_variant`. From there every
  view with a `*.html+mobile.erb` template (or a per-controller layout
  switch) renders the mobile design.
- **Path configuration.** `Hotwire.loadPathConfiguration` reads both the
  bundled `path-configuration.json` (offline fallback for cold boots) **and**
  `/configurations/ios_v1` (authoritative — edit it in Rails to roll out new
  modal/navigation rules without shipping an app update). The existing
  `ConfigurationsController#ios_v1` already returns the modal/clear-all
  rules the shell expects.
- **Modal sheets.** URLs ending in `/new`, `/edit`, or containing `/modal`
  are presented as `form_sheet` modals; that matches the prototype's
  bottom-sheet pattern for new-expense, new-note, new-stage, etc. The
  modal's content is just a regular Turbo Frame — Rails returns the same
  `index.html+mobile.erb` and the navigator wraps it in a sheet.

## Next steps (Rails side)

Once the shell is running and the Rails server returns 200 for the dashboard
URL, start creating mobile templates in this order:

1. `sessions/new.html+mobile.erb` (sign in)
2. `registrations/new.html+mobile.erb` (sign up)
3. `constructors/dashboard/index.html+mobile.erb` (KPIs + activity)
4. `constructors/projects/{index,show}.html+mobile.erb`
5. Stages list/detail
6. Materials list/detail
7. Modals (new stage / new list / expense / note / new project)
8. Search · Library · Profile
9. Blueprints · Team · Documents

Each template uses the `Qb::Mobile::*` ViewComponents and is wrapped in
`layouts/mobile.html.erb`, which is selected automatically because of the
variant.
