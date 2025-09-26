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
    
    private func createSingleGroupMessageView(_ group: MessageGroup) -> some View {
        SingleGroupMessageView(
            group: group,
            fullScreenImage: $fullScreenImage,
            cacheImage: viewModel.image(forKey: group.id),
            nsAnimation: nsAnimation,
            didCreateMessageVideoView: { data in
                MessageVideoView(viewModel: didCreateMessageVideoViewModel(data))
            },
            didCreateMessageAttachmentView: { data in
                MessageAttachmentView(viewModel: didCreateMessageAttachmentViewModel(data)) { url in
                    didDisplayDocument(url)
                }
            }, didCreateMessageImageView: createMessageImageView,
            didSelectImageView: selectImage
        )
    }
    
    private func createMultipleGroupMessageView(_ group: MessageGroup) -> some View {
        MultipleGroupMessageView(
            message: group,
            nsAnimation: nsAnimation,
            fullScreenGroupImage: $fullScreenGroupImage,
            cacheImage: caches[group.id],
            didSelectGroupImage: selectGroupImage,
            didCreateFannedGroupMessageImageView: { data, message in
                FannedGroupMessageImageView(viewModel: didCreateGroupMessageImageViewModel(data)) { images in
                    selectGroupImage(images, id: message.id.uuidString)
                } didCompleteDisplayImage: { images in
                    debugPrint("[Cached] Group Image Message \(message.id.uuidString)")
                    caches[message.groupId] = images
                }
            })
//            .id(messages.first?.id)
    }
    
    private func selectGroupImage(_ images: [UIImage], id: String) {
        withAnimation {
            self.selectedGroupId = id
            self.fullScreenGroupImage = images
        }
    }
    
    @ViewBuilder
    private func createMessageImageView(data: ImageMessage, message: Message) -> MessageImageView {
        MessageImageView(geoEffectId: message.id.uuidString, nsAnimation: nsAnimation, viewModel: didCreateMessageImageViewModel(data)) { image in
            selectImage(message.id, image: image)
        } didCompleteDisplayImage: { image in
            viewModel.insertImage(image, forKey: message.groupId ?? message.id)
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
