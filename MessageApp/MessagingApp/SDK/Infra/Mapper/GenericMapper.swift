//
//  GenericMapper.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation

struct GenericMapper {
    static func map<T>(data: Data, response: HTTPURLResponse) throws -> T where T: Decodable {
        guard response.statusCode == 200 else {
            let error = URLError(.badServerResponse)
            throw error
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
