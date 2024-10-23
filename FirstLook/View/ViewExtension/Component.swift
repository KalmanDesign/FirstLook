//
//  Component.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/23.
//

import SwiftUI

extension View{
    func normalButton(
        title: String,
        action: @escaping () -> Void,
        backgroundColor:Color = .white,
        textColor: Color = .black
    ) -> some View{
        self.overlay {
            Button(action: action) {
                Text(title)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(360)
                    .font(.subheadline)
            }
            .padding()
        }
    }
}
