//
//  AuthenticatedHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

final class AuthenticatedHTTPClient: HTTPClient {
    private let client: HTTPClient
    private let tokenProvider: TokenProvider
    
    init(client: HTTPClient, tokenProvider: TokenProvider) {
        self.client = client
        self.tokenProvider = tokenProvider
    }
    
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        var request = request
        return tokenProvider.fetchToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: request)
            }
            .eraseToAnyPublisher()
    }
}
