//
//  SettingView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/21.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject private var vm: ViewModel
    @State private var cacheSize: String = "计算中..."
    @State private var showingClearCacheAlert = false
    @State private var downloadOriginal: Bool = false
    
    
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    Section(header: Text("下载设置")) {
                        Toggle("下载原始图片", isOn: $vm.downloadOriginal)
                            .onChange(of: vm.downloadOriginal) { newValue in
                                print("downloadOriginal 更新为: \(newValue)")
                            }
                        
                    }
                    
                    Section {
                        Text("更新时提示")
                        Text("联系我")
                        HStack {
                            Button("清除缓存") {
                                showingClearCacheAlert = true
                            }
                            Spacer()
                            Text(cacheSize)
                                .foregroundColor(.gray)
                        }
                    }
                    Section(header: Text("关于应用")) {
                        HStack {
                            Text("版本信息")
                            Spacer()
                            Text(Configuration.versionAndBuild)
                                .foregroundColor(.gray)
                        }
                        Text("反馈与支持")
                    }
                }
                .navigationTitle("Setting")
                .onAppear {
                    updateCacheSize()
                }
                .alert("确认清除缓存", isPresented: $showingClearCacheAlert) {
                    Button("取消", role: .cancel) { }
                    Button("确认清除", role: .destructive) {
                        clearCache()
                    }
                } message: {
                    Text("清除缓存将删除所有临时文件。这可能会暂时影响应用性能，但不会删除任何重要数据。")
                }
            }
            
            VStack {
                Spacer()
                Text("Build Version: \(Configuration.versionAndBuild)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 12)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func updateCacheSize() {
        cacheSize = vm.readCacheSize()
    }
    
    private func clearCache() {
        vm.clearCache()
        updateCacheSize()
    }
}

#Preview {
    let container = PreviewContainer()
    return SettingView()
        .environmentObject(container.createViewModel())
        .modelContainer(container.container)
}
