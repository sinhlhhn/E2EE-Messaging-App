//
//  TokenProvider.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Combine

protocol TokenProvider {
    func fetchToken() -> AnyPublisher<String, Error>
    func refreshToken() -> AnyPublisher<String, Error>
}
