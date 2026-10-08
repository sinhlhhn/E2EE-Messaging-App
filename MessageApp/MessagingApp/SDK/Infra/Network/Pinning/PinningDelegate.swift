//
//  PinningDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation

nonisolated
protocol PinningDelegate: Sendable {
    func handleChallenge(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    func handleChallenge(didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?)
}
