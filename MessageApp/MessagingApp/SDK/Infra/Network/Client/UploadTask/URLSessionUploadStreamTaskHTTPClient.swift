//
//  URLSessionUploadTaskHTTPClient 2.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 27/6/25.
//


import Foundation
import Combine

final class URLSessionUploadStreamTaskHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func perform(request: URLRequest) -> AnyPublisher<Void, Error> {
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<Void, Error> = .init()
        session.uploadTask(withStreamedRequest: request)
        let task = session.uploadTask(withStreamedRequest: request)
        
        task.resume()
        return subject.eraseToAnyPublisher()
    }
}
