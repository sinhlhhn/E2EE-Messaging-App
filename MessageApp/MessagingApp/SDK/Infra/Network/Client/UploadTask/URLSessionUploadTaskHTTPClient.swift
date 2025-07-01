//
//  URLSessionUploadTaskHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 24/6/25.
//

import Foundation
import Combine

final class URLSessionUploadTaskHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func perform(request: (URLRequest, Data)) -> AnyPublisher<(Optional<Data>, HTTPURLResponse), any Error> {
        let (request, data) = request
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<(Data?, HTTPURLResponse), Error> = .init()
        let task = session.uploadTask(with: request, from: data) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send((data, httpResponse))
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
