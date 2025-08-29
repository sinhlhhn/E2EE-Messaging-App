//
//  MessageAttachmentView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI

struct MessageAttachmentView: View {
    
    @State private var viewModel: MessageAttachmentViewModel
    
    private let didTapItem: (URL) -> Void
    
    init(viewModel: MessageAttachmentViewModel, didTapItem: @escaping (URL) -> Void) {
        self.viewModel = viewModel
        self.didTapItem = didTapItem
    }
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView()
            case .completed(let fileSize):
                HStack(alignment: .top) {
                    Image(systemName: "newspaper")
                        .padding(.all, 8)
                        .background(Color.red)
                        .clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text(viewModel.originalName)
                            .font(.title3)
                            .lineLimit(1)
                        Text(fileSize)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.5))
                .clipShape(.rect(cornerRadius: 20))
                .highPriorityGesture(
                    TapGesture().onEnded {
                        didTapItem(viewModel.getDestinationURL() ?? URL(string: "")!)
                    }
                )
            }
        }.task {
            viewModel.getData()
        }
    }
}
