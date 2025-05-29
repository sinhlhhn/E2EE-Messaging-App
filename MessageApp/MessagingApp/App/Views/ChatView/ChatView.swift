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
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            Text("Sender: \(viewModel.sender)")
            Text("Receiver: \(viewModel.receiver)")
            MessageListView(reachedTop: $viewModel.reachedTop, previousId: $viewModel.lastMessageId, messages: $viewModel.messages, isFocused: $isFocused)
                .onTapGesture {
                    isFocused = false
                }
            MessageTextField() { text in
                viewModel.sendMessage(text)
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

#Preview {
    ChatView(viewModel: ChatViewModel(sender: "slh", receiver: "", service: NullSocketService<String, TextMessage>(), messageService: NullMessageService(), didTapBack: {}))
}
