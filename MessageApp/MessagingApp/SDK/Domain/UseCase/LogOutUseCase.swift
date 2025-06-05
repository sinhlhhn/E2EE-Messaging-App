//
//  LogOutUseCase.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Combine

protocol LogOutUseCase {
    func logOut(userName: String) -> AnyPublisher<Void, Error>
}
