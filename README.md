# Actell ESP32 build workspace

Build-only helpers for the public upstream project `ja1chen/actell`, pinned to
`55234856b8cb6fc114c0ca2674cd7bd420b1654c`.

The manual GitHub Actions workflow builds an **unsigned** iOS 27 IPA and an
ESP32-S3 USB NCM firmware image. The IPA still needs local Apple signing before
installation. Builds do not contain Apple credentials, pairing records, device
identifiers, API keys, or local screenshots. Only these build helpers are pushed.

Run manually with target `all`, `ios`, or `firmware`. The iOS job uses the
standard `xcode-27` runner, never the paid larger `xcode-27-xlarge` label.
Private-repository runner usage can consume the account's included minutes;
public-repository standard runners are covered by GitHub's free public usage.
No workflow runs automatically on push. Each job has a time limit and artifacts
expire after seven days.

Upstream software is GPL-3.0-only. Each artifact includes its license, exact
source archive, revision, and SHA-256 manifest. No product code is modified.
Neither successful compilation nor artifact creation proves device operation.

Local validation: Bash syntax for both scripts and YAML structure validation.
Real build validation occurs in the manually requested workflow. Final device
acceptance requires installing the app, flashing the verified S3, configuring
the provider on the phone, and observing a task with the laptop disconnected.
