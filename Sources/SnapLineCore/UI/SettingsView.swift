import SwiftUI
import AppKit

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var instantDisplayEnabled: Bool = false
    @Published public var launchAtLogin: Bool = false
    @Published public var statusBanner: String?

    public init() {
        refresh()
    }

    public func refresh() {
        instantDisplayEnabled = !SystemScreenshotConfig.isFloatingThumbnailEnabled()
        launchAtLogin = LaunchAgentManager.isEnabled
    }
}

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var store: ScreenshotStore
    @ObservedObject var viewModel: SettingsViewModel
    var onPickFolder: () -> Void
    var onPlayDemo: () -> Void

    public init(
        settings: AppSettings,
        store: ScreenshotStore,
        viewModel: SettingsViewModel,
        onPickFolder: @escaping () -> Void,
        onPlayDemo: @escaping () -> Void
    ) {
        self.settings = settings
        self.store = store
        self.viewModel = viewModel
        self.onPickFolder = onPickFolder
        self.onPlayDemo = onPlayDemo
    }

    public var body: some View {
        Form {
            Section("Thư mục lưu Screenshot") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.secondary)
                        Text(settings.watchedFolderURL.path)
                            .font(.system(.callout, design: .monospaced))
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }

                    HStack(spacing: 8) {
                        Text("\(store.items.count) ảnh / video")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Theo hệ thống") {
                            let sysURL = SystemScreenshotConfig.readSystemLocation()
                            try? settings.updateWatchedFolder(sysURL, syncToSystemIfEnabled: false)
                            store.reloadFolder(url: sysURL)
                            viewModel.statusBanner = "Đã đồng bộ theo thư mục macOS."
                        }
                        .controlSize(.small)

                        Button("Chọn thư mục...") {
                            onPickFolder()
                        }
                        .controlSize(.small)
                        .buttonStyle(.borderedProminent)
                    }
                }

                Toggle("Đồng bộ luôn vị trí lưu screenshot của macOS", isOn: $settings.syncSystemLocation)
                    .onChange(of: settings.syncSystemLocation) { _, sync in
                        if sync {
                            do {
                                try SystemScreenshotConfig.writeSystemLocation(settings.watchedFolderURL)
                                viewModel.statusBanner = "Đã cập nhật thư mục lưu screenshot của macOS."
                            } catch {
                                viewModel.statusBanner = error.localizedDescription
                            }
                        }
                    }
            }

            Section("Tốc độ hiện dây treo") {
                Toggle("Hiện ngay lập tức (Tắt preview góc dưới mặc định của macOS)", isOn: $viewModel.instantDisplayEnabled)
                    .onChange(of: viewModel.instantDisplayEnabled) { _, instant in
                        let currentInstant = !SystemScreenshotConfig.isFloatingThumbnailEnabled()
                        guard instant != currentInstant else { return }
                        do {
                            try SystemScreenshotConfig.setFloatingThumbnailEnabled(!instant)
                            viewModel.statusBanner = instant
                                ? "Đã tắt preview góc dưới — dây treo sẽ hiện ngay <0.2s sau khi chụp."
                                : "Đã bật lại preview góc dưới mặc định của macOS."
                        } catch {
                            viewModel.statusBanner = error.localizedDescription
                            viewModel.instantDisplayEnabled = !SystemScreenshotConfig.isFloatingThumbnailEnabled()
                        }
                    }

                Text("Mặc định macOS giữ ảnh chụp ở góc dưới phải ~5 giây trước khi lưu xuống ổ đĩa. Bật tùy chọn này giúp ảnh bay thẳng lên dây ngay khi bạn chụp xong.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Hiển thị & Tự ẩn") {
                Picker("Tự ẩn khi không tương tác", selection: $settings.autoHideDelay) {
                    Text("3 giây").tag(3.0)
                    Text("6 giây (Mặc định)").tag(6.0)
                    Text("10 giây").tag(10.0)
                    Text("15 giây").tag(15.0)
                    Text("Không tự ẩn").tag(0.0)
                }

                Picker("Kích thước ảnh Polaroid", selection: $settings.cardSize) {
                    ForEach(CardSizePreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Độ võng dây thừng")
                    Spacer()
                    Slider(value: $settings.ropeSagIntensity, in: 0.4...1.5, step: 0.1)
                        .frame(width: 180)
                    Text(String(format: "%.1fx", settings.ropeSagIntensity))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 34, alignment: .trailing)
                }

                Toggle("Hiển thị thời gian chụp ở viền dưới ảnh", isOn: $settings.showTimestamp)
            }

            Section("Phím tắt & Hệ thống") {
                Picker("Phím tắt gọi / ẩn dây treo", selection: $settings.hotKey) {
                    ForEach(HotKeyPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }

                Toggle("Tự mở SnapLine khi đăng nhập macOS", isOn: $viewModel.launchAtLogin)
                    .onChange(of: viewModel.launchAtLogin) { _, enabled in
                        guard enabled != LaunchAgentManager.isEnabled else { return }
                        do {
                            try LaunchAgentManager.setEnabled(enabled)
                        } catch {
                            viewModel.statusBanner = error.localizedDescription
                            viewModel.launchAtLogin = LaunchAgentManager.isEnabled
                        }
                    }
            }

            if let statusBanner = viewModel.statusBanner {
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text(statusBanner)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("SnapLine · Mượt nhẹ trên macOS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Thử hiệu ứng chụp mới (Demo)") {
                    onPlayDemo()
                }
                .controlSize(.regular)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .frame(width: 520, height: 540)
        .onAppear {
            viewModel.refresh()
        }
    }
}
