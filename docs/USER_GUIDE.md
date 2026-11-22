# SnapLine User Guide / Hướng dẫn Sử dụng

---

## English

### 1. First Launch & Menu Bar
SnapLine runs quietly as a Menu Bar accessory (`LSUIElement = true`) without cluttering your Dock.
- Look for the **clothesline icon** in your macOS Menu Bar.
- On first launch, SnapLine automatically reads your macOS screenshot folder (`com.apple.screencapture location`, defaulting to `~/Desktop` if unset).
- Click the Menu Bar icon anytime to:
  - **Show / Hide Clothesline** (`⌘⇧L`)
  - **Play New Capture Demo** to preview the 4-stage animation on demand
  - **Open Folder in Finder** or **Change Screenshot Folder...**
  - Toggle **Instant Display (Disable macOS thumbnail)**
  - Open **Settings...** (`⌘,`)

### 2. Taking Screenshots & Recordings
Take screenshots (`⌘⇧3`, `⌘⇧4`, `⌘⇧5`) or screen recordings (`⌘⇧5`) as usual:
1. Once the file finishes saving to disk, SnapLine detects it within ~15ms and drops the clothesline across the top quarter of your active display.
2. Existing cards sway in a gentle breeze and glide left to clear the rightmost slot.
3. Your latest capture arcs up from the bottom-right and is clamped by a wooden clothespin.
4. The overlay auto-hides smoothly after **6 seconds** (configurable) unless you hover over a card, scroll, drag, or open Quick Look.

### 3. Browsing & Acting on Captures
- **Scroll into the past:** Swipe horizontally with two fingers on a Trackpad, scroll your mouse wheel, or press `←` / `→`.
- **Quick Look:** Single-click any Polaroid (or press `Space`) to inspect at full resolution or play recorded video with audio. Press `←` / `→` inside Quick Look to browse adjacent captures.
- **Drag & Drop:** Click and drag any Polaroid directly onto Slack, Figma, Mail, Notes, Chrome, or Finder.
- **Hover Quick Actions:** Hovering lifts the card and reveals a frosted pill with three buttons:
  - **Copy:** Copies both the image pixels and file URL to the clipboard (shows a green checkmark).
  - **Reveal in Finder:** Selects the original file in Finder.
  - **Trash:** Unclips the card with a drop animation and moves the file to the Trash.
- **Inline Video Preview:** Hover over a `.mov` / `.mp4` card for `0.35s` to preview the muted loop right inside the Polaroid frame.

### 4. Preferences (`⌘,`)
- **Screenshot Folder:** Choose any directory and optionally keep macOS's `com.apple.screencapture location` in sync.
- **Instant Display:** Disables macOS's 5-second corner floating thumbnail so captures land on the clothesline immediately (`<0.2s`). *(See [Troubleshooting](TROUBLESHOOTING.md) if saving directly to an external USB drive.)*
- **Appearance & Auto-Hide:** Adjust auto-hide delay (`3s`, `6s`, `10s`, `15s`, or `Never`), Polaroid size (`Compact`, `Regular`, `Large`), rope sag intensity (`0.4x – 1.5x`), and chin timestamps.
- **Global Hotkey & Login:** Choose from `⌘⇧L`, `⌥⇧S`, `⌃⌥S`, or `⌘⇧K`, and toggle Launch at Login (`LaunchAgent`).

---

## Tiếng Việt

### 1. Khởi chạy & Menu Bar
SnapLine chạy gọn nhẹ trên **Menu Bar** và không chiếm chỗ trên Dock.
- Lần đầu mở app, SnapLine tự nhận diện thư mục lưu screenshot hiện tại của macOS (`com.apple.screencapture location`, mặc định `~/Desktop`).
- Bấm icon dây treo ảnh trên Menu Bar để **Hiện/Ẩn dây treo (`⌘⇧L`)**, **Thử hiệu ứng chụp mới (Demo)**, **Mở thư mục trong Finder**, **Đổi thư mục lưu**, bật/tắt nhanh **Chụp xong hiện ngay**, hoặc mở **Cài đặt (`⌘,`)**.

### 2. Chụp & Quay màn hình
Chụp ảnh (`⌘⇧3`, `⌘⇧4`, `⌘⇧5`) hoặc quay video màn hình (`⌘⇧5`) như bình thường:
1. Ngay khi file được ghi xong ra thư mục, dây thừng hạ xuống ở 1/4 phía trên màn hình.
2. Các ảnh cũ rung rinh nhẹ rồi trượt sang trái nhường vị trí ngoài cùng bên phải.
3. Ảnh mới chụp bay vút lên từ góc dưới phải và được kẹp gỗ đóng chặt vào dây.
4. Dây tự ẩn mượt sau **6 giây** nếu bạn không chạm chuột (tự tạm dừng đếm ngược khi hover, cuộn, kéo-thả hoặc mở Quick Look).

### 3. Cuộn & Thao tác trên từng Tấm ảnh
- **Cuộn về quá khứ:** Vuốt ngang 2 ngón trên Trackpad, lăn chuột, hoặc bấm phím `←` / `→`.
- **Xem chi tiết (Quick Look):** Click 1 lần vào ảnh (hoặc nhấn `Space`) để phóng to độ phân giải gốc / xem video có tiếng; double-click để mở bằng app mặc định.
- **Kéo-thả trực tiếp:** Kéo thẳng tấm Polaroid thả sang Slack, Figma, Chrome, Mail hoặc Finder.
- **Thanh thao tác nhanh khi Hover:** Hiện 3 nút **Copy** (kèm dấu tích ✓), **Mở trong Finder**, và **Xóa vào Thùng rác** (hiệu ứng gỡ kẹp rơi xuống). Với video `.mov`/`.mp4`, giữ chuột `0.35s` sẽ phát preview lặp không tiếng ngay trong khung ảnh.
