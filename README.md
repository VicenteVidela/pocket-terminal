# Pocket Terminal (working title)

Early, general-purpose Android SSH client skeleton for developers to adapt.
It is not security-audited or ready for sensitive systems.

## Current prototype

- One password-authenticated SSH shell with an xterm terminal and disconnect.
- SSH host-key confirmation on first connection; changed keys are rejected.
- Host-key pins are stored using Flutter secure storage. Passwords are not saved.
- Android backups are disabled.

This is not yet feature parity with the original private app. It has not been tested on a
physical Android device or audited for security. In particular, credential-entry
screenshot protection, key authentication, profile management and host-key
rotation are not yet implemented. Disconnects do not resume shells.

## Development

Tested build toolchain: Flutter 3.44.4 / Dart 3.12.2, JDK 21 and Android SDK.
Run `flutter pub get`, `flutter analyze`, `flutter test`, and
`flutter build apk --debug`. Run on an Android device with `flutter run`.
Use an isolated test server with password authentication enabled, and verify
its SSH host fingerprint through a trusted channel before accepting it. Enter
the host, port, username and password, then connect. The disconnect icon closes
the current shell. Pins survive app restarts; clearing app data removes them.
The debug APK is not a release: configure your own release signing separately.

## Road to a public release

1. Test SSH authentication, pinning, rejected and changed host keys with a
   disposable SSH server; test keyboard, resize and disconnects on Android.
2. Add protected credential entry, key authentication and configurable profiles.
3. Port and adapt the existing terminal improvements, tmux session browser and
   SFTP file browser, with tests and no household-specific defaults.
4. Review third-party dependency licenses and create appropriate attribution
   and user documentation.
5. Audit all tracked files, generated artifacts and history for secrets and
   identifying details; use synthetic examples. Review before publication.

Household-specific integrations are not part of this project. No code or data
needs to be synced from any private repository. See `HANDOFF.md` for a concise
developer-to-developer handoff. Project code is MIT licensed; dependencies
retain their own licenses.
