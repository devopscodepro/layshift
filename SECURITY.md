# Security

## Reporting a vulnerability

Please don't open a public issue for security problems. Report them privately through [GitHub's private vulnerability reporting](https://github.com/devopscodepro/layshift/security/advisories/new) instead.

Include what you found, how to reproduce it and what an attacker could do with it. I'll get back to you as soon as I can, usually within a few days, and keep you posted until it's fixed. If you'd like to be credited in the release notes, say so.

## Supported versions

Only the latest release gets security fixes. LayShift updates are small, so please update before reporting.

## What LayShift can and can't do

It helps to know the boundaries when judging an issue:

- The app runs with the Hardened Runtime and has no network access. It is not sandboxed, because the event tap it needs for modifier-only shortcuts is not available to sandboxed apps.
- With the Input Monitoring permission it listens to modifier keys (⌃ ⌥ ⇧ ⌘ fn) and to the fact that some other key or mouse button was pressed, to tell a shortcut from normal typing. It never reads which keys you type and never records anything.
- With the Accessibility permission it presses the system "previous input source" shortcut after switching to an input method. That is the only event it ever posts.
- It changes keyboard layouts through the public Text Input Sources API. It never runs scripts, never asks for admin rights and has no privileged helper.
- Settings are stored in the app's user defaults.
