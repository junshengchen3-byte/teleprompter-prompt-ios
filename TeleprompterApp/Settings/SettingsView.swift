import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            theme.pageGradient.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 38, height: 38)
                    }
                    Spacer()
                    Text("设置")
                        .font(.headline)
                    Spacer()
                    Color.clear.frame(width: 38, height: 38)
                }
                .foregroundStyle(theme.text)
                .padding(.horizontal, 10)
                .frame(height: 48)
                .promptPanel(radius: 24, theme: theme)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        settingsSection("提词") {
                            SettingStepperRow(title: "字号", value: $settings.defaultFontSize, range: 28...72, step: 2, formatter: { "\(Int($0))" })
                            SettingStepperRow(title: "速度", value: $settings.defaultScrollSpeed, range: 8...120, step: 4, formatter: { "\(Int($0))" })
                            SettingIntStepperRow(title: "倒计时", value: $settings.defaultCountdownSeconds, range: 0...10, suffix: " 秒")
                            SettingIntStepperRow(title: "继续倒计时", value: $settings.resumeCountdownSeconds, range: 1...5, suffix: " 秒")
                            Toggle("镜像", isOn: $settings.defaultMirrorEnabled)
                            Toggle("自动隐藏控制栏", isOn: $settings.autoHideControls)
                            Picker("背景", selection: $settings.defaultBackgroundStyle) {
                                Text("黑底白字").tag("black")
                                Text("白底黑字").tag("white")
                            }
                        }

                        settingsSection("拍摄") {
                            Picker("默认摄像头", selection: $settings.defaultCameraPosition) {
                                Text("前置").tag("front")
                                Text("后置").tag("back")
                            }
                        }

                        settingsSection("权限") {
                            PermissionStatusRow(name: "相机", value: "进入拍摄时请求")
                            PermissionStatusRow(name: "麦克风", value: "进入拍摄时请求")
                            PermissionStatusRow(name: "相册", value: "保存时请求")
                        }

                        settingsSection("隐私") {
                            Text("脚本仅保存在本机。第一版不登录、不云同步、不上传录制视频。")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)
                        }
                    }
                    .foregroundStyle(theme.text)
                }
            }
            .padding(18)
            .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .colorScheme(theme.isLight ? .light : .dark)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .promptPanel(radius: 18, theme: theme)
        }
    }

    private var theme: PromptTheme {
        PromptDesign.theme(for: settings)
    }
}

struct SettingStepperRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formatter: (Double) -> String

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Stepper(value: $value, in: range, step: step) {
                Text(formatter(value))
                    .foregroundStyle(PromptDesign.secondaryText)
            }
            .frame(maxWidth: 170)
        }
        .padding(.vertical, 12)
    }
}

struct SettingIntStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Stepper(value: $value, in: range) {
                Text("\(value)\(suffix)")
                    .foregroundStyle(PromptDesign.secondaryText)
            }
            .frame(maxWidth: 170)
        }
        .padding(.vertical, 12)
    }
}

struct PermissionStatusRow: View {
    let name: String
    let value: String

    var body: some View {
        HStack {
            Text(name).font(.headline)
            Spacer()
            Text(value)
                .foregroundStyle(PromptDesign.secondaryText)
        }
        .padding(.vertical, 12)
    }
}
