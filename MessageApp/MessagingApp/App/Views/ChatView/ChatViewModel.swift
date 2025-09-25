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

struct MessageGroup: Identifiable, Equatable {
    let id: UUID        // = groupId if present, else message.id
    let isFromCurrentUser: Bool
    let createdAt: Double
    let messages: [Message]  // all messages in this group
    
    var lastestMessageId: Int? {
        messages.last?.remoteId
    }
}

@Observable
class ChatViewModel {
    //TODO: -should be let
    var sender: User
    var receiver: String
    private let service: any SocketUseCase<String, SocketData>
    private let uploadService: NetworkModule
    private let messageService: MessageUseCase
    var messages: [MessageGroup] = []
    var reachedTop: Bool = false
    
    private var firstMessageId: Int?
    var lastMessageId: Int?
    private var cancellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    private var connectCancellable: AnyCancellable?
    private var fetchMessageCancellable: AnyCancellable?
    private let passthroughSubject = PassthroughSubject<FetchMessageData, Never>()
    var isLoading = false
    
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
                self?.updateNewMessage(response: response)
            }
        
        connect()
    }
    
    private func updateNewMessage(response: SocketData) {
        var messages: [Message] = []
        switch response.messageType {
        case .text(let textMessageData):
            messages.append(Message(remoteId: response.remoteId, type: .text(textMessageData), isFromCurrentUser: false, groupId: response.groupId, createdDate: response.createdDate))
        case .image(let array):
            for item in array {
                messages.append(Message(remoteId: response.remoteId, type: .image(item), isFromCurrentUser: false, groupId: response.groupId, createdDate: response.createdDate))
            }
        case .video(let videoMessage):
            messages.append(Message(remoteId: response.remoteId, type: .video(videoMessage), isFromCurrentUser: false, groupId: response.groupId, createdDate: response.createdDate))
        case .attachment(let attachmentMessage):
            messages.append(Message(remoteId: response.remoteId, type: .attachment(attachmentMessage), isFromCurrentUser: false, groupId: response.groupId, createdDate: response.createdDate))
        }
        
        addNewMessage(MessageGroup(id: UUID(), isFromCurrentUser: false, createdAt: Date().timeIntervalSince1970, messages: messages))
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
    }
    
    private func notifyNewMessageSent(result: [UploadDataResponse]) {
        let groupId = UUID()
        let images = result.map { ImageMessage(path: URL(string: $0.path)!, originalName: $0.originalName)}
        let type: SocketMessageType = .image(images)
        let createdDate = Date().timeIntervalSince1970
        service.sendMessage(SocketMessage(sender: self.sender.username, receiver: self.receiver, messageType: type, groupId: groupId, createdDate: createdDate))
        
        var messages: [Message] = []
        for item in images {
            messages.append(Message(remoteId: nil, type: .image(item), isFromCurrentUser: true, groupId: groupId, createdDate: createdDate))
        }
        
        addNewMessage(MessageGroup(id: UUID(),isFromCurrentUser: true, createdAt: Date().timeIntervalSince1970, messages: messages))
    }
    
    func sendAttachment(urls: [URL]) {
        //TODO: -Deal with foreach here
        for attachmentURL in urls {
            let originalName = attachmentURL.lastPathComponent
            sendMessage(.attachment(.init(path: attachmentURL, originalName: originalName)))
        }
    }
    
    private func addNewMessage(_ message: MessageGroup) {
        withAnimation {
            messages.insert(message, at: 0)
        }
    }
    
    func sendMessage(_ type: MessageType) {
        let createdDate = Date().timeIntervalSince1970
        switch type {
        case .text(let textData):
            service.sendMessage(SocketMessage(sender: sender.username, receiver: receiver, messageType: .text(textData), groupId: nil, createdDate: createdDate))
            let messages = [Message(remoteId: nil, type: type, isFromCurrentUser: true, groupId: nil, createdDate: createdDate)]
            addNewMessage(MessageGroup(id: UUID(), isFromCurrentUser: true, createdAt: Date().timeIntervalSince1970, messages: messages))
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
                    let videoData = VideoMessage(path: url, originalName: url.lastPathComponent)
                    let type = MessageType.video(videoData)
                    service.sendMessage(SocketMessage(sender: self.sender.username, receiver: self.receiver, messageType: .video(videoData), groupId: nil, createdDate: createdDate))
                    let messages = [Message(remoteId: nil, type: type, isFromCurrentUser: true, groupId: nil, createdDate: createdDate)]
                    addNewMessage(MessageGroup(id: UUID(),isFromCurrentUser: true, createdAt: Date().timeIntervalSince1970, messages: messages))
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
                    let attachment = AttachmentMessage(path: URL(string: response.path)!, originalName: response.originalName)
                    let attachmentType: MessageType = .attachment(attachment)
                    //TODO: -Currently, the owner also need to download the file from the server and then save to the Document/Download folder. We may need to move the file to the Document/Download folder to prevent unnecessary network call. It quite complex because currently, we let the server to generate the file name to avoid duplicated file.
                    service.sendMessage(SocketMessage(sender: self.sender.username, receiver: self.receiver, messageType: .attachment(attachment), groupId: nil, createdDate: createdDate))
                    let messages = [Message(remoteId: nil, type: attachmentType, isFromCurrentUser: true, groupId: nil, createdDate: createdDate)]
                    addNewMessage(MessageGroup(id: UUID(),isFromCurrentUser: true, createdAt: Date().timeIntervalSince1970, messages: messages))
                }
                .store(in: &cancellables)
        }
    }
    
    func loadFirstMessage() {
        isLoading = true
        passthroughSubject.send(FetchMessageData(sender: sender.username, receiver: receiver, firstLoad: true))
    }
    
    func loadMoreMessages() {
        // Ignore when there are no more message to load.
        if firstMessageId == 1 {
            return
        }
        // Ignore if a request is already running.
        if isLoading {
            return
        }
        isLoading = true
        passthroughSubject.send(FetchMessageData(sender: sender.username, receiver: receiver, before: firstMessageId, limit: 10, firstLoad: false))
    }
    
    private func fetchMessage() {
        fetchMessageCancellable = passthroughSubject
            .flatMap(maxPublishers: .max(1)) { [weak self] data in
                guard let self else { return Empty<[Message], Never>().eraseToAnyPublisher() }
                return self.messageService.fetchMessages(data: data)
                    .replaceError(with: [])
                    .eraseToAnyPublisher()
            }
            .compactMap { [weak self] messages -> [MessageGroup]? in
                self?.groupMessages(messages)
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
                self.messages.append(contentsOf: messages)
                //TODO: -Auto scroll to the latest message
                if let firstMessageId = messages.last?.messages.first?.remoteId {
                    self.firstMessageId = firstMessageId
                }
                self.reachedTop = false
                self.isLoading = false
            }
    }
    
    func groupMessages(_ messages: [Message]) -> [MessageGroup] {
        // Group messages by groupId (or fallback to id for solo messages)
        let groupedDict = Dictionary(grouping: messages) { msg in
            msg.groupId ?? msg.id
        }

        // Build MessageGroup for each cluster
        let groups = groupedDict.map { (key, msgs) in
            let sortedMsgs = msgs.sorted {
                $0.createdDate < $1.createdDate
            }

            return MessageGroup(
                id: key,
                isFromCurrentUser: sortedMsgs.first!.isFromCurrentUser,
                createdAt: sortedMsgs.first!.createdDate,
                messages: sortedMsgs
            )
        }

        // Sort groups in timeline order
        return groups.sorted { $0.createdAt > $1.createdAt }
    }
    
    deinit {
        service.disconnect()
    }
}
