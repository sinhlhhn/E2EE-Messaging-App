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
struct TextMessage: SocketData {
    let messageId: String
    let sender: String
    let receiver: String
    let message: String
    
    func socketRepresentation() -> SocketData {
        return ["sender": sender, "receiver": receiver, "text": message]
    }
}

class LocalSocketService: SocketUseCase {
    typealias Message = TextMessage
    typealias User = String
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    private let encryptService: EncryptionModule
    private let decryptService: DecryptionModule
    private let keyStore: KeyStoreModule
    
    private let subject = PassthroughSubject<Message, Error>()
    private let connectSubject = PassthroughSubject<Void, Error>()

    init(encryptService: EncryptionModule, decryptService: DecryptionModule, keyStore: KeyStoreModule) {
        self.encryptService = encryptService
        self.decryptService = decryptService
        self.keyStore = keyStore
        manager = SocketManager(socketURL: URL(string: "http://localhost:3000")!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        
        setupHandlers()
    }
    
    func connect(user: User) -> AnyPublisher<Void, Error> {
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            debugPrint("🔌 Socket connected \(String(describing: self?.socket.status))")
            self?.registerUser(user)
        }
        
        socket.connect()
        return connectSubject.eraseToAnyPublisher()
    }
    
    private func registerUser(_ user: User) {
        socket.on("register") { [weak self] _, _ in
            debugPrint("🔌 Socket registered successfully with user: \(user) - \(String(describing: self?.socket.status))")
            self?.connectSubject.send(())
        }
        socket.emit("register", user)
    }

    private func setupHandlers() {

        socket.on("receive-message") { [weak self] data, ack in
            if let dict = data.first as? [String: Any],
               let message = dict["text"] as? String,
               let user = dict["from"] as? String,
               let id = dict["messageId"] as? Int
            {
                guard let self else { return }
                debugPrint("📥 Message received: \(message)")
                // You can post a notification or update the UI here
                let decryptedMessage = decryptMessage(message: message)
                subject.send(TextMessage(messageId: String("\(id)"), sender: user, receiver: "", message: decryptedMessage))
                
            } else {
                debugPrint("❌ invalid data \(data)")
            }
        }

        socket.on(clientEvent: .disconnect) { data, ack in
            debugPrint("❌ Socket disconnected")
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
        let encryptMessage = encryptMessage(message: message.message)
        let encryptedMessage: Message = Message(messageId: message.messageId, sender: message.sender, receiver: message.receiver, message: encryptMessage)
        socket.emit("send-message", encryptedMessage)
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
    
    func login(email: String, password: String, completion: @escaping () -> Void) {
        socket.emit("register", email, password, completion: completion)
    }
    
}
