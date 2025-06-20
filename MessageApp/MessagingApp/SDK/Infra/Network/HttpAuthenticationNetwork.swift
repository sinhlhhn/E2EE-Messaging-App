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
        let urlString = "\(localhost)auth/register"
        
        let request = buildRequest(url: urlString, method: .post, body: try? data.asDictionary())
        
        return network.perform(request: request)
            .tryMap { data, response in
                
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let model = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                
                return AuthenticationModel(accessToken: model.accessToken, refreshToken: model.refreshToken)
            }
            .eraseToAnyPublisher()
    }
    
    func logInUser(data: PasswordAuthentication) -> AnyPublisher<AuthenticationModel, any Error> {
        let urlString = "\(localhost)auth/login"
        
        let request = buildRequest(url: urlString, method: .post, body: try? data.asDictionary())
        
        return network.perform(request: request)
            .tryMap { data, response in
                
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let model = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                
                return AuthenticationModel(accessToken: model.accessToken, refreshToken: model.refreshToken)
            }
            .eraseToAnyPublisher()
    }
}
