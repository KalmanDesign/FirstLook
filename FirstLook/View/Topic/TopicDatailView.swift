//
//  TopicDatailView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/20.
//

import SwiftUI
import Kingfisher
import WaterfallGrid

// 定义TopicDatailView结构体，遵循View协议
struct TopicDatailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var vm: ViewModel
    let topic: Topic
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading ,spacing: 12) {
                TopicCover(photo: vm.topicPhotos[topic.id]?.first)
                    .frame(height: 200)
                    .overlay(alignment: .bottomLeading) {
                        Text(topic.slug.capitalized)
                            .bold()
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                    }
                
                Text(topic.topicDescription ?? "No description available")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    
                
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(vm.topicPhotos[topic.id] ?? [], id: \.uniqueIdentifier) { photo in
                        NavigationLink(destination: ImageDetailView(photo: photo).navigationBarBackButtonHidden(true)) {
                            GeometryReader { geometry in
                                KFImage(URL(string: photo.urls.small))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.width * 4/3)
                                    .clipped()
                                    .cornerRadius(10)
                            }
                            .aspectRatio(3/4, contentMode: .fit)
                        }
                        .onAppear {
                            if photo == vm.topicPhotos[topic.id]?.last {
                                Task {
                                    await vm.loadMoreTopicPhotos(for: topic)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                if vm.isLoadingMore {
                    ProgressView()
                        .padding()
                } else if !vm.canLoadMorePages(for: topic) {
                    VStack(spacing: 8) {
                        Text("您已经浏览了3页内容")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        if !vm.isVIP {
                            Button("升级到 VIP 以查看更多内容") {
                                // vm.purchaseVIP()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .background(Color.black)
    }
}

struct TopicCover: View {
    let photo: TopicPhoto?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if let photo = photo, let imageURL = URL(string: photo.urls.regular) {
            KFImage(imageURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, overlayColor]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                )
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, overlayColor]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    private var overlayColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
}

// 预览TopicDatailView
#Preview {
    let container = PreviewContainerTopic()
    
    TopicDatailView(topic: Topic(id: "2", slug: "3432"))
        .environmentObject(container.createViewModel())
        .modelContainer(container.container)
}
