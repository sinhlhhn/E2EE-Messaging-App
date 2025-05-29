//
//  MessageListView.swift
//  MessagingApp
//
//  Created by Sam on 20/5/25.
//

import SwiftUI

struct MessageListView: View {
    @Binding var reachedTop: Bool
    @Binding var previousId: Int?
    @Binding var messages: [Message]
    @FocusState<Bool>.Binding var isFocused: Bool
    @State private var isScrollUp: Bool = false
    
    var body: some View {
        ScrollViewReader { proxy in
            if reachedTop {
                ProgressView()
            }
            List(messages) { message in
                HStack {
                    if message.isFromCurrentUser {
                        Spacer()
                    }
                    MessageView(content: message.content)
                        .onAppear {
                            if message.messageId == messages.first?.messageId, isScrollUp {
                                reachedTop = true
                            }
                        }
                }
                .id(message.messageId)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .onChange(of: messages, { _, _ in
                //TODO: If the user is scrolling up, do not scroll to the bottom.
                scrollToBottom(proxy)
            })
            .onChange(of: isFocused, { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    scrollToBottom(proxy)
                }
            })
            .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
                    geometry.contentOffset.y
                }, action: { oldValue, newValue in
                    if oldValue == newValue { return }
                    if newValue > oldValue {
                        isScrollUp = false
                    } else {
                        isScrollUp = true
                    }
                })
            .scrollContentBackground(.hidden)
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(previousId)
        }
    }
}

#Preview {
    @Previewable @FocusState var isFocused: Bool
    MessageListView(reachedTop: Binding.constant(false), previousId: Binding.constant(0), messages: Binding.constant(mockMessages), isFocused: $isFocused)
}
