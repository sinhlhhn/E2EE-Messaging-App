//
//  MessageTextField.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI

struct MediaMessageTextField: View {
    @State private var text: String = ""
    @State private var isShowingMedia: Bool = true
    @State private var isPresentedAttachment: Bool = false
    
    private let didTapSend: (String) -> Void
    private let didSelectAttachments: ([URL]) -> Void
    
    fileprivate init(
        text: String,
        didSelectAttachments: @escaping ([URL]) -> Void,
        didTapSend: @escaping (String) -> Void
    ) {
        self.text = text
        self.didTapSend = didTapSend
        self.didSelectAttachments = didSelectAttachments
    }
    
    init(
        didSelectAttachments: @escaping ([URL]) -> Void,
        didTapSend: @escaping (String) -> Void
    ) {
        self.didTapSend = didTapSend
        self.didSelectAttachments = didSelectAttachments
    }
    
    var body: some View {
        HStack(alignment: .bottomAligned) {
            if isShowingMedia {
                mediaView
            }
            MessageTextField(text: text, didTapSend: { _ in
                isShowingMedia.toggle()
            })
            .opacity(0.5)
        }
        .animation(.linear, value: isShowingMedia)
    }
    
    private var mediaView: some View {
        Group {
            attachmentView
            imageView
        }
    }
    
    private var imageView: some View {
        Button {
            
        } label: {
            Image(systemName: "photo.badge.plus")
                .font(.title2)
        }
    }
    
    private var attachmentView: some View {
        Button {
            isPresentedAttachment = true
        } label: {
            Image(systemName: "paperclip")
                .font(.title2)
        }
        .fileImporter(isPresented: $isPresentedAttachment, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                urls.forEach { debugPrint($0.path) }
                didSelectAttachments(urls)
            case .failure(let failure):
                debugPrint("fileImporter with error: ", failure)
            }
        }
    }
}

#Preview {
    MediaMessageTextField(text: "", didSelectAttachments: { _ in }, didTapSend: { _ in })
        .padding()
    MediaMessageTextField(text: "Short text", didSelectAttachments: { _ in }, didTapSend: { _ in })
        .padding()
    MediaMessageTextField(text: "Very long long long long long long long long text", didSelectAttachments: { _ in }, didTapSend: { _ in })
        .padding()
}
