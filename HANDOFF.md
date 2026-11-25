# Machine-to-machine handoff

Repository: https://github.com/VicenteVidela/pocket-terminal

## Purpose

Android-only Flutter starter for an SSH terminal that another developer can
adapt. It is intentionally independent of any household, server, hostname,
credential, service API, tower or notification infrastructure.

## Current behavior

`lib/main.dart` contains a single connection screen and terminal. It opens a
password-authenticated SSH shell via dartssh2 and renders it with xterm.
Host keys are confirmed on first use and pinned per hostname and port via
flutter_secure_storage; changes are rejected. Passwords are not persisted;
Android backup is disabled. Disconnect closes the shell and the terminal buffer
is replaced before another connection. The generated release configuration has
no signing key. Project code is MIT licensed; dependencies have separate licenses.

## Build and use

Prerequisites: Flutter 3.44.4 (Dart 3.12.2), JDK 21 and Android SDK. Run:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run
```

Use a disposable SSH server that accepts passwords. Enter host, port, username
and password; compare the displayed host-key fingerprint with a trusted source.
The disconnect icon closes the connection. Clearing Android app data removes
pins. Debug builds are not suitable for distribution. Configure your own
application ID, branding and release signing for a derived app.

## Verification and limitations

The debug APK builds and a widget test checks missing-input validation. Neither
an end-to-end SSH test nor a physical-device test has been completed. There is
no independent security audit. Credentials can be visible in screenshots; do not
use sensitive credentials until credential-screen capture protection is added
and tested. This is password-only, single connection, no profile persistence,
key authentication, tmux integration, file browser, background service,
auto-reconnect, host-key rotation UI, or terminal shortcut bar. A lost connection
does not restore a shell. Android lifecycle behavior is not established.

## Recommended next steps

1. Add automated real-SSH tests for authentication, rejection, key pin reuse,
   changed keys, terminal input/output, disconnect and failure cleanup, using an
   isolated temporary server. Exercise lifecycle and keyboard behavior on Android.
2. Add credential-screen capture protection and test it on real devices; add SSH
   key authentication and secure, user-configurable profiles.
3. Add optional tmux session inventory/reattachment and an SFTP browser, with
   explicit destructive-action confirmation and thorough integration tests.
4. Review dependencies and attribution, privacy, accessibility, Android release
   signing, security, and product naming before distributing binaries.

Do not add real hosts, tokens, private keys, screenshots containing personal
information or local configuration to the repository or its Git history.
