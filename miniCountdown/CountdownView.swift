import SwiftUI
import AVFoundation

struct CountdownView: View {
    let totalSeconds: Int
    let isAlwaysOnTop: Bool
    let isDarkMode: Bool
    
    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    @State private var isMouseInside: Bool = false
    @State private var showingAlert: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    
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
                    NSApplication.shared.terminate(nil)
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
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func calculateFontSize(for size: CGSize) -> CGFloat {
        let minDimension = min(size.width - 20, size.height)
        return minDimension * 0.8
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                timer?.invalidate()
                closeCountdownWindow()
                playSound()
                showCenteredAlert()
            }
        }
    }
    
    private func closeCountdownWindow() {
        DispatchQueue.main.async {
            if let windows = NSApplication.shared.windows.first(where: { window in
                return window.contentView is NSHostingView<CountdownView>
            }) {
                windows.close()
            }
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
        let alert = NSAlert()
        alert.messageText = "倒计时结束"
        alert.informativeText = "时间到了！"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        if let iconImage = NSImage(systemSymbolName: "timer", accessibilityDescription: nil) {
            iconImage.size = NSSize(width: 64, height: 64)
            alert.icon = iconImage
        }
        
        if let screen = NSScreen.main {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                styleMask: [],
                backing: .buffered,
                defer: true
            )
            
            let centerX = screen.frame.midX
            let centerY = screen.frame.midY
            
            window.setFrameOrigin(NSPoint(x: centerX - 50, y: centerY - 50))
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSApplication.shared.terminate(nil)
            }
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
