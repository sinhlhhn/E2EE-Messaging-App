//
//  LogOutUseCase.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Combine

public protocol LogOutUseCase {
    func logOut(userName: String) -> AnyPublisher<Void, Error>
}
