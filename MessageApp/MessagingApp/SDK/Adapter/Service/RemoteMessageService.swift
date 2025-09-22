//
//  RemoteMessageService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

import Combine
import CryptoKit

class RemoteMessageService: MessageUseCase {
    private let secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>
    private let keyStore: KeyStoreModule
    private let decryptService: DecryptionModule
    private let network: NetworkModule
    
    init(secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>, keyStore: KeyStoreModule, decryptService: DecryptionModule, network: NetworkModule) {
        self.secureKey = secureKey
        self.keyStore = keyStore
        self.decryptService = decryptService
        self.network = network
    }
    
    private func generateSecreteKey(salt: Data, publicKey: Data, privateKey: Data) throws -> Data {
        let sharedInfo = "Message".data(using: .utf8)!
        return try secureKey.generateSecureKey(data: P256KeyData(privateKey: privateKey, publicKey: publicKey, salt: salt, hashFunction: SHA256.self, sharedInfo: sharedInfo, outputByteCount: 32))
    }
    
    func fetchMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error> {
        network.fetchReceiverKey(username: data.receiver)
            .flatMap { publicKey -> AnyPublisher<(String, String), Error> in
                self.network.fetchSalt(sender: data.sender, receiver: data.receiver)
                    .map { salt in (publicKey, salt) }
                    .eraseToAnyPublisher()
            }
            .tryMap { publicKey, salt -> (Data, Data, Data) in
                guard let publicKeyData = Data(base64Encoded: publicKey),
                      let saltData = Data(base64Encoded: salt),
                      let privateKey: Data? = self.keyStore.retrieve(key: .privateKey),
                      let privateKey = privateKey else {
                    throw NSError(domain: "Invalid base64 string", code: 0, userInfo: nil)
                }
                return (publicKeyData, saltData, privateKey)
            }
            .tryMap { publicKey, salt, privateKey -> Data in
                return try self.generateSecreteKey(salt: salt, publicKey: publicKey, privateKey: privateKey)
            }
            .flatMap { secureKey in
                self.keyStore.store(key: .secureKey, value: secureKey)
                return self.network.fetchEncryptedMessages(data: data)
                    .map { messages in
                        self.decryptMessage(messages, secureKey: secureKey)
                    }
            }
            .eraseToAnyPublisher()
            
    }
    
    private func decryptMessage(_ messages: [RemoteMessage], secureKey: Data) -> [Message] {
        messages.map { message in
            let createdDate = message.createdDate
            switch message.type {
            case .text(let data):
                let content = try? self.decryptService.decryptMessage(with: secureKey, combined: Data(base64Encoded: data.getData()) ?? Data())
                let text = String(data: content ?? Data(), encoding: .utf8) ?? ""
                return Message(remoteId: message.id, type: .text(.init(content: text)), isFromCurrentUser: message.isFromCurrentUser, groupId: nil, createdDate: createdDate)
            case .image(let data):
                do {
                    let encryptedPath = data.path.path
                    let encryptedOriginalName = data.originalName
                    let content = try self.decryptService.decryptMessage(with: secureKey, combined: Data(base64Encoded: encryptedPath) ?? Data())
                    let text = String(data: content, encoding: .utf8) ?? ""
                    let path = URL(string: text)!
                    let originalNameData = try self.decryptService.decryptMessage(with: secureKey, combined: Data(base64Encoded: encryptedOriginalName) ?? Data())
                    let originalName = String(data: originalNameData, encoding: .utf8) ?? ""
                    let groupId = message.groupId?.uuidString ?? ""
                    return Message(remoteId: message.id, type: .image(.init(path: path, originalName: originalName)), isFromCurrentUser: message.isFromCurrentUser, groupId: UUID(uuidString: groupId), createdDate: createdDate)
                } catch {
                    debugPrint("❌ cannot decrypt message attachment")
                    return Message(remoteId: message.id, type: .text(.init(content: "Error message")), isFromCurrentUser: message.isFromCurrentUser, groupId: nil, createdDate: createdDate)
                }
            case .video(let data):
                do {
                    let content = try self.decryptService.decryptMessage(with: secureKey, combined: Data(base64Encoded: data.path.path) ?? Data())
                    let text = String(data: content, encoding: .utf8) ?? ""
                    let path = URL(string: text)!
                    let originalNameData = try self.decryptService.decryptMessage(with: secureKey, combined: Data(base64Encoded: data.originalName) ?? Data())
                    let originalName = String(data: originalNameData, encoding: .utf8) ?? ""
                    return Message(remoteId: message.id, type: .video(.init(path: path, originalName: originalName)), isFromCurrentUser: message.isFromCurrentUser, groupId: nil, createdDate: createdDate)
                } catch {
                    debugPrint("❌ cannot decrypt message video")
                    return Message(remoteId: message.id, type: .text(.init(content: "Error message")), isFromCurrentUser: message.isFromCurrentUser, groupId: nil, createdDate: createdDate)
                }
            case .attachment(let data):
                do {
                    let content = try self.decryptService.decryptMessage(with: secureKey, combined: Data(base64Encoded: data.path.path) ?? Data())
                    let text = String(data: content, encoding: .utf8) ?? ""
                    let path = URL(string: text)!
                    let originalNameData = try self.decryptService.decryptMessage(with: secureKey, combined: Data(base64Encoded: data.originalName) ?? Data())
                    let originalName = String(data: originalNameData, encoding: .utf8) ?? ""
                    return Message(remoteId: message.id, type: .attachment(.init(path: path, originalName: originalName)), isFromCurrentUser: message.isFromCurrentUser, groupId: nil, createdDate: createdDate)
                } catch {
                    debugPrint("❌ cannot decrypt message attachment")
                    return Message(remoteId: message.id, type: .text(.init(content: "Error message")), isFromCurrentUser: message.isFromCurrentUser, groupId: nil, createdDate: createdDate)
                }
            }
        }
        
    }
}
