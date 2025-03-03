//
//  AISettingsView.swift
//  WorkMind
//
//  Created by Feng Ji on 2025/3/3.
//
import SwiftUI

// AI服务设置视图
struct AISettingsView: View {
    @Binding var apiKey: String
    @Binding var modelName: String
    @Binding var inputPrompt: String
    @Binding var systemPrompt: String
    @Binding var apiChannel: APIChannel
    @Binding var apiEndpoint: String
    @Binding var temperature: Double
    
    var body: some View {
        Form {
            Section(header: Text("AI服务设置").bold()) {
                let apiChannels = APIChannel.allCases
                Picker("API通道", selection: $apiChannel) {
                    ForEach(apiChannels, id: \.self) { channel in
                        Text(channel.displayName).tag(channel)
                    }
                }
                .onChange(of: apiChannel) { oldValue, newValue in
                    AIService.shared.aiChannel = newValue
                    apiKey = AIService.shared.apiKey
                    modelName = AIService.shared.modelName
                }
                .padding(.vertical, 4)
                
                HStack {
                    TextField("模型名称", text: $modelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: modelName) { oldValue, newValue in
                            AIService.shared.modelName = newValue
                        }
                }
                .padding(.vertical, 4)
                
                if apiChannel != .ollama {
                    HStack {
                        TextField("API密钥", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: apiKey) { oldValue, newValue in
                                AIService.shared.apiKey = newValue
                            }
                    }
                    .padding(.vertical, 4)
                } else if apiChannel == .ollama {
                    HStack {
                        TextField("API域名", text: $apiEndpoint)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: apiEndpoint) { oldValue, newValue in
                                AIService.shared.apiEndpoint = newValue
                            }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("提示词设置").bold()) {
                HStack {
                    Slider(value: $temperature, in: 0...2, step: 0.05) {
                        Text("Temperature")
                    }.onChange(of: temperature) { oldValue, newValue in
                        AIService.shared.temperature = newValue
                    }
                    Text(temperature, format: .number.precision(.fractionLength(2)))
                }
                .padding(.vertical, 4)
                
                HStack(alignment: .top) {
                    TextEditor(text: $systemPrompt)
                        .frame(height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                        .onChange(of: systemPrompt) { oldValue, newValue in
                            AIService.shared.systemPrompt = newValue
                        }.overlay(alignment: .topLeading, content: {
                            Text("系统Prompt")
                                .frame(width: 100, alignment: .leading).offset(CGSize(width: -80,height: 0))
                        })
                }
                .padding(.vertical, 4)
                
                HStack(alignment: .top) {
                    TextEditor(text: $inputPrompt)
                        .frame(height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                        .onChange(of: inputPrompt) { oldValue, newValue in
                            AIService.shared.inputPrompt = newValue
                        }.overlay(alignment: .topLeading, content: {
                            Text("输入Prompt")
                                .frame(width: 100, alignment: .leading).offset(CGSize(width: -80,height: 0))
                        })
                }
                .padding(.vertical, 4)
            }
        }
    }
}
