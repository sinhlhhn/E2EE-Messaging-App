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
    @State private var viewModel: MessageListViewModel = .init()
    
    // Image
    @State private var selectedId: String?
    @State private var fullScreenImage: UIImage?
    @Namespace private var nsAnimation
    
    var didCreateMessageAttachmentViewModel: ((AttachmentMessage) -> MessageAttachmentViewModel)
    var didCreateMessageImageViewModel: ((ImageMessage) -> MessageImageViewModel)
    var didCreateGroupMessageImageViewModel: (([ImageMessage]) -> GroupMessageImageViewModel)
    var didCreateMessageVideoViewModel: ((VideoMessage) -> MessageVideoViewModel)
    var didDisplayDocument: ((URL) -> Void)
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                if reachedTop {
                    ProgressView()
                }
                List(messages, id: \.self)  { message in
                    HStack {
                        if message.isFromCurrentUser {
                            Spacer()
                        }
                        createMessageView(message)
//                            .onAppear {
//                                if message.messageId == messages.first?.messageId, isScrollUp {
//                                    reachedTop = true
//                                }
//                            }
                    }
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
            
            if let fullScreenImage = fullScreenImage, let selectedId = selectedId {
                FullScreenMessageImageView(image: fullScreenImage, geoEffectId: selectedId, nsAnimation: nsAnimation)
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            withAnimation {
                                self.fullScreenImage = nil
                            }
                        })
                    .zIndex(1) // During the transition, SwiftUI may assign a higher zIndex to the list because the full-size image is removed from the view hierarchy. To prevent the list from overlapping the full-size image, we manually set the zIndex to ensure the full-size image stays on top until the transition completes.
            }
        }
    }
    
    @ViewBuilder
    private func createMessageView(_ message: Message) -> some View {
        switch message.type {
        case .text(let data):
            MessageView(content: data.content)
                .frame(maxWidth: 200, alignment: message.isFromCurrentUser ? .trailing : .leading)
        case .video(let data):
            MessageVideoView(viewModel: didCreateMessageVideoViewModel(data))
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 200, height: 300)
        case .image(let images):
            if images.count == 1 {
                createSingleImageMessage(data: images[0], message: message)
            } else {
                createGroupImageMessage(data: images, message: message)
            }
        case .attachment(let data):
            MessageAttachmentView(viewModel: didCreateMessageAttachmentViewModel(data)) { url in
                didDisplayDocument(url)
            }
            .frame(maxWidth: 200, alignment: message.isFromCurrentUser ? .trailing : .leading)
        }
    }
    
    @ViewBuilder
    private func createGroupImageMessage(data: [ImageMessage], message: Message) -> some View {
        FannedGroupImageView(viewModel: didCreateGroupMessageImageViewModel(data))
    }
    
    @ViewBuilder
    private func createSingleImageMessage(data: ImageMessage, message: Message) -> some View {
        //TODO: -Handle display multiple image here. Create a new collection image view
        // This code is used to create a Hero animation for the image.
        // We have a thumbnail and a full-size image, and we want to create a Hero animation between them.
        // The process is as follows:
        //  - The app loads the image from disk.
        //  - When the user taps the thumbnail image, the image flies from the thumbnail to the full-size version.
        //  - When the user dismisses the full-size image, it flies back to the thumbnail.
        //
        // Issue:
        //  - The problem is that `matchedGeometryEffect` only allows one view with the same ID and `isSource = true` at a time.
        //    → To work around this, we create a placeholder and remove the thumbnail when transitioning to the full-size image.
        //  - Since the thumbnail is removed, we have to reload the image from disk. This introduces a delay,
        //    and we show a loading state to the user. However, this loading state prevents SwiftUI from recognizing
        //    the transition properly, resulting in a choppy animation.
        //    → To fix this, we implement a caching mechanism to avoid loading from disk, allowing SwiftUI to perform
        //    a smooth transition.
        if let fullScreenImage = fullScreenImage {
            Image(uiImage: fullScreenImage)
                .resizable()
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 200, height: 200)
        } else if let image = viewModel.image(forKey: message.id.uuidString) {
            CachedMessageImageView(image: image, geoEffectId: message.id.uuidString, nsAnimation: nsAnimation) { image in
                selectImage(message.id, image: image)
            }
            .frame(width: 200, height: 200)
        } else {
            createMessageImageView(data: data, id: message.id)
                .frame(width: 200, height: 200)
        }
    }
    
    @ViewBuilder
    private func createMessageImageView(data: ImageMessage, id: UUID) -> some View {        
        MessageImageView(geoEffectId: id.uuidString, nsAnimation: nsAnimation, viewModel: didCreateMessageImageViewModel(data)) { image in
            viewModel.insertImage(image, forKey: id.uuidString)
            selectImage(id, image: image)
        }
    }
    
    private func selectImage(_ id: UUID, image: UIImage) {
        withAnimation {
            selectedId = id.uuidString
            fullScreenImage = image
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(previousId)
        }
    }
}

//#Preview {
//    @Previewable @FocusState var isFocused: Bool
//    MessageListView(reachedTop: Binding.constant(false), previousId: Binding.constant(0), messages: Binding.constant(mockMessages), isFocused: $isFocused)
//}
