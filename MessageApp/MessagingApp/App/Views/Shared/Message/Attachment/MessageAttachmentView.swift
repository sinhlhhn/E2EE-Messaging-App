//
//  MessageAttachmentView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI

struct MessageAttachmentView: View {
    
    @State private var viewModel: MessageAttachmentViewModel
    
    init(viewModel: MessageAttachmentViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView()
            case .completed(let fileSize):
                HStack(alignment: .top) {
                    Image(systemName: "newspaper")
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text(viewModel.originalName)
                            .font(.title)
                            .lineLimit(1)
                        Text(fileSize)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.5))
                .clipShape(.rect(cornerRadius: 20))
            }
        }.task {
            viewModel.getData()
        }
    }
}

//#Preview {
//    MessageAttachmentView(fileTitle: "File title", fileSize: "File size")
//}
