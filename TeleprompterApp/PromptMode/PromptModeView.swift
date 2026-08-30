import SwiftData
import SwiftUI

struct PromptModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var scripts: [Script]

    let settings: AppSettings
    private let initialMode: PromptDisplayMode
    @State private var permissionService = PermissionService()
    @StateObject private var cameraService: CameraRecordingService
    @State private var selectedScript: Script?
    @State private var session: TeleprompterSession?
    @State private var activeSheet: PromptSheet?
    @State private var displayMode: PromptDisplayMode
    @State private var lastTick = Date()
    @State private var cameraAspectRatio: CameraAspectRatio = .ratio9x16
    @State private var cameraZoomFactor: CameraZoomFactor = .one
    @State private var promptPanelOffset: CGSize = .zero
    @State private var promptPanelScale: CGFloat = 1
    @State private var promptPanelOpacity = 0.58
    @State private var shouldResumeCameraRecordingAfterCountdown = false

    init(settings: AppSettings, initialScript: Script? = nil, initialMode: PromptDisplayMode = .fullScreen) {
        self.settings = settings
        self.initialMode = initialMode
        let defaultPosition: CameraPosition = settings.defaultCameraPosition == "back" ? .back : .front
        _cameraService = StateObject(wrappedValue: CameraRecordingService(defaultPosition: defaultPosition))
        _selectedScript = State(initialValue: initialScript)
        _session = State(initialValue: initialScript.map { TeleprompterSession(text: $0.body, settings: settings) })
        _displayMode = State(initialValue: initialMode)
    }

    var body: some View {
        ZStack {
            if let session {
                if displayMode == .camera {
                    cameraStage(session)
                } else {
                    teleprompterStage(session)
                }
            } else {
                preparation
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .colorScheme(theme.isLight ? .light : .dark)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newScript:
                ScriptEditorView(modeTitle: "新建脚本", theme: theme) { script in
                    start(with: script)
                }
            case .editScript(let script):
                ScriptEditorView(script: script, modeTitle: "编辑脚本", theme: theme) { script in
                    start(with: script)
                }
            case .library:
                ScriptListView(theme: theme) { script in
                    start(with: script)
                }
            }
        }
    }

    private var preparation: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            theme.pageGradient.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 22) {
                topBar(title: "选择脚本")
                ScriptPickerView(
                    modeTitle: initialMode == .camera ? "拍摄提词" : "全屏提词",
                    theme: theme,
                    onCreate: { activeSheet = .newScript },
                    onOpenLibrary: { activeSheet = .library },
                    recentScripts: recentScripts,
                    onSelect: start(with:),
                    onEdit: { activeSheet = .editScript($0) }
                )
                Spacer()
            }
            .padding(18)
            .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
        }
    }

    private func teleprompterStage(_ session: TeleprompterSession) -> some View {
        TeleprompterTextView(session: session, backgroundStyle: settings.defaultBackgroundStyle)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) {
                    session.toggleControls()
                }
            }
            .overlay(alignment: .top) {
                if session.areControlsVisible {
                    topBar(title: "提词中", compact: true)
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                }
            }
            .overlay {
                if session.areControlsVisible {
                    TeleprompterControlsView(
                        session: session,
                        isLightMode: settings.defaultBackgroundStyle == "white",
                        bottomInset: 84,
                        onToggleTheme: toggleTheme
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if session.areControlsVisible {
                    PromptModeSwitchBar(selectedMode: .fullScreen) {
                        displayMode = .camera
                    } onFullScreen: {}
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                }
            }
            .onReceive(Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()) { now in
                let delta = now.timeIntervalSince(lastTick)
                lastTick = now
                session.tick(delta: delta, maximumOffset: 8000)
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                session.countdownTick()
            }
    }

    private func topBar(title: String, compact: Bool = false) -> some View {
        HStack {
            Button {
                if session == nil {
                    dismiss()
                } else {
                    closeSession()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 38, height: 38)
            }
            Spacer()
            Text(title)
                .font(.headline)
                .foregroundStyle(compact ? PromptDesign.text : theme.text)
            Spacer()
            Button {
                activeSheet = .library
            } label: {
                    Image(systemName: compact ? "slider.horizontal.3" : "list.bullet")
                    .font(.headline)
                    .frame(width: 38, height: 38)
            }
        }
        .foregroundStyle(compact ? PromptDesign.text : theme.text)
        .padding(.horizontal, 8)
        .frame(height: 50)
        .background(.black.opacity(compact ? 0.42 : 0), in: Capsule())
        .promptPanel(radius: 25, theme: compact ? PromptDesign.darkTheme : theme)
    }

    private var recentScripts: [Script] {
        scripts.sortedForPromptLibrary()
    }

    private func start(with script: Script) {
        script.lastUsedAt = .now
        selectedScript = script
        session = TeleprompterSession(text: script.body, settings: settings)
        lastTick = .now
    }

    private func closeSession() {
        cameraService.stopSession()
        session = nil
        displayMode = initialMode
    }

    private func cameraStage(_ session: TeleprompterSession) -> some View {
        GeometryReader { proxy in
            let previewSize = cameraPreviewSize(in: proxy.size)
            let panelSize = CGSize(width: min(proxy.size.width * 0.88, 430), height: min(proxy.size.height * 0.42, 340))
            ZStack {
                Color.black.ignoresSafeArea()

                CameraPreviewView(session: cameraService.session)
                    .frame(width: previewSize.width, height: previewSize.height)
                    .clipShape(Rectangle())
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                MovablePromptPanel(
                    session: session,
                    offset: $promptPanelOffset,
                    scale: $promptPanelScale,
                    opacity: promptPanelOpacity,
                    containerSize: proxy.size,
                    panelSize: panelSize,
                    onTogglePlayback: { toggleCameraPromptPlayback(session) }
                )
                .frame(width: panelSize.width, height: panelSize.height)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                NativeCameraChrome(
                    isRecording: cameraService.isRecording,
                    zoomFactor: cameraZoomFactor,
                    aspectRatio: cameraAspectRatio,
                    promptPanelOpacity: $promptPanelOpacity,
                    onClose: closeSession,
                    onOpenScripts: { activeSheet = .library },
                    onToggleAspectRatio: cycleAspectRatio,
                    onSelectZoom: selectZoomFactor,
                    onOpenAlbum: openAlbumPlaceholder,
                    onRecord: toggleRecording,
                    onFlipCamera: { Task { await cameraService.switchCamera() } }
                )
            }
        }
        .overlay(alignment: .bottom) {
            PromptModeSwitchBar(selectedMode: .camera) {
            } onFullScreen: {
                cameraService.stopSession()
                displayMode = .fullScreen
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .task {
            await prepareCamera()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onReceive(Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()) { now in
            let delta = now.timeIntervalSince(lastTick)
            lastTick = now
            session.tick(delta: delta, maximumOffset: 8000)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            let hadCountdown = session.activeCountdown != nil
            session.countdownTick()
            if hadCountdown, session.activeCountdown == nil, shouldResumeCameraRecordingAfterCountdown {
                cameraService.resumeRecording()
                shouldResumeCameraRecordingAfterCountdown = false
            }
        }
        .alert("拍摄状态", isPresented: Binding(get: { cameraService.lastErrorMessage != nil }, set: { if !$0 { cameraService.lastErrorMessage = nil } })) {
            if permissionService.cameraStatus == .denied ||
                permissionService.microphoneStatus == .denied ||
                permissionService.cameraStatus == .restricted ||
                permissionService.microphoneStatus == .restricted {
                Button("去设置") {
                    cameraService.lastErrorMessage = nil
                    permissionService.openSystemSettings()
                }
            }
            Button("好") { cameraService.lastErrorMessage = nil }
        } message: {
            Text(cameraService.lastErrorMessage ?? "")
        }
    }

    private func prepareCamera() async {
        permissionService.refresh()
        if permissionService.cameraStatus == .notDetermined {
            _ = await permissionService.requestCamera()
        }
        if permissionService.microphoneStatus == .notDetermined {
            _ = await permissionService.requestMicrophone()
        }
        guard permissionService.cameraStatus == .authorized, permissionService.microphoneStatus == .authorized else {
            cameraService.lastErrorMessage = "需要相机和麦克风权限才能使用拍摄提词。"
            return
        }
        await cameraService.configure()
        cameraService.setZoomFactor(cameraZoomFactor.captureZoom)
        cameraService.startSession()
    }

    private func toggleRecording() {
        Task {
            if cameraService.isRecording {
                _ = await permissionService.requestPhotosAddOnly()
                await cameraService.stopRecordingAndSaveToPhotos()
            } else {
                await cameraService.startRecording()
                session?.requestStart()
            }
        }
    }

    private func toggleCameraPromptPlayback(_ session: TeleprompterSession) {
        if session.isScrolling || session.activeCountdown != nil {
            session.pause()
            shouldResumeCameraRecordingAfterCountdown = false
            if cameraService.isRecording && !cameraService.isRecordingPaused {
                cameraService.pauseRecording()
            }
            return
        }

        if cameraService.isRecording && cameraService.isRecordingPaused {
            shouldResumeCameraRecordingAfterCountdown = session.countdownSeconds > 0
            if session.countdownSeconds == 0 {
                cameraService.resumeRecording()
            }
        } else {
            shouldResumeCameraRecordingAfterCountdown = false
        }
        session.requestStart()
    }

    private var theme: PromptTheme {
        PromptDesign.theme(for: settings)
    }

    private func toggleTheme() {
        settings.defaultBackgroundStyle = settings.defaultBackgroundStyle == "white" ? "black" : "white"
    }

    private func cameraPreviewSize(in availableSize: CGSize) -> CGSize {
        let targetRatio = cameraAspectRatio.value
        let availableRatio = availableSize.width / availableSize.height
        if availableRatio > targetRatio {
            return CGSize(width: availableSize.height * targetRatio, height: availableSize.height)
        }
        return CGSize(width: availableSize.width, height: availableSize.width / targetRatio)
    }

    private func cycleAspectRatio() {
        cameraAspectRatio = cameraAspectRatio.next
    }

    private func selectZoomFactor(_ factor: CameraZoomFactor) {
        cameraZoomFactor = factor
        cameraService.setZoomFactor(factor.captureZoom)
    }

    private func openAlbumPlaceholder() {
        cameraService.lastErrorMessage = "录制完成后会直接保存到系统相册。相册入口将在后续版本接入最近视频预览。"
    }
}

enum PromptSheet: Identifiable {
    case newScript
    case editScript(Script)
    case library

    var id: String {
        switch self {
        case .newScript: "newScript"
        case .editScript(let script): "edit-\(script.id.uuidString)"
        case .library: "library"
        }
    }
}

private enum CameraAspectRatio: CaseIterable {
    case ratio9x16
    case ratio3x4
    case ratio1x1

    var title: String {
        switch self {
        case .ratio9x16: "9:16"
        case .ratio3x4: "3:4"
        case .ratio1x1: "1:1"
        }
    }

    var value: CGFloat {
        switch self {
        case .ratio9x16: 9 / 16
        case .ratio3x4: 3 / 4
        case .ratio1x1: 1
        }
    }

    var next: CameraAspectRatio {
        switch self {
        case .ratio9x16: .ratio3x4
        case .ratio3x4: .ratio1x1
        case .ratio1x1: .ratio9x16
        }
    }
}

private enum CameraZoomFactor: Double, CaseIterable {
    case half = 0.5
    case one = 1
    case two = 2

    var title: String {
        switch self {
        case .half: "0.5"
        case .one: "1"
        case .two: "2"
        }
    }

    var captureZoom: CGFloat {
        max(CGFloat(rawValue), 1)
    }
}

private struct MovablePromptPanel: View {
    @Bindable var session: TeleprompterSession
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    let opacity: Double
    let containerSize: CGSize
    let panelSize: CGSize
    let onTogglePlayback: () -> Void
    @State private var dragStartOffset: CGSize?
    @State private var textDragStartOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    Text(session.text)
                        .font(.system(size: session.fontSize * 0.72, weight: .black, design: .rounded))
                        .lineSpacing(session.fontSize * 0.18)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 88)
                        .frame(maxWidth: .infinity)
                        .offset(y: -session.scrollOffset)
                }
                .scrollDisabled(true)
                .contentShape(Rectangle())
                .gesture(textScrollGesture)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Rectangle()
                    .fill(PromptDesign.danger.opacity(0.92))
                    .frame(height: 2)
                    .padding(.horizontal, 18)

                if let countdown = session.activeCountdown {
                    CountdownOverlayView(countdown: countdown)
                }

                VStack {
                    HStack {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.26), in: Circle())
                            .accessibilityLabel("拖动调整位置")
                            .gesture(panelDragGesture)
                        Spacer()
                        Button {
                            togglePanelScale()
                        } label: {
                            Image(systemName: panelScaleIcon)
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.26), in: Circle())
                        }
                        .accessibilityLabel("调整提词框大小")
                        .buttonStyle(.plain)
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(14)
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity)

            PanelPromptControls(
                session: session,
                onTogglePlayback: onTogglePlayback
            )
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
        .padding(.top, 2)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.black.opacity(opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
        }
        .scaleEffect(scale)
        .offset(offset)
    }

    private var textScrollGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if !session.isDragging {
                    textDragStartOffset = session.scrollOffset
                    session.beginManualReposition()
                }
                session.updateManualOffset(textDragStartOffset - value.translation.height)
            }
            .onEnded { _ in
                session.finishManualReposition()
            }
    }

    private var panelDragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if dragStartOffset == nil {
                    dragStartOffset = offset
                }
                let start = dragStartOffset ?? .zero
                offset = clampedOffset(CGSize(width: start.width + value.translation.width, height: start.height + value.translation.height))
            }
            .onEnded { _ in
                dragStartOffset = nil
                offset = clampedOffset(offset)
            }
    }

    private var panelScaleIcon: String {
        scale < 0.95 ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left"
    }

    private func togglePanelScale() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            scale = scale < 0.95 ? 1 : 0.82
            offset = clampedOffset(offset)
        }
    }

    private func clampedOffset(_ proposed: CGSize) -> CGSize {
        let scaledWidth = panelSize.width * scale
        let scaledHeight = panelSize.height * scale
        let maxX = max(0, (containerSize.width - scaledWidth) / 2 - 10)
        let maxY = max(0, (containerSize.height - scaledHeight) / 2 - 26)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }
}

