//
//  HttpAuthenticationNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

final class HttpAuthenticationNetwork: AuthenticationNetwork {
    
    private let network: HTTPClient
    
    init(network: HTTPClient) {
        self.network = network
    }
    
    func registerUser(data: PasswordAuthentication) -> AnyPublisher<AuthenticationModel, Error> {
        let urlString = "http://localhost:3000/auth/register"
        
        let request = buildRequest(url: urlString, method: .post, body: try? data.asDictionary())
        
        return network.perform(request: request)
            .tryMap { data, response -> AuthenticationResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { AuthenticationModel(accessToken: $0.accessToken, refreshToken: $0.refreshToken) }
            .eraseToAnyPublisher()
    }
    
    func logInUser(data: PasswordAuthentication) -> AnyPublisher<AuthenticationModel, any Error> {
        let urlString = "http://localhost:3000/auth/login"
        
        let request = buildRequest(url: urlString, method: .post, body: try? data.asDictionary())
        
        return network.perform(request: request)
            .tryMap { data, response -> AuthenticationResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { AuthenticationModel(accessToken: $0.accessToken, refreshToken: $0.refreshToken) }
            .eraseToAnyPublisher()
    }
}
