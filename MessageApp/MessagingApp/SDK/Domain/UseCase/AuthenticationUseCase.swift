//
//  AuthenticationService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 22/5/25.
//

import Foundation

import Combine
protocol AuthenticationUseCase<Authentication> {
    associatedtype Authentication
    func login(data: Authentication) -> AnyPublisher<Bool, Error>
}
