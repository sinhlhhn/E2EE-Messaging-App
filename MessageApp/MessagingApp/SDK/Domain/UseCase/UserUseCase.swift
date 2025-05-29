//
//  UserService.swift
//  MessagingApp
//
//  Created by Sam on 22/5/25.
//

import Foundation
import Combine

protocol UserUseCase {
    func fetchUsers() -> AnyPublisher<[User], Error>
}
