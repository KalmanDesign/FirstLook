//
//  TopicsView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/19.
//

import SwiftUI
import Kingfisher

// MARK: - 主视图
struct TopicsView: View {
    @EnvironmentObject private var vm: ViewModel
    @State private var selectedTopic: Topic?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.topics, id: \.id) { topic in
                        topicSection(for: topic)
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationBarTitle("Topics")
        }
        .sheet(item: $selectedTopic) { topic in
            TopicDatailView(topic: topic)
        }
        .onAppear {
            vm.loadFavoritePhotos()
        }
    }
    
    // MARK: - 主题区块
    private func topicSection(for topic: Topic) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            topicPhotos(for: topic)
        }
    }
    
    // MARK: - 主题照片
    private func topicPhotos(for topic: Topic) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(vm.topicPhotos[topic.id, default: []].prefix(6).enumerated()), id: \.element.id) { index, photo in
                    if index == 0 {
                        NavigationLink(destination: TopicDatailView(topic: topic).toolbar(.hidden, for: .tabBar)) {
                            topicPhotoView(photo: photo, isFirstPhoto: true, topic: topic)
                        }
                    } else {
                        NavigationLink(destination: ImageDetailView(photo: photo).toolbar(.hidden, for: .tabBar)) {
                            topicPhotoView(photo: photo, isFirstPhoto: false, topic: nil)
                        }
                    }
                }
                
                // 添加灰色矩形
                NavigationLink(destination: TopicDatailView(topic: topic).toolbar(.hidden, for: .tabBar)) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 200)
                        .cornerRadius(16)
                        .overlay(
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .onAppear {
            if vm.topicPhotos[topic.id] == nil {
                Task {
                    await vm.fetchTopicPhotos(topic: topic, page: 1)
                }
            }
        }
    }
    
    // MARK: - 主题照片视图
    private func topicPhotoView(photo: TopicPhoto, isFirstPhoto: Bool, topic: Topic?) -> some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(URL(string: photo.urls.thumb))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: isFirstPhoto ? UIScreen.main.bounds.width / 2 + 80 : 140, height: isFirstPhoto ? 200 : 200)
                .clipped()
                .cornerRadius(16)
                .overlay(
                    Group {
                        if isFirstPhoto, let topic = topic {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic.slug.capitalized)
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                Text(topic.topicDescription ?? "No description available")
                                    .font(.callout)
                                    .lineLimit(1)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .cornerRadius(16)

                            )
                        }
                    }
                )
        }
    }
}

#Preview {
    let container = PreviewContainerTopic()
    return TopicsView()
        .environmentObject(container.createViewModel())
        .modelContainer(container.container)
}
