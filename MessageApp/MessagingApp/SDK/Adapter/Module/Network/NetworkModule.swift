//
//  NetworkModule.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

// TODO: -Can extract to small module: UserCloudModule, NetworkCloudModule
protocol NetworkModule {
    func registerUser(data: PasswordAuthentication) -> AnyPublisher<Void, Error>
    func sendPublicKey(user: String, publicKey: Data) -> AnyPublisher<Void, Error>
    func sendBackupKey(user: String, salt: String, encryptedKey: String) -> AnyPublisher<Void, Error>
    func fetchRestoreKey(username: String) -> AnyPublisher<RestoreKeyResponse, Error>
    
    func fetchUsers() -> AnyPublisher<[User], Error>
    
    func fetchReceiverKey(username: String) -> AnyPublisher<String, Error>
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error>
    func fetchEncryptedMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error>
}
