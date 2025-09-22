//
//  ChatView.swift
//  MessagingApp
//
//  Created by Sam on 21/5/25.
//

import Foundation
import SwiftUI

import Combine
import PhotosUI

struct ChatView: View {
    @State private var lastContentOffset: CGFloat = 0
    @State private var isScrollingUp: Bool = false
    
    @State var viewModel: ChatViewModel
    @FocusState private var isFocused: Bool
    
    private let didCreateMessageListView: (Binding<Bool>, Binding<Int?>, Binding<[MessageGroup]>, FocusState<Bool>.Binding) -> MessageListView
    
    init(
        viewModel: ChatViewModel,
        didCreateMessageListView: @escaping (Binding<Bool>, Binding<Int?>, Binding<[MessageGroup]>, FocusState<Bool>.Binding) -> MessageListView
    ) {
        self.viewModel = viewModel
        self.didCreateMessageListView = didCreateMessageListView
    }
    
    var body: some View {
        VStack {
            Text("Sender: \(viewModel.sender)")
            Text("Receiver: \(viewModel.receiver)")
            didCreateMessageListView(
                $viewModel.reachedTop,
                $viewModel.lastMessageId,
                $viewModel.messages,
                $isFocused
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
