import Foundation
import CoreData
import AppKit
import SwiftUI

class WorkPlanListViewModel: ObservableObject {
    @Published var plans: [WorkPlanRecord] = []
    private var currentPage = 0
    private let pageSize = 20
    
    init() {
        loadPlans()
    }
    
    func loadPlans() {
        let newPlans = WorkMindManager.shared.getWorkPlans(page: 0, pageSize: pageSize)
        newPlans.forEach { plan in
            plan.completedHours = getCompletedHours(plan)
        }
        plans = newPlans
        currentPage = 0
    }
    
    func loadNextPage() {
        currentPage += 1
        let newPlans = WorkMindManager.shared.getWorkPlans(page: currentPage, pageSize: pageSize)
        if !newPlans.isEmpty {
            newPlans.forEach { plan in
                plan.completedHours = getCompletedHours(plan)
            }
            plans.append(contentsOf: newPlans)
        }
    }
    
    func refresh() {
        loadPlans()
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "--" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    func formatWorkDuration(_ minutes: Int32) -> String {
        return "\(minutes)分钟"
    }
    
    func getActiveStatus(_ isActive: Int16) -> String {
        return isActive >= 0 ? "有效" : "无效"
    }
    
    func getActiveStatusColor(_ isActive: Int16) -> Color {
        return isActive >= 0 ? .green : .red
    }
    
    func getCompletedHours(_ plan: WorkPlanRecord) -> Float {
        let total = WorkMindManager.shared.getCompletedTotalSeconds(planId: plan.id)
        return Float(total) / 3600.0
    }
}
