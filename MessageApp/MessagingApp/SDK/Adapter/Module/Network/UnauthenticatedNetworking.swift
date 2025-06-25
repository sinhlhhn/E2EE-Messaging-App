//
//  UnauthenticatedNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Combine

protocol UnauthenticatedNetworking {
    func registerUser(data: PasswordAuthentication) -> AnyPublisher<AuthenticationModel, Error>
    func logInUser(data: PasswordAuthentication) -> AnyPublisher<AuthenticationModel, Error>
    
}
