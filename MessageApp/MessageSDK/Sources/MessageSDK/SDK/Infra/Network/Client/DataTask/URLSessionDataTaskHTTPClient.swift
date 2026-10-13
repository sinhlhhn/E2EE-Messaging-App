//
//  URLSessionDataTaskHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 24/6/25.
//

import Foundation
import Combine

public final class URLSessionDataTaskHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), Error> {
        debugPrint("☁️ CURL: \(request.curlString())")
        return session.dataTaskPublisher(for: request)
            .tryMap { result in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw InvalidHTTPResponseError()
                }
                debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
                return (result.data, httpResponse)
            }
            .eraseToAnyPublisher()
    }
}
