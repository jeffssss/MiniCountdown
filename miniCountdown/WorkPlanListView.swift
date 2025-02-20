import SwiftUI

struct WorkPlanItemView: View {
    let plan: WorkPlanRecord
    let viewModel: WorkPlanListViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(viewModel.formatDate(plan.startDate)) ~ \(viewModel.formatDate(plan.endDate))")
                    .font(.subheadline)
                
                Spacer()
                
                Text(viewModel.getActiveStatus(plan.isActive))
                    .font(.subheadline)
                    .foregroundColor(viewModel.getActiveStatusColor(plan.isActive))
            }
            
            HStack(spacing: 12) {
                Label("目标 \(String(format: "%.2g", plan.targetHours))小时", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Label("工作 \(plan.workDays)天", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Label("单次 \(viewModel.formatWorkDuration(plan.workDurationMinutes))", systemImage: "timer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                var completeHour = viewModel.getCompletedHours(plan)
                Label("已完成 \(String(format: "%.2g", completeHour))小时(\(String(format: "%.2g",completeHour/plan.targetHours * 100))%)",
                      systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
        }
        .padding(.vertical, 8)
    }
}

struct WorkPlanListView: View {
    @StateObject private var viewModel = WorkPlanListViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.plans, id: \.id) { plan in
                WorkPlanItemView(plan: plan, viewModel: viewModel)
                    .onAppear {
                        if plan == viewModel.plans.last {
                            viewModel.loadNextPage()
                        }
                    }
            }
        }
        .listStyle(InsetListStyle())
        .navigationTitle("工作计划")
        .onAppear {
            viewModel.refresh()
        }
    }
}

#Preview {
    WorkPlanListView()
}
