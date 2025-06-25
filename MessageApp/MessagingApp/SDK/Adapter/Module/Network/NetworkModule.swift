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
    
    func sendPublicKey(user: String, publicKey: Data) -> AnyPublisher<Void, Error>
    func sendBackupKey(user: String, salt: String, encryptedKey: String) -> AnyPublisher<Void, Error>
    func fetchRestoreKey(username: String) -> AnyPublisher<RestoreKeyModel, Error>
    func logOut(userName: String) -> AnyPublisher<Void, Error>
    
    func fetchUsers() -> AnyPublisher<[User], Error>
    
    func fetchReceiverKey(username: String) -> AnyPublisher<String, Error>
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error>
    func fetchEncryptedMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error>
    
    func uploadImage(images: [MultipartImage], fields: [FormField]) -> AnyPublisher<Void, Error>
    func downloadImage(url: String) -> AnyPublisher<Data, Error>
}
