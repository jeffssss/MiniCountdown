import SwiftUI
import AVFoundation
import CoreData
import SwiftyJSON

struct CountdownView: View {
    let totalSeconds: Int
    let isAlwaysOnTop: Bool
    let isDarkMode: Bool
    
    @State private var isMonitorEnabled : Bool
    
    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    @State private var isMouseInside: Bool = false
    @State private var showingAlert: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var hostWindow: NSWindow?
    @State private var currentRecord: WorkMindRecord?
    @State private var isPaused: Bool = false
    @State private var pauseStartTime: Date?
    
    @State private var compensateTime: Int
    @State private var startTime : Date?
    
    // 添加工作监控器
    private var workMonitor: WorkMonitor
    
    init(totalSeconds: Int, isAlwaysOnTop: Bool, isDarkMode: Bool, isMonitorEnabled: Bool = true) {
        self.totalSeconds = totalSeconds
        self.isAlwaysOnTop = isAlwaysOnTop
        self.isDarkMode = isDarkMode
        self.isMonitorEnabled = isMonitorEnabled
        _remainingSeconds = State(initialValue: totalSeconds)
        self.compensateTime = 0
        self.workMonitor = WorkMonitor()
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
                    
                    if isMouseInside {
                        VStack {
                            Spacer()
                            HStack {
                                Button(action: {
                                    isMonitorEnabled.toggle()
                                    if isMonitorEnabled, let startTime = startTime {
                                        // 更新lastScreenshotTimeSinceStart为当前时间减去补偿时间
                                        workMonitor.setLastScreenshotTime(Date().timeIntervalSince(startTime) - Double(compensateTime))
                                    }
                                }) {
                                    Image(systemName: isMonitorEnabled ? "eye.circle.fill" : "eye.slash.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(isMonitorEnabled ? (isDarkMode ? .white : .black) : .gray)
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                                Button(action: {
                                    if isPaused {
                                        // 继续计时
                                        if let pauseTime = pauseStartTime {
                                            compensateTime += Int(Date().timeIntervalSince(pauseTime))
                                        }
                                        isPaused = false
                                        pauseStartTime = nil
                                    } else {
                                        // 暂停计时
                                        isPaused = true
                                        pauseStartTime = Date()
                                    }
                                }) {
                                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(8)
                            }
                        }
                    }
                }
            }
            
            // 关闭按钮
            if isMouseInside {
                Button(action: {
                    closeCountdownWindow(status: .interrupted)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
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
            print("CountdownView onAppear")

            // 创建倒计时记录
            currentRecord = WorkMindManager.shared.createRecord(duration: Int32(totalSeconds))
            startTimer()
            // 保存窗口引用
            if let window = NSApplication.shared.windows.first(where: { window in
                return window.contentView is NSHostingView<CountdownView>
            }) {
                hostWindow = window
            }
            
            // 添加锁屏事件监听
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ScreenDidLock"),
                object: nil,
                queue: .main
            ) { _ in
                if !isPaused {
                    alert(alertMessage: "检测到锁屏", alertReason: "已检测到锁屏操作，点击确认继续工作" , playSound: false)
                }
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
    
    private func alert(alertMessage:String, alertReason:String, playSound:Bool = true) {
        if playSound {
            alertSound()
        }
        
        let alert = NSAlert()
        alert.messageText = alertMessage
        alert.informativeText = alertReason
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        // 获取 alert 窗口并设置其属性
        alert.window.level = .floating
        NSApp.activate(ignoringOtherApps: true)
        
        // 处理按钮点击回调
        let alertTime = Date()
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let confirmTime = Date()
            let confirmDelay = Int(confirmTime.timeIntervalSince(alertTime))
            if !self.isPaused {
                self.compensateTime += confirmDelay
                print("用户确认了警告信息,耗时为\(confirmDelay),会补充至compensateTime=\(self.compensateTime)")
            } else {
                print("用户确认了警告信息,耗时为\(confirmDelay),由于当前处于暂停状态，不补充时间")
            }
        }
    }
    
    private func calculateFontSize(for size: CGSize) -> CGFloat {
        let minDimension = min(size.width - 20, size.height)
        return minDimension * 0.8
    }
    
    private func startTimer() {
        compensateTime = 0
        startTime = Date()  // 记录开始时间
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if isPaused {
                return
            }
            let currentTime = Date()
            //更新倒计时
            let elapsedSeconds = Int(currentTime.timeIntervalSince(startTime!))
            remainingSeconds = max(totalSeconds + compensateTime - elapsedSeconds, 0)
            
            if remainingSeconds > 0 {
                // 检查是否需要执行截图
                let timeSinceStart = currentTime.timeIntervalSince(startTime!) - Double(compensateTime)
                
                // 使用WorkMonitor检查工作状态
                if isMonitorEnabled {
                    workMonitor.checkWorkStatus(timeSinceStart: timeSinceStart)
                    { alertMessage, alertReason in
                        alert(alertMessage: alertMessage, alertReason: alertReason)
                    }
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
    
    private func alertSound(){
        if let soundURL = Bundle.main.url(forResource: "not_working_alert", withExtension: "wav") {
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
