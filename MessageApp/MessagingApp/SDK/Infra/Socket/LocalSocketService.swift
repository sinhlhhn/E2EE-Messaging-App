//
//  LocalSocketService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

import Combine
import SocketIO

// TODO: should extract to send and receive model
struct SocketMessage: SocketData {
    let messageId: String
    let sender: String
    let receiver: String
    let messageType: MessageType
    
    func socketRepresentation() -> SocketData {
        switch messageType {
        case .text(let textMessageData):
            return ["sender": sender, "receiver": receiver, "text": textMessageData.content]
        case .image(let imageMessage):
            //TODO: -handle send image via socket
            return ["":""]
        case .video(let videoMessage):
            //TODO: -handle send video via socket
            return ["":""]
        case .attachment(let attachmentMessage):
            return ["sender": sender, "receiver": receiver, "mediaUrl": attachmentMessage.path.path]
        }
        
    }
}

class LocalSocketService: SocketUseCase {
    typealias Message = SocketMessage
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
               let id = dict["messageId"] as? Int
            {
                guard let self else { return }
                if let message = dict["text"] as? String {
                    debugPrint("📥 Message received: \(message)")
                    // You can post a notification or update the UI here
                    let decryptedMessage = decryptMessage(message: message)
                    subject.send(SocketMessage(messageId: String("\(id)"), sender: user, receiver: "", messageType: .text(.init(content: decryptedMessage))))
                    return
                }
                if let mediaURL = dict["mediaUrl"] as? String,
                   let url = URL(string: mediaURL) {
                    debugPrint("📥 Media received: \(mediaURL)")
                    let decryptedMediaURL = decryptMessage(message: mediaURL)
                    subject.send(SocketMessage(messageId: String("\(id)"), sender: user, receiver: "", messageType: .attachment(.init(path: url))))
                    return
                }
                
                print("❌ unknown message format \(data)")
                
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
        switch message.messageType {
        case .text(let data):
            let encryptMessage = encryptMessage(message: data.content)
            let encryptedMessage: Message = Message(messageId: message.messageId, sender: message.sender, receiver: message.receiver, messageType: .text(.init(content: encryptMessage)))
            socket.emit("send-message", encryptedMessage)
        case .image(_):
            fatalError()
        case .video(_):
            fatalError()
        case .attachment(let data):
            let encryptMessage = encryptMessage(message: data.path.path)
            guard let url = URL(string: encryptMessage) else {
                fatalError("cannot convert string to url \(encryptMessage)")
            }
            let encryptedMessage: Message = Message(messageId: message.messageId, sender: message.sender, receiver: message.receiver, messageType: .attachment(.init(path: url)))
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
