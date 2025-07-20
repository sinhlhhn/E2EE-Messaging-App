//
//  MessageTextField.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI
import PhotosUI

struct MediaMessageTextField: View {
    @State private var text: String = ""
    @Binding var imageSelection: PhotosPickerItem?
    
    @State private var isShowingMedia: Bool = true
    @State private var isPresentedAttachment: Bool = false
    
    private let didTapSend: (String) -> Void
    private let didSelectAttachments: ([URL]) -> Void
    
    fileprivate init(
        text: String,
        imageSelection: Binding<PhotosPickerItem?>,
        didSelectAttachments: @escaping ([URL]) -> Void,
        didTapSend: @escaping (String) -> Void
    ) {
        self.text = text
        self.didTapSend = didTapSend
        self.didSelectAttachments = didSelectAttachments
        self._imageSelection = imageSelection
    }
    
    init(
        imageSelection: Binding<PhotosPickerItem?>,
        didSelectAttachments: @escaping ([URL]) -> Void,
        didTapSend: @escaping (String) -> Void
    ) {
        self.didTapSend = didTapSend
        self.didSelectAttachments = didSelectAttachments
        self._imageSelection = imageSelection
    }
    
    var body: some View {
        HStack(alignment: .bottomAligned) {
            if isShowingMedia {
                mediaView
            }
            MessageTextField(text: text, didTapSend: { text in
//                isShowingMedia.toggle()
                didTapSend(text)
            })
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
        PhotosPicker(selection: $imageSelection,
                     photoLibrary: .shared()) {
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
                didSelectAttachments(urls)
            case .failure(let failure):
                debugPrint("fileImporter with error: ", failure)
            }
        }
    }
}

#Preview {
    MediaMessageTextField(text: "", imageSelection: .constant(nil), didSelectAttachments: { _ in }, didTapSend: { _ in })
        .padding()
    MediaMessageTextField(text: "Short text", imageSelection: .constant(nil), didSelectAttachments: { _ in }, didTapSend: { _ in })
        .padding()
    MediaMessageTextField(text: "Very long long long long long long long long text", imageSelection: .constant(nil), didSelectAttachments: { _ in }, didTapSend: { _ in })
        .padding()
}
