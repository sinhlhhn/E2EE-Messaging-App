//
//  HttpNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

let localhost = "https://localhost:443/"

final class AuthenticatedNetwork: NetworkModule {
    private let network: HTTPClient
    
    init(network: HTTPClient) {
        self.network = network
    }
    
    func logOut(userName: String) -> AnyPublisher<Void, any Error> {
        let urlString = "\(localhost)api/logout"
        let request = buildRequest(url: urlString, method: .post, body: ["username": userName])
        
        return network.perform(request: request)
            .tryMap { data, response in
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                return Void()
            }
            .eraseToAnyPublisher()
        
    }
    
    func sendPublicKey(user: String, publicKey: Data) -> AnyPublisher<Void, Error> {
        let urlString = "\(localhost)api/keys"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "username": user,
            "publicKey": publicKey.base64EncodedString()
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> String in
                try GenericMapper.map(data: data, response: response)
            }
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }
    
    func sendBackupKey(user: String, salt: String, encryptedKey: String) -> AnyPublisher<Void, Error> {
        let urlString = "\(localhost)api/key-backup"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "username": user,
            "salt": salt,
            "encryptedKey": encryptedKey
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> String in
                try GenericMapper.map(data: data, response: response)
            }
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }
    
    func fetchRestoreKey(username: String) -> AnyPublisher<RestoreKeyModel, Error> {
        let urlString = "\(localhost)api/key-backup/\(username)"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> RestoreKeyResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.toRestoreKeyModel() }
            .eraseToAnyPublisher()
    }
    
    func fetchUsers() -> AnyPublisher<[User], Error> {
        let urlString = "\(localhost)api/users"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> ListUser in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.users }
            .eraseToAnyPublisher()
    }
    
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error> {
        let urlString = "\(localhost)api/session"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "senderUsername": sender,
            "receiverUsername": receiver
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> SaltResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.salt }
            .eraseToAnyPublisher()
    }
    
    func fetchReceiverKey(username: String) -> AnyPublisher<String, Error> {
        let urlString = "\(localhost)api/keys/\(username)"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> PublicKeyResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.publicKey }
            .eraseToAnyPublisher()
    }
    
    func fetchEncryptedMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error> {
        let sender = data.sender
        let urlString = "\(localhost)api/messages/\(data.sender)/\(data.receiver)"
        
        var params = [String: Any]()
        if let before = data.before {
            params["before"] = before
        }
        if let limit = data.limit {
            params["limit"] = limit
        }
        
        let request = buildRequest(url: urlString, parameters: params)
        
        return network.perform(request: request)
            .tryMap { data, response -> [MessageResponse] in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.map { Message(messageId: $0.id, content: $0.text, isFromCurrentUser: $0.sender == sender)} }
            .eraseToAnyPublisher()
    }
}
