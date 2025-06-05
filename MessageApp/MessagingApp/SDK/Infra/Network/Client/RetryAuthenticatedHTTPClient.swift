//
//  RetryAuthenticatedHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

final class RetryAuthenticatedHTTPClient: HTTPClient {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        let retryTimes = 2
        return client.perform(request: request)
            .catch { error in
                return self.performWithRetry(request, retryTimes: retryTimes)
            }
            .eraseToAnyPublisher()
    }
    
    private func performWithRetry(_ request: URLRequest, retryTimes: Int) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        if retryTimes == 0 {
            return Fail<(Data, HTTPURLResponse), any Error>(error: NSError(domain: "", code: 1)).eraseToAnyPublisher() // should log out
        }
        return performWithRetry(request, retryTimes: retryTimes - 1)
    }
}
