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
    @State private var selectedTopic:Topic?
    
    
    var body: some View {
        NavigationStack{
            ScrollView {
                ForEach(vm.topics, id: \.id) { topic in
                    VStack(alignment: .leading,spacing: 16) {
                        VStack(alignment: .leading, spacing:6) {
                            Text(topic.slug.capitalized)
                                .font(.title2)
                                .bold()
                                .onTapGesture {
                                    selectedTopic = topic
                                }
                            Text(topic.topicDescription ?? "No description available")
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing,16)
                        if let photos = vm.topicPhotos[topic.id], !photos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(photos.prefix(6), id: \.id) { photo in
                                        NavigationLink(destination: DetailView(photo: photo).toolbar(.hidden,for: .tabBar)) {
                                            TopicPhotoView(photo: photo)
                                                .environmentObject(vm)
                                        }
                                    }
                                }
                            }
                        } else {
                            ProgressView("加载图片中...")
                        }
                    }
                    .padding(.top,12)
                    .padding(.leading,16)
                    .onAppear {
                        Task {
                            await vm.fetchTopicPhotos(topic: topic, page: 1)
                        }
                    }
                }
            }
            .navigationBarTitle("Topics")
        }
        .sheet(item: $selectedTopic) { topic in
            TopicDatailView(topic: topic)
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
        KFImage(URL(string: photo.urls.thumb))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 140,height: 200)
            .clipped()
            .cornerRadius(10)
    }
}

#Preview {
    let container = PreviewContainerTopic()
    return TopicsView()
        .environmentObject(container.createViewModel())
        .modelContainer(container.container)
}
