//
//  ChatView.swift
//  MessagingApp
//
//  Created by Sam on 21/5/25.
//

import Foundation
import SwiftUI

import Combine

struct ChatView: View {
    @State private var lastContentOffset: CGFloat = 0
    @State private var isScrollingUp: Bool = false
    
    @Bindable var viewModel: ChatViewModel
    @FocusState private var isFocused: Bool
    
    private let didCreateMessageAttachmentViewModel: (AttachmentMessage) -> MessageAttachmentViewModel
    private let didCreateMessageImageViewModel: (ImageMessage) -> MessageImageViewModel
    
    init(
        viewModel: ChatViewModel,
        didCreateMessageAttachmentViewModel: @escaping (AttachmentMessage) -> MessageAttachmentViewModel,
        didCreateMessageImageViewModel: @escaping (ImageMessage) -> MessageImageViewModel
    ) {
        self.viewModel = viewModel
        self.didCreateMessageAttachmentViewModel = didCreateMessageAttachmentViewModel
        self.didCreateMessageImageViewModel = didCreateMessageImageViewModel
    }
    
    var body: some View {
        VStack {
            Text("Sender: \(viewModel.sender)")
            Text("Receiver: \(viewModel.receiver)")
            MessageListView(
                reachedTop: $viewModel.reachedTop,
                previousId: $viewModel.lastMessageId,
                messages: $viewModel.messages,
                isFocused: $isFocused,
                didCreateMessageAttachmentViewModel: didCreateMessageAttachmentViewModel,
                didCreateMessageImageViewModel: didCreateMessageImageViewModel
            )
                .onTapGesture {
                    isFocused = false
                }
            MediaMessageTextField(
                imageSelection: $viewModel.imageSelection) { attachmentURLs in
                    viewModel.sendAttachment(urls: attachmentURLs)
                    debugPrint(attachmentURLs)
                } didTapSend: { text in
                    viewModel.sendMessage(.text(.init(content: text)))
                }
            .focused($isFocused)
            .padding()
        }
        .clipped()
        .navigationBarBackButtonHidden()
        .toolbar{
            ToolbarItem(placement: .topBarLeading) {
                backBarButton
            }
        }
        .onAppear {
            viewModel.subscribe()
            viewModel.loadFirstMessage()
        }
        .onChange(of: viewModel.reachedTop) { oldValue, newValue in
            debugPrint("🟣 \(oldValue) - \(newValue)")
            if oldValue != newValue, newValue == true {
                debugPrint("🟣 start load more")
                viewModel.loadMoreMessages()
            }
        }
    }
    
    private var backBarButton: some View {
        Button {
            viewModel.reset()
        } label: {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }
}

//#Preview {
//    ChatView(viewModel: ChatViewModel(sender: "slh", receiver: "", service: NullSocketService<String, SocketMessage>(), uploadService: NullUserService(), messageService: NullMessageService(), didTapBack: {}))
//}
