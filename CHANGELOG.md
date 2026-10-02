# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Menu bar app that switches keyboard layouts with shortcuts. The menu shows the current layout, Settings… and Quit.
- Next layout shortcut chosen from a list: ⌃⇧, ⌥⇧, ⌘⇧, ⌃⌥, a single modifier, the right ⌘ or ⌥, fn/Globe, or a custom one. Presets work with either side of the keyboard.
- A shortcut per layout on the Layouts tab: keys like ⌥1, or modifiers pressed and released on their own, with left and right told apart.
- Input methods such as Hiragana or Pinyin take effect in the front app right away, which plain switching does not guarantee on macOS.
- Layouts tab follows the system: add or remove an input source in System Settings and the list updates.
- Launch at Login and an option to hide the menu bar icon. Opening the app again brings Settings back.
- Permissions are requested when a shortcut needs them, with their status shown in Settings.
- Settings warn when the fn/🌐 key is also used by macOS, point to the system Caps Lock option, and explain how to get back after hiding the menu bar icon.
- The menu says when secure input (a password field) pauses the shortcuts.
- App icon and menu bar glyph.
- Russian localization.
- MIT license
- Changelog
