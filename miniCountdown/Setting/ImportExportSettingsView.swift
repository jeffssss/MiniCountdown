//
//  ImportExportSettingsView.swift
//  miniCountdown
//
//  Created by AI Assistant on 2023/6/15.
//

import SwiftUI

// 导入导出设置视图
struct ImportExportSettingsView: View {
    @Binding var showImportPicker: Bool
    @Binding var showExportPicker: Bool
    @Binding var errorMessage: String
    @Binding var showErrorAlert: Bool
    
    // 添加状态更新回调
    var onSettingsUpdated: () -> Void
    
    var body: some View {
        Form {
            Section(header: Text("导入导出设置").bold()) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("您可以导出当前所有设置到JSON文件，或从之前导出的JSON文件中导入设置。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            showImportPicker = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("导入设置")
                            }
                            .frame(minWidth: 120)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            showExportPicker = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("导出设置")
                            }
                            .frame(minWidth: 120)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("导入说明：")
                            .font(.subheadline)
                            .bold()
                        
                        Text("1. 导入设置将覆盖当前所有设置项")
                            .font(.caption)
                        Text("2. 导入后需要重新启动应用以确保所有设置生效")
                            .font(.caption)
                        Text("3. 请确保导入的设置文件格式正确")
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.vertical, 8)
            }
        }
        .fileExporter(
            isPresented: $showExportPicker,
            document: JSONDocument(initialText: ""),
            contentType: .json,
            defaultFilename: "settings.json"
        ) { result in
            handleExport(result)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }
    
    // 导入设置文件处理
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                do {
                    try SettingsManager.shared.importFromFile(url: url)
                    onSettingsUpdated()
                } catch {
                    errorMessage = "导入设置失败: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        case .failure(let error):
            errorMessage = "选择文件失败: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    // 导出设置文件处理
    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try SettingsManager.shared.exportToFile(url: url)
            } catch {
                errorMessage = "导出设置失败: \(error.localizedDescription)"
                showErrorAlert = true
            }
        case .failure(let error):
            errorMessage = "选择保存位置失败: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

#Preview {
    ImportExportSettingsView(
        showImportPicker: .constant(false),
        showExportPicker: .constant(false),
        errorMessage: .constant(""),
        showErrorAlert: .constant(false),
        onSettingsUpdated: {  }
    )
}
