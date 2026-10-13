//
//  RemoteUserService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

public class RemoteUserService: UserUseCase {
    let network: NetworkModule
    
    public init(network: NetworkModule) {
        self.network = network
    }
    
    public func fetchUsers() -> AnyPublisher<[User], Error> {
        network.fetchUsers()
    }
}
