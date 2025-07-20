//
//  RetryAuthenticatedHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

final class RetryAuthenticatedHTTPClient: HTTPClient {
    private let client: DataTaskHTTPClient
    
    init(client: DataTaskHTTPClient) {
        self.client = client
    }
    
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        let retryTimes = 2
        return client.perform(request: request)
            .flatMap { (data, response) in
                if response.statusCode != 200 {
                    return self.performWithRetry(request, retryTimes: retryTimes, data: (data, response))
                }
                return Just((data, response)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func performWithRetry(_ request: URLRequest, retryTimes: Int, data: (Data, HTTPURLResponse)) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        if retryTimes == 0 {
            return Just(data).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        return performWithRetry(request, retryTimes: retryTimes - 1, data: data)
    }
}
