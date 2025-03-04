import SwiftUI

// 浏览器监控设置视图
struct BrowserMonitorSettingsView: View {
    @Binding var urlBlacklist: [String]
    @Binding var timeout: String
    @Binding var showTimeoutError: Bool
    @State private var newUrlPattern: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("浏览器监控设置").bold()) {
                HStack {
                    TextField("限制时间（秒）", text: $timeout)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 180)
                        .onChange(of: timeout) { oldValue, newValue in
                            if let timeoutValue = Int(newValue), timeoutValue > 0 {
                                showTimeoutError = false
                                BrowserMonitor.shared.timeout = timeoutValue
                            } else {
                                showTimeoutError = true
                            }
                        }
                    if showTimeoutError {
                        Text("请输入大于0的数字")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    TextField("输入URL匹配规则", text: $newUrlPattern)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        if !newUrlPattern.isEmpty {
                            BrowserMonitor.shared.addToBlacklist(newUrlPattern)
                            urlBlacklist = BrowserMonitor.shared.urlBlacklist
                            newUrlPattern = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(newUrlPattern.isEmpty)
                }
                .padding(.vertical, 4)
                
                List {
                    ForEach(urlBlacklist, id: \.self) { pattern in
                        HStack {
                            Text(pattern)
                            Spacer()
                            Button(action: {
                                BrowserMonitor.shared.removeFromBlacklist(pattern)
                                urlBlacklist = BrowserMonitor.shared.urlBlacklist
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(height: 150)
            }
        }
    }
}