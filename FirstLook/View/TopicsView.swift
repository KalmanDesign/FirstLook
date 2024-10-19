//
//  TopicsView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/19.
//

import SwiftUI
import Kingfisher

struct TopicsView: View {
    @EnvironmentObject private var vm: ViewModel
    @State private var needsRefresh = true

    var body: some View {
        ScrollView {
            ForEach(vm.topics, id: \.id) { topic in
                VStack(alignment: .leading) {
                    Text(topic.slug)
                        .font(.largeTitle)
                    Text(topic.topicDescription ?? "No description available")
                        .font(.subheadline)
                    
                    if let photos = vm.topicPhotos[topic.id], !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(photos.prefix(6), id: \.id) { photo in
                                    TopicPhotoView(photo: photo)
                                        .environmentObject(vm)
                                }
                            }
                        }
                    } else {
                        ProgressView("加载图片中...")
                    }
                }
                .onAppear {
                    Task {
                        await vm.fetchTopicPhotos(topic: topic)
                    }
                }
            }
        }
        .onAppear {
            print("TopicsView appeared")
            vm.loadFavoritePhotos()
        }
    }
}

struct TopicPhotoView: View {
    @EnvironmentObject private var vm: ViewModel
    let photo: TopicPhoto
    
    var body: some View {
        KFImage(URL(string: photo.urls.regular))
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .cornerRadius(10)
            .overlay(alignment: .topTrailing) {
                Button {
                    print("收藏按钮被点击，照片 ID: \(photo.id)")
                    vm.toggleFavorite(photo)
                } label: {
                    Image(systemName: photo.isFavorite ?? false ? "heart.fill" : "heart")
                        .foregroundColor(photo.isFavorite ?? false ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(8)
            }
    }
}

#Preview {
    let container = PreviewContainerTopic()
    return TopicsView()
        .environmentObject(container.createViewModel())
        .modelContainer(container.container)
}
