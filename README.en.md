# Air780E Modem for macOS

[简体中文](README.md) · English

Use an Air780EHV USB module for cellular Internet, SMS sending and an inbox on a Mac. The native Cocoa app includes its Python backend; users do not need Python, Homebrew or Xcode.

**0.9.6** adds Simplified Chinese (default), English and Traditional Chinese. Use the selector at the top. The choice persists and switching preserves the recipient, draft and current folder. Router V1.3 styling and sent-record deletion are retained. Phone calls and Apple notarization are **not** added.

Maker: **DJ Network (点击网络) · Stock code: 832571 · [www.DJ.cn](https://www.DJ.cn)**. Contact: **Cai Liwen (蔡立文) · cailiwen@dj.cn**. Maker information is supplied by the publisher, not investment advice or an endorsement.

## Compatibility and signing

**Apple Silicon, macOS 26+, Air780EHV_A11 / EC718HM only.** This independent community app is not a vendor product or universal Air780E driver. Never flash Air780E, Air780EHM, Air780EP or another model with this project's firmware.

The app is ad-hoc signed, **not Developer ID signed or Apple notarized**. Gatekeeper may block it. Verify the source and SHA-256 before using macOS's per-app approval flow. Never disable system security. A version/release label does not prove notarization or comprehensive validation.

## Installation and use

1. Download the Apple Silicon DMG from [Releases](https://github.com/DJ-cn-832571/Air780E-Modem/releases), open it and drag the app to Applications.
2. Connect one supported module, fit its antenna and insert a SIM with data/SMS service. Use stable USB power; some IoT SIMs provide data only.
3. If no matching protocol is found, check cable, power, model and Device status before considering firmware repair. Missing protocol alone does not prove missing firmware.
4. **Install / repair firmware**: check the marking and type `Air780EHV`. The first installation needs a separate working connection to download official core/tool assets and verify SHA-256. Flashing overwrites core/scripts, disconnects networking and may lose unsynced SMS; no original-firmware backup is made. Do not unplug.
5. **Start Internet / Stop Internet** changes module USB ECM, not the Mac's Wi-Fi, Ethernet or VPN. Link status follows the matched system AirM2M service, not merely the module switch.
6. For disabled AirM2M, **Enable adapter** enables only the matched USB system service and rechecks it. If permission is insufficient, **Network settings** offers manual activation. Activation is not proof of working ECM or Internet. Global routes, DNS and VPN are not changed.
7. Wait for **SMS ready**, enter the recipient and 1–500 characters, then confirm sending/charges. Ordinary Chinese, English and punctuation are supported; non-BMP characters such as emoji are rejected. Long SMS may be billed as multiple messages.
8. Inbox refreshes about every 15 seconds while the app runs. Select a message for details; **Reply** fills its sender number. Delete received messages into Deleted and restore them there. **Empty** permanently clears the entire Deleted folder after confirmation, including records outside the loaded list. It is not SIM clearing or secure disk erasure.
9. Sent results are Sending, Accepted, Failed or Unknown. Acceptance is not delivery; delivery receipts are unavailable. Failed records have **Resend**, requiring confirmation and preserving the old record. Unknown results are never automatically retried.
10. Each completed sent record has **Delete**. Check rows or use the header's select-all checkbox, then **Delete selected** at the bottom. Only the currently loaded list (up to 500) is selected; active sends are protected. Confirmed deletion permanently removes local history, cannot recall SMS and does not clear Inbox.
11. **Email forwarding** supports one SMTP sender and up to three destinations. Set server, port, username, sender, SSL (often 465) or STARTTLS (often 587) and a provider password/app password. Secrets use Keychain; blank keeps the existing password. **Save & test SMTP** tests encrypted login, not actual email delivery.
12. Forwarding is off by default, applies only to newly synced messages after enabling, and needs the app open/Mac online. It sends numbers, times and message bodies, possibly including verification codes. Use trusted addresses; view forwarding history in settings.
13. **Tasks & diagnostics** may show private details. **Diagnostics** instead copies sanitized version/system/interface/link information. One app instance runs to avoid serial-port contention.

## Signal and email behavior

Approximate RSRP bars: 5 at ≥ −85 dBm; 4 at −95 to −86; 3 at −105 to −96; 2 at −115 to −106; 1 for lower valid values. Invalid/unavailable values show unknown, never full signal. This is not a carrier standard. Updates are roughly every 15 seconds; hover to see RSRP.

SMTP uses certificate-verified SSL/STARTTLS. Passwords reach the local backend through an anonymous stdin pipe, not arguments/configuration. SMTP acceptance is not final delivery. Interrupted submission becomes unknown and is not automatically resent. Pre-submission connection failures use 1–15-minute backoff; authentication failure pauses attempts until corrected settings are saved. Updating may trigger a new Keychain permission prompt. Real delivery must be tested with your own mailbox.

## Validation and limitations

Earlier work verified bound ECM HTTPS and short Chinese SMS submission on one Air780EHV_A11. Offline tests, bundled-backend self-tests and native UI checks are not a complete hardware regression. Real SMTP/Keychain persistence, long SMS, cross-carrier use and other Macs require further validation. See bilingual verification/release documents.

- Roughly 100 incoming messages are cached in module RAM. Unsynced messages may be lost on restart. This is not an emergency communication device.
- A SIM may not store its own phone number; the app never infers it from IMSI/ICCID.
- Intel Macs, custom APN, PIN unlocking, concurrent modules and phone calls are unsupported.
- VPN may still control traffic. No automatic updates, telemetry or default cloud backup.
- First firmware downloads contact official CDN/GitHub; Internet checks contact connectivity-test services. Raw vendor logs, protocol data and user SMS retain their original content/language.

## Privacy

`~/Library/Application Support/Air780E Modem/` contains SQLite SMS/history, settings, operation locks and download caches. Release packages contain no user data. Local permissions protect the database, but there is no app-layer encryption; protect your account and consider FileVault. Uninstalling does not delete data or Keychain entries. Deletion does not erase backups, APFS snapshots or carrier/recipient records. Opaque incoming IDs may remain to prevent cached SMS from reappearing.

Do not upload SMS, numbers, IMEI, IMSI, ICCID, passwords, keys, databases or complete logs to Issues. Review screenshots and diagnostics before sharing.

## Build

Requires Apple Silicon/macOS 26+, Xcode Command Line Tools and Python 3.11+ (currently built with Python 3.14.6). Older macOS support requires a compatible runtime and tests, not merely a plist change.

```sh
python3 -m unittest discover -s src -p 'test_*.py'
bash scripts/build_macos.sh
bash scripts/package_release.sh
```

Backend: `src/backend_entry.py`; native UI/localization: `src/ModemApp.swift`, `src/CommercialUI.swift`, `src/Localization.swift`, `src/EmailSettings.swift`; device code: `firmware/lua/main.lua`. Builds do not flash devices/send SMS. `dist/<version>/` receives app ZIP, DMG, source ZIP and SHA256SUMS; the source archive is audited. Do not run `send_sms`/`install_firmware` without understanding charges and consequences.

## Bilingual documentation

- [0.9.6 release notes](docs/RELEASE-0.9.6.md) · [0.9.3 notes](docs/RELEASE-0.9.3.md)
- [Privacy](docs/PRIVACY.md) · [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Publishing](docs/PUBLISH.md) · [Protocol](docs/PROTOCOL.md) · [Verification](docs/VERIFICATION.md)
- [UI update](docs/UI-0.9.4.md) · [Sent deletion](docs/UPDATE-0.9.5.md)
- [Changelog](CHANGELOG.md) · [Security](SECURITY.md) · [Contributing](CONTRIBUTING.md) · [Third-party notices](THIRD_PARTY_NOTICES.md)

Project-owned code is MIT; upstream LuatOS Lua retains MIT. Proprietary cellular cores are vendor downloads, not redistributed or licensed under this project's MIT. Original dependency license texts are in `LICENSES/`.