private struct PanelPromptControls: View {
    @Bindable var session: TeleprompterSession
    let onTogglePlayback: () -> Void

    var body: some View {
        let isPreparingToPlay = session.isScrolling || session.activeCountdown != nil

        VStack(spacing: 8) {
            HStack(spacing: 9) {
                compactButton("minus") {
                    session.scrollSpeed = max(8, session.scrollSpeed - 4)
                }
                compactValue("速度", "\(Int(session.scrollSpeed))")
                compactButton("plus") {
                    session.scrollSpeed = min(120, session.scrollSpeed + 4)
                }
                compactChip(isPreparingToPlay ? "暂停" : "播放", isPreparingToPlay ? "pause.fill" : "play.fill", action: onTogglePlayback)
            }

            HStack(spacing: 9) {
                compactButton("minus") {
                    session.fontSize = max(28, session.fontSize - 2)
                }
                compactValue("字号", "\(Int(session.fontSize))")
                compactButton("plus") {
                    session.fontSize = min(72, session.fontSize + 2)
                }
                compactChip("从头", "backward.end.fill") {
                    session.restart()
                }
            }
        }
        .padding(10)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .foregroundStyle(.white)
    }

    private func compactButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: image)
                .font(.system(size: 12, weight: .black))
                .frame(width: 38, height: 34)
                .background(PromptDesign.panelLight.opacity(0.92), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func compactValue(_ title: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Text(title)
            Text(value).foregroundStyle(PromptDesign.accentBlue)
        }
        .font(.caption2.weight(.bold))
        .frame(width: 74, height: 34)
        .background(PromptDesign.panelLight.opacity(0.92), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func compactChip(_ title: String, _ image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: image)
                .font(.caption2.weight(.bold))
                .frame(width: 74, height: 34)
                .background(PromptDesign.panelLight.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct NativeCameraChrome: View {
    let isRecording: Bool
    let zoomFactor: CameraZoomFactor
    let aspectRatio: CameraAspectRatio
    @Binding var promptPanelOpacity: Double
    let onClose: () -> Void
    let onOpenScripts: () -> Void
    let onToggleAspectRatio: () -> Void
    let onSelectZoom: (CameraZoomFactor) -> Void
    let onOpenAlbum: () -> Void
    let onRecord: () -> Void
    let onFlipCamera: () -> Void
    @State private var isOpacitySliderVisible = false

    var body: some View {
        VStack {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    cameraIconButton("chevron.left", action: onClose)
                    Spacer()
                    cameraIconButton("circle.lefthalf.filled") {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isOpacitySliderVisible.toggle()
                        }
                    }
                    .accessibilityLabel("调整提词框透明度")
                    cameraTextButton(aspectRatio.title, action: onToggleAspectRatio)
                    cameraIconButton("list.bullet", action: onOpenScripts)
                        .accessibilityLabel("脚本列表")
                }
                .padding(.horizontal, 20)

                if isOpacitySliderVisible {
                    opacitySlider
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.top, 12)

            Spacer()

            zoomSelector
                .padding(.bottom, 18)

            HStack {
                cameraIconButton("photo.on.rectangle", action: onOpenAlbum)
                    .frame(width: 76)
                Spacer()
                Button(action: onRecord) {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 5)
                        Circle()
                            .fill(isRecording ? PromptDesign.danger : Color(red: 1, green: 0.22, blue: 0.2))
                            .frame(width: isRecording ? 44 : 58, height: isRecording ? 44 : 58)
                            .clipShape(RoundedRectangle(cornerRadius: isRecording ? 12 : 29, style: .continuous))
                    }
                    .frame(width: 78, height: 78)
                }
                .accessibilityLabel(isRecording ? "停止录制" : "开始录制")
                Spacer()
                cameraIconButton("arrow.triangle.2.circlepath.camera", action: onFlipCamera)
                    .frame(width: 76)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 74)
        }
        .foregroundStyle(.white)
    }

    private var zoomSelector: some View {
        HStack(spacing: 8) {
            ForEach(CameraZoomFactor.allCases, id: \.self) { factor in
                Button {
                    onSelectZoom(factor)
                } label: {
                    Text("\(factor.title)x")
                        .font(.caption.weight(.black))
                        .foregroundStyle(zoomFactor == factor ? .black : .white)
                        .frame(width: 46, height: 34)
                        .background(zoomFactor == factor ? .white : .black.opacity(0.38), in: Capsule())
                }
            }
        }
        .padding(6)
        .background(.black.opacity(0.36), in: Capsule())
    }

    private var opacitySlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.on.square")
                .font(.system(size: 15, weight: .bold))
            Slider(value: $promptPanelOpacity, in: 0.25...0.86)
                .tint(PromptDesign.accentBlue)
            Text("\(Int(promptPanelOpacity * 100))")
                .font(.caption.weight(.black))
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.46), in: Capsule())
    }

    private func cameraIconButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: image)
                .font(.system(size: 22, weight: .bold))
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.32), in: Circle())
        }
    }

    private func cameraTextButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.black))
                .frame(width: 54, height: 38)
                .background(.black.opacity(0.34), in: Capsule())
        }
    }
}
