//
//  URLSessionUploadTaskHTTPClient 2.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 27/6/25.
//


import Foundation
import Combine

final class URLSessionStreamUploadTaskHTTPClient: StreamUploadTaskHTTPClient {
    private let session: URLSession
    private let didCreateTask: (Int) -> Void
    
    init(session: URLSession, didCreateTask: @escaping (Int) -> Void) {
        self.session = session
        self.didCreateTask = didCreateTask
    }
    
    func upload(request: URLRequest) -> AnyPublisher<Void, Error> {
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<Void, Error> = .init()
        let task = session.uploadTask(withStreamedRequest: request)
        
        didCreateTask(task.taskIdentifier)
        
        task.resume()
        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
}
