# Troubleshooting / Xử lý Sự cố

---

## 1. Gatekeeper Warning on First Launch (`"SnapLine" cannot be opened...`)

**Why it happens:** SnapLine is an open-source application signed ad-hoc (`codesign --sign -`), without a paid Apple Developer ID notarization certificate.

**Fix (Terminal — fastest):**
```bash
xattr -cr /Applications/SnapLine.app
```
**Fix (GUI):**
1. Right-click (Control-click) `SnapLine.app` → **Open**.
2. If blocked, go to **System Settings → Privacy & Security**, scroll down to **Security**, and click **Open Anyway**.

---

## 2. Screenshots Wait ~5 Seconds Before Appearing on the Rope

**Why it happens:** By default, macOS displays a **Floating Thumbnail** preview in the bottom-right corner for ~5 seconds and holds the capture in memory until the preview dismisses, only then writing the `.png` file to your folder.

**Fixes:**
- **Fastest (1-Click):** Click SnapLine's Menu Bar icon → enable **"Chụp xong hiện ngay (Tắt thumbnail macOS)"** (or toggle **Instant Display** in **Settings**). Captures will appear in `<0.2s`.
- **Keep Floating Thumbnail:** Whenever you take a screenshot, swipe the bottom-right thumbnail toward the right edge of the screen to flush it to disk immediately.

---

## 3. `"Your screenshot can't be saved. Cannot write file to intended destination."`

**Why it happens:** This is a macOS `screencapture` limitation when **both** of the following are true:
1. Your macOS screenshot destination is on an **external USB drive** (e.g., `/Volumes/ExternalDrive/Screenshots`), **AND**
2. **Show Floating Thumbnail** is turned **off** (`show-thumbnail = false`).

When Floating Thumbnail is enabled, `screencaptureui` writes the screenshot via a path holding removable-volume access. When Floating Thumbnail is disabled, macOS hands off directly to `/usr/sbin/screencapture`, which lacks the `kTCCServiceSystemPolicyRemovableVolumes` entitlement on some macOS versions and fails to write directly to external USB volumes.

**Fixes:**
1. **Recommended for Instant Capture:** Set your screenshot folder to an internal drive folder (e.g. `~/Pictures/Screenshots`) via **SnapLine → Settings → Choose Folder...** (with macOS location sync enabled). Instant capture (`show-thumbnail = false`) works reliably at `<0.2s`.
2. **To keep saving to an external drive:** Re-enable macOS Floating Thumbnail (uncheck **"Chụp xong hiện ngay"** in SnapLine's Menu Bar, or run `defaults write com.apple.screencapture show-thumbnail -bool true && killall screencaptureui SystemUIServer`), or re-select the external folder via `⌘⇧5` → **Options** → **Save to → Other Location...** so macOS refreshes the folder bookmark.

---

## 4. Building Without Xcode Installed

SnapLine does **not** require `Xcode.app` — Apple Swift Command Line Tools (`xcode-select --install`) is sufficient:
- Build & run tests: `swift run SnapLineTestSuite`
- Build `.app` bundle: `./scripts/build_app.sh`
- Package `.dmg` & `.zip`: `./scripts/package_release.sh 1.0.0`

*(Note: Command Line Tools does not include `XCTest.framework`, which is why SnapLine includes a zero-dependency native Swift test suite executable `SnapLineTestSuite`.)*
