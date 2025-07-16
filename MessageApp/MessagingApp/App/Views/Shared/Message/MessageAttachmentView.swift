//
//  MessageAttachmentView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI

struct MessageAttachmentView: View {
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "newspaper")
                .padding()
                .background(Color.red)
                .clipShape(Circle())
            VStack {
                Text("File title")
                    .font(.title)
                Text("File size")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.5))
        .clipShape(.rect(cornerRadius: 20))
    }
}

#Preview {
    MessageAttachmentView()
}
