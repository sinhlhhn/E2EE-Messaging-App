//
//  MessageView 2.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//


import SwiftUI

struct MessageImageView: View {
    private let image: String
    
    init(
        image: String
    ) {
        self.image = image
    }
    
    var body: some View {
        contentView
    }
    
    private var contentView: some View {
        Image(image)
            .resizable()
            .clipShape(.rect(cornerRadius: 10))
            .frame(maxWidth: 200, maxHeight: 400)
    }
}

#Preview {
    MessageImageView(image: "tiger")
}
