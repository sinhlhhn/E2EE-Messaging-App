//
//  LocalSocketService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

import Combine
import SocketIO


protocol SocketData {
    var sender: String {get}
    var receiver: String {get}
    var messageType: MessageType {get}
    var groupId: UUID? {get}
    var createdDate: Double {get}
}

// TODO: should extract to send and receive model
struct SocketMessage: SocketIO.SocketData, SocketData {
    let sender: String
    let receiver: String
    let messageType: MessageType
    let groupId: UUID?
    let createdDate: Double
    
    func socketRepresentation() -> SocketIO.SocketData {
        switch messageType {
        case .text(let textMessageData):
            return [
                "sender": sender,
                "receiver": receiver,
                "text": textMessageData.content,
                "mediaType": "text",
                "createdDate": "\(createdDate)",
            ]
        case .image(let imageMessages):
            let mediaUrl = imageMessages.map { $0.path.path }
            let originalName = imageMessages.map { $0.originalName }
            let data = [
                "sender": sender,
                "receiver": receiver,
                "mediaUrls": mediaUrl,
                "mediaType": "image",
                "originalNames": originalName,
                "groupId": groupId?.uuidString ?? "",
                "createdDate": "\(createdDate)",
            ] as [String : Any]
            return data
        case .video(let videoMessage):
            return [
                "sender": sender,
                "receiver": receiver,
                "mediaUrl": videoMessage.path.path,
                "mediaType": "video",
                "originalName": videoMessage.originalName,
                "createdDate": "\(createdDate)",
            ]
        case .attachment(let attachmentMessage):
            return [
                "sender": sender,
                "receiver": receiver,
                "mediaUrl": attachmentMessage.path.path,
                "mediaType": "attachment",
                "originalName": attachmentMessage.originalName,
                "createdDate": "\(createdDate)",
            ]
        }
        
    }
}

class LocalSocketService: SocketUseCase {
    typealias Message = SocketData
    typealias User = String
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    private let encryptService: EncryptionModule
    private let decryptService: DecryptionModule
    private let keyStore: KeyStoreModule
    
    private let subject = PassthroughSubject<Message, Error>()
    private var connectSubject = PassthroughSubject<Void, Error>()
    
    private enum Constants {
        static let register: String = "register"
    }

    init(sessionDelegate: URLSessionDelegate, encryptService: EncryptionModule, decryptService: DecryptionModule, keyStore: KeyStoreModule) {
        self.encryptService = encryptService
        self.decryptService = decryptService
        self.keyStore = keyStore
        manager = SocketManager(socketURL: URL(string: "https://localhost:3000")!, config: [.log(false), .compress, .sessionDelegate(sessionDelegate)])
        socket = manager.defaultSocket
        
        setupHandlers()
    }
    
    func connect(user: User) -> AnyPublisher<Void, Error> {
        connectSubject = PassthroughSubject<Void, Error>()
        
        // Every time connect(user:) is called, we’re adding another .connect listener. Socket.IO does not replace existing handlers; it accumulates them.
        // We need to remove the previous event listeners before adding them again
        socket.off(clientEvent: .connect)
        
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            debugPrint("🔌 Socket connected \(String(describing: self?.socket.status))")
            self?.registerUser(user)
        }
        
