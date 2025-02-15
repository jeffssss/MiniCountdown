import SwiftUI

struct APIRequestItemView: View {
    let record: APIRequestRecord
    let viewModel: APIRequestListViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.formatDate(record.requestTime))
                    .font(.subheadline)
                
                Spacer()
                
                Text("模型: " + record.modelName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("输入: " + record.inputPrompt)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text("输出: " + (record.output ?? ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                Label("耗时: " + viewModel.formatDuration(record.requestDuration), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("Token: " + viewModel.formatTokens(record.totalTokens), systemImage: "number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct APIRequestListView: View {
    @StateObject private var viewModel = APIRequestListViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.records, id: \.id) { record in
                APIRequestItemView(record: record, viewModel: viewModel)
                    .onAppear {
                        if record == viewModel.records.last {
                            viewModel.loadNextPage()
                        }
                    }
            }
        }
        .listStyle(InsetListStyle())
        .navigationTitle("AI请求记录")
    }
}

#Preview {
    APIRequestListView()
}
