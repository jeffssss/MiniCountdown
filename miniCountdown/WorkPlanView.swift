import SwiftUI

struct WorkPlanView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var periodDays: Int = 7
    @State private var startDate = Calendar.current.startOfDay(for: Date())
    @State private var targetHours: Float = 40
    @State private var workDays: Int = 5
    @State private var workDurationMinutes: Int = 40
    @State private var showError = false
    @State private var showConfirmation = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    private var endDate: Date {
        Calendar.current.date(byAdding: .second, value: (periodDays * 24 * 3600 - 1) , to: startDate) ?? startDate
    }
    
    private var isInputValid: Bool {
        guard periodDays > 0 && periodDays <= 365 else {
            errorMessage = "工作周期必须在1-365天之间"
            return false
        }
        
        guard targetHours > 0 && targetHours <= Float(periodDays) * 24 else {
            errorMessage = "目标工作时长必须大于0且不能超过总周期时长"
            return false
        }
        
        guard workDays > 0 && workDays <= periodDays else {
            errorMessage = "计划工作天数必须大于0且不能超过工作周期"
            return false
        }
        
        return true
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                HStack {
                    Text("工作周期：")
                    TextField("", value: $periodDays, format: .number)
                        .frame(width: 60)
                    Text("天")
                }
                .padding(.vertical, 4)
                
                DatePicker("开始日期：", selection: $startDate, displayedComponents: .date)
                    .padding(.vertical, 4)
                    .onChange(of: startDate) { oldValue, newDate in
                        startDate = Calendar.current.startOfDay(for: newDate)
                    }
                
                HStack {
                    Text("结束日期：")
                    Text(endDate, format: .dateTime.year().month().day())
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("目标设置")) {
                HStack {
                    Text("目标工作时长：")
                    TextField("", value: $targetHours, format: .number)
                        .frame(width: 60)
                    Text("小时")
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("计划工作天数：")
                    TextField("", value: $workDays, format: .number)
                        .frame(width: 60)
                    Text("天")
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("单次工作时长：")
                    TextField("", value: $workDurationMinutes, format: .number)
                        .frame(width: 60)
                    Text("分钟")
                }
                .padding(.vertical, 4)
            }
            
            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                Button("创建计划") {
                    if isInputValid {
                        showConfirmation = true
                    } else {
                        showError = true
                    }
                }
            }
            .padding(.top)
        }
        .padding(20)
        .frame(width: 400)
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("确认", isPresented: $showConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确定") {
                createWorkPlan()
            }
        } message: {
            Text("确定要创建这个工作计划吗？")
        }
        .alert("成功", isPresented: $showSuccess) {
            Button("确定") {
                showSuccess = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }
        } message: {
            Text("工作计划已成功创建")
        }
    }
    
    private func createWorkPlan() {
        if let plan = WorkMindManager.shared.createWorkPlan(periodDays: periodDays,
                                                            startDate: startDate,
                                                            targetHours: targetHours,
                                                            workDays: workDays,
                                                            workDurationMinutes:workDurationMinutes) {
            showSuccess = true
            // 发送工作计划创建成功的通知
            NotificationCenter.default.post(name: NSNotification.Name("WorkPlanCreated"), object: nil)
        } else {
            errorMessage = "创建工作计划失败，该时间段已存在其他计划"
            showError = true
        }
    }
}

#Preview {
    WorkPlanView()
}
