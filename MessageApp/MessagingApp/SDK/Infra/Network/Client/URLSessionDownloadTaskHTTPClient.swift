//
//  URLSessionDownloadTaskHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation
import Combine

final class URLSessionDownloadTaskHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func perform(request: URLRequest) -> AnyPublisher<HTTPURLResponse, any Error> {
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<HTTPURLResponse, Error> = .init()
        let task = session.downloadTask(with: request) { url, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send(httpResponse)
            subject.send(completion: .finished)
        }
        
        task.resume()
        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
}
