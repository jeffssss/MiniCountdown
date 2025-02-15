import SwiftUI

struct RecordItemView: View {
    let record: WorkMindRecord
    let viewModel: RecordListViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Text(viewModel.formatDate(record.startTime))
                .font(.subheadline)

            Spacer()

            Text("时间段 " + viewModel.formatTimeRange(record.startTime, record.endTime))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()

            Text("持续 " + viewModel.calculateDuration(record: record))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(viewModel.getStatusName(status: record.status))
                .font(.subheadline)
                .foregroundColor(getStatusColor(status: record.status))
        }
        .padding(.vertical, 4)
    }
    
    private func getStatusColor(status: Int16) -> Color {
        switch status {
        case CountdownStatus.running.rawValue:
            return .blue
        case CountdownStatus.completed.rawValue:
            return .green
        case CountdownStatus.interrupted.rawValue:
            return .red
        default:
            return .gray
        }
    }
}

struct RecordListView: View {
    @StateObject private var viewModel = RecordListViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.records, id: \.id) { record in
                RecordItemView(record: record, viewModel: viewModel)
                    .onAppear {
                        if record == viewModel.records.last {
                            viewModel.loadNextPage()
                        }
                    }
            }
        }
        .listStyle(InsetListStyle())
        .navigationTitle("记录明细")
        .onAppear {
            viewModel.refresh()
        }
    }
}

#Preview {
    RecordListView()
}
