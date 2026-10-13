//
//  TokenProvider.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Combine

public enum AuthenticationState {
    case loggedIn(User)
    case loggedOut
}

public protocol TokenProvider {
    func subscribeToAuthenticationState() -> AnyPublisher<AuthenticationState, Never>
    
    func fetchToken() -> AnyPublisher<String, Error>
    func refreshToken() -> AnyPublisher<String, Error>
}
