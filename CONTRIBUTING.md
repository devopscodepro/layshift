# Contributing

Thanks for wanting to help! Bug reports, translations and small focused pull requests are the most useful.

## Before you start

- For anything bigger than a small fix, open an [issue](https://github.com/devopscodepro/layshift/issues) or an [Ideas discussion](https://github.com/devopscodepro/layshift/discussions/categories/ideas) first, so we can agree on the approach.
- LayShift stays small on purpose: no dependencies, no network, no privileged helpers, no text autocorrection. Features that need any of those are unlikely to be merged.

## Branches

- `dev` is where work happens. **Open pull requests against `dev`.**
- `main` only gets tested releases, each one tagged `vX.Y.Z`.

## Building and testing

You need Xcode 16 or later, no Apple Developer account.

```sh
xcodebuild -project LayShift.xcodeproj -scheme LayShift -derivedDataPath build build
xcodebuild -project LayShift.xcodeproj -scheme LayShift -derivedDataPath build test
open build/Build/Products/Debug/LayShift.app
```

Logs are in Console.app, or:

```sh
log stream --predicate 'subsystem == "pro.devopscode.LayShift"' --info
```

## Code

- Swift 6, AppKit for the menu bar, SwiftUI for Settings.
- Keep types small and the logic testable — the core (`ModifierTapDetector`, `InputSourceStore`, `Shortcut`, `SettingsStore`) is covered by unit tests, please add tests for changes there. Anything touching Carbon or the event tap goes behind a protocol so it can be mocked.
- Comments only where the *why* isn't obvious.
- No new warnings.

## Commits and changelog

- Small commits, one change each, short imperative subject: `Fix timer not cancelled on manual off`.
- Add a line to `CHANGELOG.md` under `[Unreleased]` for anything users will notice.

## Translations

All strings live in `LayShift/Resources/Localizable.xcstrings`. The easiest way to add or fix a language is to open the project in Xcode, select the string catalog and fill in the column for your language. Keep placeholders like `%@` and `%lld` exactly as they are.

Currently: English and Russian.

## License

By contributing you agree that your work is released under the [MIT License](LICENSE).
