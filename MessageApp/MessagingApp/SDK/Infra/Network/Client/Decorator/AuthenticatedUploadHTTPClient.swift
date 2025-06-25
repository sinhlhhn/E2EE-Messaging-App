//
//  AuthenticatedUploadHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 24/6/25.
//
import Foundation
import Combine

final class AuthenticatedUploadHTTPClient: HTTPClient {
    private let client: UploadHTTPClient
    private let tokenProvider: TokenProvider
    
    init(
        client: UploadHTTPClient,
        tokenProvider: TokenProvider
    ) {
        self.client = client
        self.tokenProvider = tokenProvider
    }
    
    func perform(request: (URLRequest, Data)) -> AnyPublisher<(Data?, HTTPURLResponse), any Error> {
        let (request, data) = request
        return performRequestWithToken(request: request, data: data)
            .flatMap{ (responseData, response) in
                if response.statusCode == 403 {
                    debugPrint("Got 403, refreshing token...")
                    return self.performRequestWithRefreshToken(request: request, data: data)
                }
                return Just((responseData, response)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithRefreshToken(request: URLRequest, data: Data)  -> AnyPublisher<(Data?, HTTPURLResponse), any Error> {
        var request = request
        return tokenProvider.refreshToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: (request, data))
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithToken(request: URLRequest, data: Data) -> AnyPublisher<(Data?, HTTPURLResponse), any Error> {
        var request = request
        return tokenProvider.fetchToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: (request, data))
            }
            .eraseToAnyPublisher()
    }
}
