//
//  HttpNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

//let localhost = "http://localhost:3000/"
let localhost = "https://localhost:3000"

final class AuthenticatedNetwork: NetworkModule {
    private let network: DataTaskHTTPClient
    private let uploadNetwork: UploadTaskHTTPClient & TaskCancelHTTPClient
    private let downloadNetwork: DownloadTaskHTTPClient & TaskCancelHTTPClient
    private let progressSubscriber: ProgressSubscriber
    private let streamUpload: StreamUploadTaskHTTPClient
    
    init(
        network: DataTaskHTTPClient,
        uploadNetwork: UploadTaskHTTPClient & TaskCancelHTTPClient,
        downloadNetwork: DownloadTaskHTTPClient & TaskCancelHTTPClient,
        progressSubscriber: ProgressSubscriber,
        streamUpload: StreamUploadTaskHTTPClient
    ) {
        self.network = network
        self.uploadNetwork = uploadNetwork
        self.downloadNetwork = downloadNetwork
        self.progressSubscriber = progressSubscriber
        self.streamUpload = streamUpload
    }
    
    //MARK: -Authentication Flow
    func logOut(userName: String) -> AnyPublisher<Void, any Error> {
        let urlString = "\(localhost)/api/logout"
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
        let urlString = "\(localhost)/api/keys"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "username": user,
            "publicKey": publicKey.base64EncodedString()
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> RequestCommonResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }
    
    func sendBackupKey(user: String, salt: String, encryptedKey: String) -> AnyPublisher<Void, Error> {
        let urlString = "\(localhost)/api/key-backup"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "username": user,
            "salt": salt,
            "encryptedKey": encryptedKey
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> RequestCommonResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }
    
    func fetchRestoreKey(username: String) -> AnyPublisher<RestoreKeyModel, Error> {
        let urlString = "\(localhost)/api/key-backup/\(username)"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> RestoreKeyResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.toRestoreKeyModel() }
            .eraseToAnyPublisher()
    }
    
    //MARK: -User
    func fetchUsers() -> AnyPublisher<[User], Error> {
        let urlString = "\(localhost)/api/users"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> ListUser in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.users }
            .eraseToAnyPublisher()
    }
    
    //MARK: -Conversation
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error> {
        let urlString = "\(localhost)/api/session"
        
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
        let urlString = "\(localhost)/api/keys/\(username)"
        
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
        let urlString = "\(localhost)/api/messages/\(data.sender)/\(data.receiver)"
        
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
                let result: [MessageResponse] = try GenericMapper.map(data: data, response: response)
                return result
            }
            .map { $0.map {
                switch $0.mediaType {
                case "text":
                    return Message(messageId: $0.id, type: .text(.init(content: $0.text!)), isFromCurrentUser: $0.sender == sender)
                case "attachment":
                    return Message(messageId: $0.id, type: .attachment(.init(path: URL(string: $0.mediaUrl!)!)), isFromCurrentUser: $0.sender == sender)
                default:
                    return Message(messageId: $0.id, type: .text(.init(content: "")), isFromCurrentUser: $0.sender == sender)
                }
            }}
            .eraseToAnyPublisher()
    }
    
    func cancelRequest() {
//        uploadNetwork.cancel(url: <#T##URL#>)
    }
    
    
    
    func uploadFile(data: UploadFileData) -> AnyPublisher<UploadDataResponse, Error> {
//        freemusic.mp3
        guard let url = URL(string: "\(localhost)/upload/raw/\(data.fileName)") else {
            return Fail<UploadDataResponse, Error>(error: NSError(domain: "", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        if let contentLength = data.fileSize {
            request.setValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
            print("Content-Length: \(contentLength)")
        }
        
        return uploadNetwork.upload(request: (request, .file(data.url)))
            .tryCompactMap { response -> UploadDataResponse? in
                switch response {
                case .uploading(let percentage):
                    print(percentage)
                    return nil
                case .uploaded(let data, let response):
                    guard response.statusCode == 200, let data = data else {
                        let error = URLError(.badServerResponse)
                        throw error
                    }
                    let result: UploadDataResponse = try GenericMapper.map(data: data, response: response)
                    return result
                }
            }
            .eraseToAnyPublisher()
    }
    
    //MARK: -Image
    func uploadImage(
        images: [MultipartImage],
        fields: [FormField] = []
    ) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(localhost)/upload") else {
            return Fail<Void, Error>(error: NSError(domain: "", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var multipart = MultipartRequest()

        // Add fields
        for field in fields {
            multipart.add(key: field.name, value: field.value)
        }

        // Add images
        for image in images {
            multipart.add(key: image.fieldName, fileName: image.fileName, fileMimeType: image.mimeType, fileData: image.data)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        
        let uploadRequest: (URLRequest, UploadData) = (request, .data(multipart.httpBody))
        
        let progress = progressSubscriber.subscribeProgress(url: url).setFailureType(to: Error.self)
        
        let uploadTask = uploadNetwork.upload(request: uploadRequest)
            .tryMap { response in
                switch response {
                case .uploading(let percentage):
                    print(percentage)
                case .uploaded(let data, let response):
                    guard response.statusCode == 200 else {
                        let error = URLError(.badServerResponse)
                        throw error
                    }
                }
                return Void()
            }
            .eraseToAnyPublisher()
        
        return Publishers.CombineLatest(
            progress,
            uploadTask.prepend(())
        )
        .print("--------------- ")
        .map { progress, complete in
            print("slh upload: \(progress)")
            return Void()
        }
        .eraseToAnyPublisher()
    }
    
    func downloadData(url: String) -> AnyPublisher<AppDownloadResponse, Error> {
        guard let url = URL(string: "\(localhost)/download\(url)") else {
            return Fail<AppDownloadResponse, Error>(error: NSError(domain: "", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        let request = URLRequest(url: url)
        let originalFileName = url.lastPathComponent
        
        return downloadNetwork.download(request: request)
            .tryMap { response in
                switch response {
                case .downloaded(let url, let response):
                    guard response.statusCode == 200 else {
                        let error = URLError(.badServerResponse)
                        throw error
                    }
                    guard let url = url else {
                        throw NSError(domain: "ivalid url", code: 0, userInfo: nil)
                    }
                    return AppDownloadResponse.downloaded(url, originalFileName)
                case .downloading(let percentage):
                    return AppDownloadResponse.downloading(percentage)
                }
            }
            .print("--------------- download ")
            .eraseToAnyPublisher()
    }
    
    //MARK: -Upload Stream
    func uploadStreamRawData() -> AnyPublisher<Void, any Error> {
//        let data = Data(repeating: 0xAB, count: 100 * 1024 * 1024) // 100MB
//        let contentLength = data.count
        
        let message = "*** \(Date())\r\n"
        guard let messageData = message.data(using: .utf8) else {
            return Fail<Void, Error>(error: NSError(domain: "", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        let contentLength = messageData.count * 3
        
        // Create streamed request
        var request = URLRequest(url: URL(string: "\(localhost)/upload/raw/backup.data")!)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        return streamUpload.upload(request: request)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

}
