//
//  MessageView.swift
//  MessagingApp
//
//  Created by Sam on 20/5/25.
//

import SwiftUI

struct MessageView: View {
    private let content: String
    private let shadowColor: Color
    private let shadowRadius: CGFloat
    
    init(
        content: String,
        shadowColor: Color = .gray,
        shadowRadius: CGFloat = 5
    ) {
        self.content = content
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        contentView
    }
    
    private var contentView: some View {
        Text(content)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .stroke(.gray)
            )
            .shadow(color: shadowColor, radius: shadowRadius)
    }
}

#Preview {
    MessageView(content: "This is a short message.")
        .padding()
    MessageView(content: "This is a very long long long long long message.")
        .padding()
}
