//
//  AuthenticatedHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 24/6/25.
//

import Foundation
import Combine

final class AuthenticatedHTTPClient: HTTPClient {
    private let client: URLHTTPClient
    private let tokenProvider: TokenProvider
    
    init(
        client: URLHTTPClient,
        tokenProvider: TokenProvider
    ) {
        self.client = client
        self.tokenProvider = tokenProvider
    }
    
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        return performRequestWithToken(request: request)
            .flatMap{ (data, response) in
                if response.statusCode == 403 {
                    debugPrint("Got 403, refreshing token...")
                    return self.performRequestWithRefreshToken(request: request)
                }
                return Just((data, response)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithRefreshToken(request: URLRequest)  -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        var request = request
        return tokenProvider.refreshToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: request)
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithToken(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        var request = request
        return tokenProvider.fetchToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: request)
            }
            .eraseToAnyPublisher()
    }
}
