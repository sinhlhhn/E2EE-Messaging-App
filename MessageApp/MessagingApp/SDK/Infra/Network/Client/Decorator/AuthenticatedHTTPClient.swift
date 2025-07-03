//
//  AuthenticatedHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 24/6/25.
//

import Foundation
import Combine

final class AuthenticatedHTTPClient: HTTPClient, UploadTaskHTTPClient, DownloadTaskHTTPClient, StreamUploadTaskHTTPClient {
    private let client: DataTaskHTTPClient
    private let uploadClient: UploadTaskHTTPClient
    private let streamUploadClient: StreamUploadTaskHTTPClient
    private let downloadClient: DownloadTaskHTTPClient
    private let tokenProvider: TokenProvider
    
    init(
        client: DataTaskHTTPClient,
        uploadClient: UploadTaskHTTPClient,
        streamUploadClient: StreamUploadTaskHTTPClient,
        downloadClient: DownloadTaskHTTPClient,
        tokenProvider: TokenProvider
    ) {
        self.client = client
        self.uploadClient = uploadClient
        self.streamUploadClient = streamUploadClient
        self.downloadClient = downloadClient
        self.tokenProvider = tokenProvider
    }
    
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        return performRequestWithToken(request: request)
            .flatMap { request in
                self.client.perform(request: request)
            }
            .flatMap{ (data, response) in
                if response.statusCode == 403 {
                    debugPrint("Got 403, refreshing token...")
                    return self.performRequestWithRefreshToken(request: request)
                        .flatMap { request in
                            self.client.perform(request: request)
                        }
                        .eraseToAnyPublisher()
                }
                return Just((data, response)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func upload(request: (URLRequest, Data)) -> AnyPublisher<(Data?, HTTPURLResponse), any Error> {
        let (request, data) = request
        return performRequestWithToken(request: request)
            .flatMap { request in
                self.uploadClient.upload(request: (request, data))
            }
            .flatMap{ (responseData, response) in
                if response.statusCode == 403 {
                    debugPrint("Got 403, refreshing token...")
                    return self.performRequestWithRefreshToken(request: request)
                        .flatMap { request in
                            self.uploadClient.upload(request: (request, data))
                        }
                        .eraseToAnyPublisher()
                }
                return Just((responseData, response)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func upload(request: URLRequest) -> AnyPublisher<Void, any Error> {
        return performRequestWithRefreshToken(request: request)
            .flatMap { request in
                self.streamUploadClient.upload(request: request)
            }
            .eraseToAnyPublisher()
    }
    
    
    func download(request: URLRequest) -> AnyPublisher<HTTPURLResponse, any Error> {
        return performRequestWithToken(request: request)
            .flatMap { request in
                self.downloadClient.download(request: request)
            }
            .flatMap{ response in
                if response.statusCode == 403 {
                    debugPrint("Got 403, refreshing token...")
                    return self.performRequestWithRefreshToken(request: request)
                        .flatMap { request in
                            self.downloadClient.download(request: request)
                        }
                        .eraseToAnyPublisher()
                }
                return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithRefreshToken(request: URLRequest)  -> AnyPublisher<URLRequest, any Error> {
        var request = request
        return tokenProvider.refreshToken()
            .map { token in
                request.setBearerToken(token)
                return request
            }
            .eraseToAnyPublisher()
    }
    
    private func performRequestWithToken(request: URLRequest) -> AnyPublisher<URLRequest, any Error> {
        var request = request
        return tokenProvider.fetchToken()
            .map { token in
                request.setBearerToken(token)
                return request
            }
            .eraseToAnyPublisher()
    }
}
