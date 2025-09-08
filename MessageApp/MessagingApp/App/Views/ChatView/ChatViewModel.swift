//
//  ChatViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 22/5/25.
//

import Foundation
import Observation
import Combine

import SwiftUI
import PhotosUI

@Observable
class ChatViewModel {
    //TODO: -should be let
    var sender: User
    var receiver: String
    private let service: any SocketUseCase<String, SocketData>
    private let uploadService: NetworkModule
    private let messageService: MessageUseCase
    var messages: [Message] = []
    var reachedTop: Bool = false
    
    private var firstMessageId: Int?
    var lastMessageId: Int?
    private var cancellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    private var connectCancellable: AnyCancellable?
    private var fetchMessageCancellable: AnyCancellable?
    private let passthroughSubject = PassthroughSubject<FetchMessageData, Never>()
    
    private let didTapBack: () -> Void
    
    var imageSelection: [PhotosPickerItem] = [] {
        didSet {
            debugPrint("================ imageSelection changed", imageSelection.count)
            Task {
                do {
                    try await loadTransferable(from: imageSelection)
                } catch {
                    debugPrint("Error loading transferable: \(error)")
                }
            }
        }
    }
    
    init(
        sender: User,
        receiver: String,
        service: any SocketUseCase<String, SocketData>,
        uploadService: NetworkModule,
        messageService: MessageUseCase,
        didTapBack: @escaping () -> Void
    ) {
        self.sender = sender
        self.receiver = receiver
        self.service = service
        self.uploadService = uploadService
        self.messageService = messageService
        self.didTapBack = didTapBack
        fetchMessage()
    }
    
