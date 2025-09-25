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
    @FocusState<Bool>.Binding var isFocused: Bool
    @State private var isScrollUp: Bool = false
    // if we use @State here, we cannot connect the `messages` between `MessageListViewModel` and `ChatViewModel`
    // if we use the @Bindable, the MessageListViewModel will be reloaded each time the MessageListView reloads. So we cannot create internal mutable data inside `MessageListViewModel` and use it because its states is also be reloaded to init state.
    @State private var viewModel: MessageListViewModel
    @Binding var messages: [MessageGroup]
    @State private var caches: [UUID?: [UIImage]] = [:]
    
    // Image
    @State private var selectedId: String?
    @State private var selectedGroupId: String?
    @State private var fullScreenImage: UIImage?
    @State private var fullScreenGroupImage: [UIImage] = []
    @Namespace private var nsAnimation
    
    private var didCreateMessageAttachmentViewModel: ((AttachmentMessage) -> MessageAttachmentViewModel)
    private var didCreateMessageImageViewModel: ((ImageMessage) -> MessageImageViewModel)
    private var didCreateGroupMessageImageViewModel: (([ImageMessage]) -> GroupMessageImageViewModel)
    private var didCreateMessageVideoViewModel: ((VideoMessage) -> MessageVideoViewModel)
    private var didDisplayDocument: ((URL) -> Void)
    
    init(
        reachedTop: Binding<Bool>,
        previousId: Binding<Int?>,
        isFocused: FocusState<Bool>.Binding,
        viewModel: MessageListViewModel,
        messages: Binding<[MessageGroup]>,
        didCreateMessageAttachmentViewModel: @escaping (AttachmentMessage) -> MessageAttachmentViewModel,
        didCreateMessageImageViewModel: @escaping (ImageMessage) -> MessageImageViewModel,
        didCreateGroupMessageImageViewModel: @escaping ([ImageMessage]) -> GroupMessageImageViewModel,
        didCreateMessageVideoViewModel: @escaping (VideoMessage) -> MessageVideoViewModel,
        didDisplayDocument: @escaping (URL) -> Void
    ) {
        self._reachedTop = reachedTop
        self._previousId = previousId
        self._isFocused = isFocused
        self._messages = messages
        self.viewModel = viewModel
        self.didCreateMessageAttachmentViewModel = didCreateMessageAttachmentViewModel
        self.didCreateMessageImageViewModel = didCreateMessageImageViewModel
        self.didCreateGroupMessageImageViewModel = didCreateGroupMessageImageViewModel
        self.didCreateMessageVideoViewModel = didCreateMessageVideoViewModel
        self.didDisplayDocument = didDisplayDocument
    }
    
    private func createSingleGroupMessageView(_ group: MessageGroup) -> some View {
        ForEach(group.messages) { message in
            HStack {
                if message.isFromCurrentUser {
                    Spacer()
                }
                createMessageView(message)
                    .flippedUpsideDown()
                    .id(message.id)
            }
        }
    }
    
    @ViewBuilder
    private func createMultipleGroupMessageView(_ group: MessageGroup) -> some View {
        let images: [ImageMessage] = group.messages.compactMap {
            if case let .image(image) = $0.type {
                return ImageMessage(path: image.path, originalName: image.originalName)
            }
            return nil
        }
        if let message = group.messages.first {
            HStack {
                if group.isFromCurrentUser == true {
                    Spacer()
                }
                
                createGroupImageMessage(data: images, message: message)
                    .flippedUpsideDown()
                    .id(messages.first?.id)
            }
        }
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(messages, id: \.id) { group in
                        if group.messages.count == 1 {
                            createSingleGroupMessageView(group)
                        } else {
                            createMultipleGroupMessageView(group)
                        }
                    }
                    .listRowSeparator(.hidden)
                    
                    //TODO: move logic to other place
                    if messages.last?.lastestMessageId != 1 && !messages.isEmpty {
                        ListProgressView()
                            .flippedUpsideDown()
                            .listRowSeparator(.hidden)
                            .onAppear {
                                reachedTop = true
                            }
                    }
                }
                .flippedUpsideDown()
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
            
            if !fullScreenGroupImage.isEmpty, let selectedGroupId = selectedGroupId {
                FullScreenGroupMessageImageView(images: fullScreenGroupImage, geoEffectId: selectedGroupId, nsAnimation: nsAnimation)
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            withAnimation {
                                self.fullScreenGroupImage = []
                            }
                        })
                    .zIndex(1)
            }
        }
    }
    
    @ViewBuilder
    private func createMessageView(_ message: Message) -> some View {
        switch message.type {
        case .text(let data):
            MessageView(content: data.content)
                .frame(maxWidth: .infinity, alignment: message.isFromCurrentUser ? .trailing : .leading)
                .padding(message.isFromCurrentUser ? .leading : .trailing, 16)
        case .video(let data):
            MessageVideoView(viewModel: didCreateMessageVideoViewModel(data))
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 200, height: 300)
        case .image(let image):
            createSingleImageMessage(data: image, message: message)
        case .attachment(let data):
            MessageAttachmentView(viewModel: didCreateMessageAttachmentViewModel(data)) { url in
                didDisplayDocument(url)
            }
            .frame(maxWidth: 200, alignment: message.isFromCurrentUser ? .trailing : .leading)
        }
    }
    
    @ViewBuilder
    private func createGroupImageMessage(data: [ImageMessage], message: Message) -> some View {
        if !fullScreenGroupImage.isEmpty {
            FannedImageView(images: fullScreenGroupImage)
                .frame(width: 150, height: 150)
        } else if let images = caches[message.groupId] {
            FannedImageView(images: images)
                .matchedGeometryEffect(id: message.id.uuidString, in: nsAnimation)
                .frame(width: 150, height: 150)
                .highPriorityGesture(
                    TapGesture().onEnded {
                        selectGroupImage(images, message: message)
                    }
                )
        } else {
            FannedGroupMessageImageView(viewModel: didCreateGroupMessageImageViewModel(data)) { images in
                selectGroupImage(images, message: message)
            } didCompleteDisplayImage: { images in
                debugPrint("[Cached] Group Image Message \(message.id.uuidString)")
                caches[message.groupId] = images
            }
            .matchedGeometryEffect(id: message.id.uuidString, in: nsAnimation)
            .frame(width: 150, height: 150)
        }
    }
    
    private func selectGroupImage(_ images: [UIImage], message: Message) {
        withAnimation {
            self.selectedGroupId = message.id.uuidString
            self.fullScreenGroupImage = images
        }
    }
    
    @ViewBuilder
    private func createSingleImageMessage(data: ImageMessage, message: Message) -> some View {
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
            selectImage(id, image: image)
        } didCompleteDisplayImage: { image in
            viewModel.insertImage(image, forKey: id.uuidString)
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
