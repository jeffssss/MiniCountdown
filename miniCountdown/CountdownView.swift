import SwiftUI
import AVFoundation
import CoreData

struct CountdownView: View {
    let totalSeconds: Int
    let isAlwaysOnTop: Bool
    let isDarkMode: Bool
    
    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    @State private var isMouseInside: Bool = false
    @State private var showingAlert: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var hostWindow: NSWindow?
    @State private var currentRecord: WorkMindRecord?
    
    init(totalSeconds: Int, isAlwaysOnTop: Bool, isDarkMode: Bool) {
        self.totalSeconds = totalSeconds
        self.isAlwaysOnTop = isAlwaysOnTop
        self.isDarkMode = isDarkMode
        _remainingSeconds = State(initialValue: totalSeconds)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geometry in
                ZStack {
                    isDarkMode ? Color.black : Color.white
                    
                    Text(timeString(from: remainingSeconds))
                        .font(.system(size: calculateFontSize(for: geometry.size)))
                        .bold()
                        .minimumScaleFactor(0.01)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // 关闭按钮
            if isMouseInside {
                Button(action: {
                    closeCountdownWindow(status: .interrupted)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(2)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onHover { hovering in
            isMouseInside = hovering
        }
        .onAppear {
            // 创建倒计时记录
            currentRecord = WorkMindManager.shared.createRecord(duration: Int32(totalSeconds))
            startTimer()
            // 保存窗口引用
            if let window = NSApplication.shared.windows.first(where: { window in
                return window.contentView is NSHostingView<CountdownView>
            }) {
                hostWindow = window
            }
        }
        .onDisappear {
            timer?.invalidate()
            // 如果倒计时还在进行中，则标记为中断
            if remainingSeconds > 0, let record = currentRecord {
                WorkMindManager.shared.updateRecord(record, status: .interrupted)
            }
        }
    }
    
    private func calculateFontSize(for size: CGSize) -> CGFloat {
        let minDimension = min(size.width - 20, size.height)
        return minDimension * 0.8
    }
    
    private func startTimer() {
        let screenshotManager = ScreenshotManager.shared
        var lastScreenshotTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                
                // 检查是否需要执行截图
                let currentTime = Date()
                if currentTime.timeIntervalSince(lastScreenshotTime) >= screenshotManager.interval {
                    screenshotManager.takeScreenshot()
                    lastScreenshotTime = currentTime
                }
            } else {
                closeCountdownWindow(status: .completed)
                playSound()
                showCenteredAlert()
            }
        }
    }
    
    private func closeCountdownWindow(status: CountdownStatus) {
        DispatchQueue.main.async {
            // 先停止计时器和更新状态，再关闭窗口
            timer?.invalidate()
            timer = nil
            
            // 更新WorkMindRecord状态
            if let record = currentRecord {
                WorkMindManager.shared.updateRecord(record, status: status)
            }
            
            AppDelegate.shared?.isCountdownRunning = false
            hostWindow?.close()
        }
    }
    
    private func playSound() {
        if let soundURL = Bundle.main.url(forResource: "finish_sound", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                NSSound.beep()
            }
        } else {
            NSSound.beep()
        }
    }
    
    private func showCenteredAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "倒计时结束"
            alert.informativeText = "时间到了！"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            
            if let iconImage = NSImage(systemSymbolName: "timer", accessibilityDescription: nil) {
                iconImage.size = NSSize(width: 64, height: 64)
                alert.icon = iconImage
            }
            
            alert.runModal()
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    CountdownView(totalSeconds: 3600, isAlwaysOnTop: false, isDarkMode: false)
}
