//
//  AuthenticationResponse.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//


struct AuthenticationResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
