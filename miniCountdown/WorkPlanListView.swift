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
                Label("目标时长: \(String(format: "%.1f", plan.targetHours))小时", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("工作天数: \(plan.workDays)天", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Label("单次时长: \(viewModel.formatWorkDuration(plan.workDurationMinutes))", systemImage: "timer")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    }
}

#Preview {
    WorkPlanListView()
}