        socket.connect()
        return connectSubject.eraseToAnyPublisher()
    }
    
    private func registerUser(_ user: User) {
        socket.off(Constants.register)
        
        socket.on(Constants.register) { [weak self] _, _ in
            debugPrint("🔌 Socket registered successfully with user: \(user) - \(String(describing: self?.socket.status))")
            self?.connectSubject.send(())
        }
        socket.emit("register", user)
    }

    private func setupHandlers() {

        socket.on("receive-message") { [weak self] data, ack in
            if let dict = data.first as? [String: Any],
               let user = dict["from"] as? String,
               let id = dict["messageId"] as? Int,
               let createdDateValue = dict["createdDate"] as? String,
            let createdDate = Double(createdDateValue)
            {
                guard let self else { return }
                
                guard let rawType = dict["mediaType"] as? String,
                      let mediaType = MediaType(rawValue: rawType) else {
                    debugPrint("cannot parse media type \(data)")
                    return
                }
                
                switch mediaType {
                case .image:
                    if let mediaURL = dict["mediaUrl"] as? String,
                       let originalName = dict["originalName"] as? String,
                       let groupIdValue = dict["groupId"] as? String {
                        debugPrint("📥 image received: \(mediaURL)")
                        let decryptedMediaURL = URL(string: decryptMessage(message: mediaURL))!
                        let decryptedOriginalName = decryptMessage(message: originalName)
                        subject.send(SocketMessage(sender: user, receiver: "", messageType: .image([.init(path: decryptedMediaURL, originalName: decryptedOriginalName)]), groupId: UUID(uuidString: groupIdValue), createdDate: createdDate))
                        return
                    }
                case .attachment:
                    if let mediaURL = dict["mediaUrl"] as? String,
                       let originalName = dict["originalName"] as? String {
                        debugPrint("📥 Media received: \(mediaURL)")
                        let decryptedMediaURL = URL(string: decryptMessage(message: mediaURL))!
                        let decryptedOriginalName = decryptMessage(message: originalName)
                        subject.send(SocketMessage(sender: user, receiver: "", messageType: .attachment(.init(path: decryptedMediaURL, originalName: decryptedOriginalName)), groupId: nil, createdDate: createdDate))
                        return
                    }
                case .video:
                    if let mediaURL = dict["mediaUrl"] as? String,
                       let originalName = dict["originalName"] as? String {
                        debugPrint("📥 Video received: \(mediaURL)")
                        let decryptedMediaURL = URL(string: decryptMessage(message: mediaURL))!
                        let decryptedOriginalName = decryptMessage(message: originalName)
                        subject.send(SocketMessage(sender: user, receiver: "", messageType: .video(.init(path: decryptedMediaURL, originalName: decryptedOriginalName)), groupId: nil, createdDate: createdDate))
                        return
                    }
                case .text:
                    if let message = dict["text"] as? String {
                        debugPrint("📥 Message received: \(message)")
                        // You can post a notification or update the UI here
                        let decryptedMessage = decryptMessage(message: message)
                        subject.send(SocketMessage(sender: user, receiver: "", messageType: .text(.init(content: decryptedMessage)), groupId: nil, createdDate: createdDate))
                        return
                    }
                }
                debugPrint("❌ unknown message format \(mediaType.rawValue) \(data)")
            } else {
                debugPrint("❌ invalid data \(data)")
            }
        }
        
        socket.on("receive-images") { [weak self] data, ack in
            if let dict = data.first as? [String: Any],
               let groupId = dict["groupId"] as? String,
               let user = dict["from"] as? String,
               let messages = dict["messages"] as? [[String: Any]]
            {
                guard let self else { return }
                var images = [ImageMessage]()
                for message in messages {
                    guard let id = message["messageId"] as? Int else {
                        debugPrint("❌ cannot parse user or messageId \(data)")
                        return
                    }
                    
                    guard let rawType = message["mediaType"] as? String,
                          let mediaType = MediaType(rawValue: rawType) else {
                        debugPrint("cannot parse media type \(data)")
                        return
                    }
                    
                    switch mediaType {
                    case .image:
                        if let mediaURL = message["mediaUrl"] as? String,
                           let originalName = message["originalName"] as? String {
                            debugPrint("📥 image received: \(mediaURL)")
                            let decryptedMediaURL = URL(string: decryptMessage(message: mediaURL))!
                            let decryptedOriginalName = decryptMessage(message: originalName)
                            images.append(ImageMessage(path: decryptedMediaURL, originalName: decryptedOriginalName))
                        }
                    default:
                        debugPrint("❌ unknown message format \(mediaType.rawValue) \(data)")
                    }
                }
                subject.send(SocketMessage(sender: user, receiver: "", messageType: .image(images), groupId: UUID(uuidString: groupId), createdDate: Date().timeIntervalSince1970))
            } else {
                debugPrint("❌ invalid data \(data)")
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            debugPrint("❌ Socket disconnected")
            // Complete the stream after the socket is disconnected.
            self?.connectSubject.send(completion: .finished)
        }
        
        socket.on(clientEvent: .error) { error, ack in
            debugPrint("❌ Socket error \(error)")
        }
    }
    
    private func decryptMessage(message: String) -> String {
        do {
            guard let messageData = Data(base64Encoded: message),
                  let key: Data? = keyStore.retrieve(key: .secureKey),
                  let key = key else {
                debugPrint("❌ cannot convert message to data")
                return ""
            }

            let decryptedMessage = try decryptService.decryptMessage(with: key, combined: messageData)
            guard let result = String(data: decryptedMessage, encoding: .utf8) else {
                debugPrint("❌ cannot convert data to message")
                return ""
            }
            return result
            
        } catch {
            debugPrint("❌ cannot decrypt message")
        }
        return ""
    }

    func sendMessage(_ message: Message) {
        if socket.status != .connected {
            debugPrint("❌ Socket not connected yet \(socket.status)")
            return
        }
        debugPrint("📤 Sending: \(message)")
        let createdDate = message.createdDate
        switch message.messageType {
        case .text(let data):
            let encryptMessage = encryptMessage(message: data.content)
            let encryptedMessage = SocketMessage(sender: message.sender, receiver: message.receiver, messageType: .text(.init(content: encryptMessage)), groupId: nil, createdDate: createdDate)
            socket.emit("send-message", encryptedMessage)
        case .image(let images):
            //TODO: -Fix force unwrap
            let imageTypes: [ImageMessage] = images.map { ImageMessage(path: URL(string: encryptMessage(message: $0.path.path))!, originalName: encryptMessage(message: $0.originalName)) }
            let encryptedMessage = SocketMessage(sender: message.sender, receiver: message.receiver, messageType: .image(imageTypes), groupId: message.groupId, createdDate: createdDate)
            socket.emit("send-images", encryptedMessage)
            
        case .video(let data):
            let encryptPathMessage = encryptMessage(message: data.path.path)
            guard let url = URL(string: encryptPathMessage) else {
                fatalError("cannot convert string to url \(encryptPathMessage)")
            }
            let encryptOriginalName = encryptMessage(message: data.originalName)
            let encryptedMessage = SocketMessage(sender: message.sender, receiver: message.receiver, messageType: .video(.init(path: url, originalName: encryptOriginalName)), groupId: nil, createdDate: createdDate)
            socket.emit("send-message", encryptedMessage)
        case .attachment(let data):
            let encryptPathMessage = encryptMessage(message: data.path.path)
            guard let url = URL(string: encryptPathMessage) else {
                fatalError("cannot convert string to url \(encryptPathMessage)")
            }
            let encryptOriginalName = encryptMessage(message: data.originalName)
            let encryptedMessage = SocketMessage(sender: message.sender, receiver: message.receiver, messageType: .attachment(.init(path: url, originalName: encryptOriginalName)), groupId: nil, createdDate: createdDate)
            socket.emit("send-message", encryptedMessage)
        }
        
    }
    
    private func encryptMessage(message: String) -> String {
        guard let messageData = message.data(using: .utf8) else {
            debugPrint("❌ cannot convert message to data")
            return ""
        }
        
        guard let key: Data? = keyStore.retrieve(key: .secureKey),
              let key = key,
              let encryptedMessageData = try? encryptService.encryptMessage(with: key, plainText: messageData) else {
            debugPrint("❌ cannot encrypt message")
            return ""
        }
        
        let encryptedMessageString = encryptedMessageData.base64EncodedString()
        return encryptedMessageString
    }
    
    func subscribeToIncomingMessages() -> AnyPublisher<Message, Error> {
        subject.eraseToAnyPublisher()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
}
