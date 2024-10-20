//
//  AppleAppGirdView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/20.
//

import SwiftUI

enum AppleIcon: String, CaseIterable {
    case appStore = "AppStore"
    case books = "Books"
    case calculator = "Calculator"
    case calendar = "Calendar"
    case camera = "Camera"
    case clock = "Clock"
    case compass = "Compass"
    case contacts = "Contacts"
    case faceTime = "FaceTime"
    case files = "Files"
    case findMy = "Find My"
}


struct AppleAppGirdView: View {
    let columns = 4
    let horizontalSpacing: CGFloat = 8
    let verticalSpacing: CGFloat = 24 // 增加这个值来增加行间距
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (horizontalSpacing * CGFloat(columns - 1)) - 32 // 32 为左右padding
            let itemWidth = availableWidth / CGFloat(columns)
            
            ScrollView {
                Grid(horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing) {
                    ForEach(0..<(AppleIcon.allCases.count + columns - 1) / columns, id: \.self) { row in
                        GridRow {
                            ForEach(0..<columns, id: \.self) { column in
                                let index = row * columns + column
                                if index < AppleIcon.allCases.count {
                                    iconImage(image: AppleIcon.allCases[index].rawValue, width: itemWidth)
                                } else {
                                    Color.clear.frame(width: itemWidth, height: itemWidth)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct iconImage: View {
    let image: String
    let width: CGFloat
    
    var body: some View {
        VStack {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.6, height: width * 0.6)
                .shadow(radius: 10) // 添加投影
            Text(image)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.white)
                .shadow(radius: 10) // 添加投影
            
        }
        .frame(width: width, height: width)
    }
}

#Preview {
    AppleAppGirdView()
}
