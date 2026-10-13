# Windows Defender Disable/Restore Scripts

Scripts for permanently disabling Windows Defender on an **isolated test/malware-analysis VM**.
Based on the method described by IT-Connect: https://www.it-connect.fr/comment-desactiver-windows-defender-sur-windows-11-ou-windows-10/

**For isolated test VMs only.** Never run this on a production or internet-connected machine.
Take a VM snapshot before you start.

## Why multiple scripts?

Windows protects Defender's core services with Tamper Protection and PPL (Protected Process Light), so disabling it requires several steps in a specific order — some of which only work in Safe Mode.

## Files

| Order | Script | Run in | Purpose |
|---|---|---|---|
| — | `0-check-defender-status-en.ps1` | Normal mode, any time | Read-only checkup: Tamper Protection, real-time protection, service states, GPO keys, scheduled tasks |
| 1 | `1-disable-defender-gpo-tasks-en.ps1` | Normal mode | Applies GPO-equivalent registry keys + disables Defender's 4 scheduled tasks |
| 2 | `2-disable-defender-services-en.ps1` | **Safe Mode only** | Sets Defender's services/drivers (`WinDefend`, `WdFilter`, etc.) to disabled — fails outside Safe Mode |
| 3 | `3-restore-defender-services-en.ps1` | **Safe Mode** (for services) | Reverts everything: restores services, removes GPO keys, re-enables tasks |

## How to use

1. Manually turn off **Tamper Protection** first (Windows Security > Virus & threat
   protection > Manage settings). Nothing else works until this is off.
2. Run `1-disable-defender-gpo-tasks-en.ps1` as Administrator, in normal boot mode.
3. Reboot into **Safe Mode** (`msconfig` > Boot tab > Safe boot > Minimal).
4. Run `2-disable-defender-services-en.ps1` as Administrator.
5. Uncheck Safe boot in `msconfig`, reboot normally.
6. Run `0-check-defender-status-en.ps1` any time to confirm the current state.

To undo everything, run `3-restore-defender-services-en.ps1` (reboot into Safe Mode for the services part), then manually re-enable Tamper Protection and real-time protection in Windows Security.

## Important caveat

This is **not a permanent fix**. Microsoft documents this as intentional: Tamper Protection can silently re-enable itself after a Windows Update (and sometimes even after a normal reboot on some builds), which restores Defender's services and re-enables protection. Re-check the state after every major update, or just restore a clean snapshot before each test run — that's the most reliable approach anyway.
