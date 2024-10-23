//
//  UpgradeButtonView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/23.
//

import SwiftUI

struct UpgradeButtonView: View {
    let title: String
    let action: () -> Void
    var backgroundColor: Color = .white
    var textColor: Color = .black
    var height: CGFloat = 48
    var cornerRadius: CGFloat = 22
    var icon: Image?
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                Text(title)
                    .bold()
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius)
        }
    }
}

extension UpgradeButtonView {
    static func pro(action: @escaping () -> Void) -> UpgradeButtonView {
        UpgradeButtonView(title: "升级到 PRO", action: action, backgroundColor: .white, textColor: .black)
    }
    
    static func vip(action: @escaping () -> Void) -> UpgradeButtonView {
        UpgradeButtonView(title: "成为 VIP", action: action, backgroundColor: .white, textColor: .black)
    }
    
    static func custom(title: String, icon: Image?, action: @escaping () -> Void, backgroundColor: Color = .blue, textColor: Color = .white) -> UpgradeButtonView {
        UpgradeButtonView(title: title, action: action, backgroundColor: backgroundColor, textColor: textColor, icon: icon)
    }
}



#Preview {
    UpgradeButtonView(title: "升级到 PRO，查看更多内容。", action:{
        print("Purchase tapped")
    })
}
