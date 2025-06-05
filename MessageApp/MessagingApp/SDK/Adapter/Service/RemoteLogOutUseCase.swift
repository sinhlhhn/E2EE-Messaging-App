//
//  RemoteLogOutUseCase.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Combine

final class RemoteLogOutUseCase: LogOutUseCase {
    private let network: NetworkModule
    private let keyStore: KeyStoreModule
    
    init(network: NetworkModule, keyStore: KeyStoreModule) {
        self.network = network
        self.keyStore = keyStore
    }
    
    func logOut(userName: String) -> AnyPublisher<Void, Error> {
        network.logOut(userName: userName)
            .map { _ in
                self.keyStore.delete(key: .refreshToken)
                self.keyStore.delete(key: userName)
                return ()
            }
            .first()
            .eraseToAnyPublisher()
            
    }
}
