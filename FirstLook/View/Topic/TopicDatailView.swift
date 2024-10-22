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
    
    // 定义body属性，用于描述视图的内容
    var body: some View {
        ScrollView {
            ZStack{
                VStack(alignment: .leading){
                    TopicCover(photo: vm.topicPhotos[topic.id]?.randomElement())
                        .overlay(alignment: .bottomLeading) {
                            Text(topic.slug.capitalized)
                                .bold()
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                        }
                    Text(topic.topicDescription ?? "dasiudhuiashdias")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    WaterfallGrid(vm.topicPhotos[topic.id] ?? []) { photo in
                        NavigationLink(destination: ImageDetailView(photo: photo).navigationBarBackButtonHidden(true)) {
                            KFImage(URL(string: photo.urls.regular)!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                }
                .frame(minWidth: UIScreen.main.bounds.width, alignment: .leading)
            }
        }
        .edgesIgnoringSafeArea(.all)
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
                .frame(height: 320)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, overlayColor]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipped()
        }  else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 320)
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