    func subscribe() {
        cancellable = service.subscribeToIncomingMessages()
            .sink { completion in
                switch completion {
                case .finished: debugPrint("socket finished")
                case .failure(let error):
                    //TODO: -should implement retry mechanism
                    debugPrint("socket get error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] response in
                self?.messages.append(Message(type: response.messageType, isFromCurrentUser: false, groupId: response.groupId, createdDate: response.createdDate))
            }
        
        connect()
    }
    
    private func connect() {
        connectCancellable = service.connect(user: sender.username)
            .sink { completion in
                switch completion {
                    case .finished: debugPrint("socket finished")
                case .failure(let error):
                    //TODO: -show no connection state
                    debugPrint("socket get error: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                //TODO: -show connected state
                debugPrint("socket connected")
            }
    }
    
    private func loadTransferable(from imageSelection: [PhotosPickerItem]) async throws {
        if imageSelection.isEmpty {
            return
        }
        var listData = [Data]()
        for item in imageSelection {
            let result = try await item.loadTransferable(type: Movie.self)
            
            if let result = result {
                self.uploadVideo(result)
            } else {
                guard let data = try await self.loadImage(from: item) else {
                    //TODO: -Handle error
                    return
                }
                listData.append(data)
            }
        }
        self.imageSelection = []
        let fileName = "image.jpg"
        let multipartImages = listData.map { MultipartImage(data: $0, fieldName: "media", fileName: fileName, mimeType: "image/jpg") }
        
        uploadService.uploadImage(images: multipartImages, fields: [.init(name: "mediaType", value: "image")])
            .sink { completion in
                switch completion {
                case .finished: debugPrint("uploadImage finish")
                case .failure(let error): debugPrint("uploadImage failure with error \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] result in
                debugPrint("uploadImage result \(result)")
                self?.notifyNewMessageSent(result: result)
            }
            .store(in: &cancellables)
        
    }
    
    private func uploadVideo(_ video: Movie) {
        sendMessage(.video(.init(path: video.url, originalName: video.url.lastPathComponent)))
    }
    
    private func loadImage(from imageSelection: PhotosPickerItem) async throws -> Data? {
        let data = try await imageSelection.loadTransferable(type: Data.self)
        return data
//        guard let data = data else {
//            //TODO: -Handle nil data
//            debugPrint("loading image failed")
//            return
//        }
//        uploadImage(imageData: data)
    }
    
//    private func uploadImage(imageData: Data) {
//        let fileName = "image.jpg"
//        uploadService.uploadImage(images: [.init(data: imageData, fieldName: "media", fileName: fileName, mimeType: "image/jpg")], fields: [.init(name: "mediaType", value: "image")])
//            .sink { completion in
//                switch completion {
//                case .finished: debugPrint("uploadImage finish")
//                case .failure(let error): debugPrint("uploadImage failure with error \(error.localizedDescription)")
//                }
//            } receiveValue: { [weak self] result in
//                debugPrint("uploadImage result \(result)")
//                self?.notifyNewMessageSent(result: result)
//            }
//            .store(in: &cancellables)
//    }
    
    private func notifyNewMessageSent(result: [UploadDataResponse]) {
        let groupId = UUID()
        let urls = result
        let images = result.map { ImageMessage(path: URL(string: $0.path)!, originalName: $0.originalName)}
        let type: MessageType = .image(images)
        let createdDate = Date().timeIntervalSince1970
        service.sendMessage(SocketMessage(sender: self.sender.username, receiver: self.receiver, messageType: type, groupId: groupId, createdDate: createdDate))
        messages.append(Message(type: type, isFromCurrentUser: true, groupId: groupId, createdDate: createdDate))
    }
    
    func sendAttachment(urls: [URL]) {
        //TODO: -Deal with foreach here
        for attachmentURL in urls {
            let originalName = attachmentURL.lastPathComponent
            sendMessage(.attachment(.init(path: attachmentURL, originalName: originalName)))
        }
    }
    
    func sendMessage(_ type: MessageType) {
        let createdDate = Date().timeIntervalSince1970
        switch type {
        case .text(let textData):
            service.sendMessage(SocketMessage(sender: sender.username, receiver: receiver, messageType: type, groupId: nil, createdDate: createdDate))
            messages.append(Message(type: type, isFromCurrentUser: true, groupId: nil, createdDate: createdDate))
        case .image(let VideoMessage):
            //TODO: handle image
            break
        case .video(let videoData):
            uploadService.uploadFile(data: UploadFileData(url: videoData.path, fileSize: videoData.fileSize, userId: String(sender.id)))
                .sink { completion in
                    switch completion {
                    case .finished: print("uploadFile finished")
                    case .failure(let error): print("uploadFile failure")
                    }
                } receiveValue: { [weak self] response in
                    guard let self else { return }
                    print("uploadFile receiveValue")
                    guard let url = URL(string:  response.path) else {
                        debugPrint("❌ cannot convert string to URL")
                        return
                    }
                    let type = MessageType.video(.init(path: url, originalName: url.lastPathComponent))
                    service.sendMessage(SocketMessage(sender: self.sender.username, receiver: self.receiver, messageType: type, groupId: nil, createdDate: createdDate))
                    messages.append(Message(type: type, isFromCurrentUser: true, groupId: nil, createdDate: createdDate))
                }
                .store(in: &cancellables)
            
        case .attachment(let attachment):
            uploadService.uploadFile(data: UploadFileData(url: attachment.path, fileSize: attachment.fileSize, userId: String(sender.id)))
                .sink { completion in
                    switch completion {
                    case .finished: print("uploadFile finished")
                    case .failure(let error): print("uploadFile failure")
                    }
                } receiveValue: { [weak self] response in
                    guard let self else { return }
                    print("uploadFile receiveValue")
                    let attachmentType: MessageType = .attachment(.init(path: URL(string: response.path)!, originalName: response.originalName))
                    //TODO: -Currently, the owner also need to download the file from the server and then save to the Document/Download folder. We may need to move the file to the Document/Download folder to prevent unnecessary network call. It quite complex because currently, we let the server to generate the file name to avoid duplicated file.
                    service.sendMessage(SocketMessage(sender: self.sender.username, receiver: self.receiver, messageType: attachmentType, groupId: nil, createdDate: createdDate))
                    messages.append(Message(type: attachmentType, isFromCurrentUser: true, groupId: nil, createdDate: Date().timeIntervalSince1970))
                }
                .store(in: &cancellables)
        }
    }
    
    func loadFirstMessage() {
        passthroughSubject.send(FetchMessageData(sender: sender.username, receiver: receiver, firstLoad: true))
    }
    
    func loadMoreMessages() {
        passthroughSubject.send(FetchMessageData(sender: sender.username, receiver: receiver, before: firstMessageId, limit: 10, firstLoad: false))
    }
    
    private func fetchMessage() {
        fetchMessageCancellable = passthroughSubject
            .delay(for: .seconds(2), scheduler: DispatchQueue.global())
            .flatMap(maxPublishers: .max(1)) { data in
                self.messageService.fetchMessages(data: data)
                    .replaceError(with: [])
            }
            .map { messages -> [Message] in
                self.groupMessages(messages)
            }
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .finished: debugPrint("fetch finish")
                case .failure(let error):
                    //TODO: -show error
                    debugPrint("❌ fetch get error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] messages in
                guard let self else { return }
                self.messages = messages
                //TODO: -Auto scroll to the latest message
//                if let firstMessageId = messages.first?.messageId {
//                    self.firstMessageId = firstMessageId
//                }
//                if let lastMessageId = messages.last?.messageId {
//                    self.lastMessageId = lastMessageId
//                }
//                self.reachedTop = false
            }
    }
    
    private func groupMessages(_ messages: [Message]) -> [Message] {
        var grouped: [UUID: [Message]] = [:]
        var singles: [Message] = []

        for message in messages {
            if let gid = message.groupId {
                grouped[gid, default: []].append(message)
            } else {
                singles.append(message)
            }
        }

        var result: [Message] = []

        for (_, group) in grouped {
            // merge images if they exist
            let images = group.compactMap { msg -> [ImageMessage]? in
                if case .image(let imgs) = msg.type {
                    return imgs
                }
                return nil
            }.flatMap { $0 }

            if !images.isEmpty {
                // build a new combined message
                let combined = Message(
                    type: .image(images),
                    isFromCurrentUser: group.first?.isFromCurrentUser ?? false,
                    groupId: group.first?.groupId,
                    createdDate: group.first?.createdDate ?? Date().timeIntervalSince1970
                )
                result.append(combined)
            }

            // handle non-image messages inside same group normally
            for msg in group {
                if case .image = msg.type { continue }
                result.append(msg)
            }
        }

        result.append(contentsOf: singles)

        return result.sorted { $0.createdDate < $1.createdDate }
    }
    
    func reset() {
        service.disconnect()
        didTapBack()
        messages = []
    }
}
