//
//  SplashViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/6/25.
//

import SwiftUI
import Combine

@Observable
final class SplashViewModel {
    private let tokenProvider: TokenProvider
    private let keyStore: KeyStoreModule
    let needAuth: () -> Void
    let didAuth: (String) -> Void
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(tokenProvider: TokenProvider, keyStore: KeyStoreModule, needAuth: @escaping () -> Void, didAuth: @escaping (String) -> Void) {
        self.tokenProvider = tokenProvider
        self.keyStore = keyStore
        self.needAuth = needAuth
        self.didAuth = didAuth
        
        subscribeToAuthenticationState()
    }
    
    private func subscribeToAuthenticationState() {
        tokenProvider.subscribeToAuthenticationState()
            .sink { [weak self] authenticationState in
                switch authenticationState {
                case .loggedOut:
                    self?.handleLogout()
                case .loggedIn(let user): self?.didAuth(user)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleLogout() {
        keyStore.deleteAllKeys()
        needAuth()
    }
    
    func checkAuthentication() {
        let isAuthent: String? = self.keyStore.retrieve(key: .refreshToken)
        if let _ = isAuthent, let user: String = self.keyStore.retrieve(key: .userName) {
            didAuth(user)
        } else {
            needAuth()
        }
    }
}
