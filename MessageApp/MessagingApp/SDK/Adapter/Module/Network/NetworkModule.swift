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
    func fetchEncryptedMessages(data: FetchMessageData) -> AnyPublisher<[RemoteMessage], any Error>
    
    func uploadImage(images: [MultipartImage], fields: [FormField]) -> AnyPublisher<[UploadDataResponse], Error>
    func uploadStreamRawData() -> AnyPublisher<Void, any Error>
    func downloadData(url: String) -> AnyPublisher<AppDownloadResponse, Error>
    
    func uploadFile(data: UploadFileData) -> AnyPublisher<UploadDataResponse, Error>
    
    func cancelRequest()
}

enum AppDownloadResponse {
    case downloading(Double)
    case downloaded(URL, String)
}

struct UploadFileData {
    let url: URL
    let fileSize: Int?
    let userId: String
    
    var filePath: String {
        url.path
    }
    
    var fileName: String {
        url.lastPathComponent
    }
}
