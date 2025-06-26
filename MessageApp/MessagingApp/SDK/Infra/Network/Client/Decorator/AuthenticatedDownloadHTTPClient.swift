//
//  AuthenticatedDownloadHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation
import Combine

final class AuthenticatedDownloadHTTPClient: HTTPClient {
    private let client: DownloadTaskHTTPClient
    private let tokenProvider: TokenProvider
    
    init(
        client: DownloadTaskHTTPClient,
        tokenProvider: TokenProvider
    ) {
        self.client = client
        self.tokenProvider = tokenProvider
    }
    
    func perform(request: URLRequest) -> AnyPublisher<HTTPURLResponse, any Error> {
        return performRequestWithToken(request: request)
            .flatMap{ response in
                if response.statusCode == 403 {
                    debugPrint("Got 403, refreshing token...")
                    return self.performRequestWithRefreshToken(request: request)
                }
                return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithRefreshToken(request: URLRequest)  -> AnyPublisher<HTTPURLResponse, any Error> {
        var request = request
        return tokenProvider.refreshToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: request)
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithToken(request: URLRequest) -> AnyPublisher<HTTPURLResponse, any Error> {
        var request = request
        return tokenProvider.fetchToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: request)
            }
            .eraseToAnyPublisher()
    }
}
