//
//  RemoteUserService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

class RemoteUserService: UserUseCase {
    let network: NetworkModule
    
    init(network: NetworkModule) {
        self.network = network
    }
    
    func fetchUsers() -> AnyPublisher<[User], Error> {
        network.fetchUsers()
    }
}
