//
//  HTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

protocol HTTPClient {
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), Error>
}

extension URLSession: HTTPClient {
    struct InvalidHTTPResponseError: Error {}
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), Error> {
        return dataTaskPublisher(for: request)
            .tryMap { result in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw InvalidHTTPResponseError()
                }
                return (result.data, httpResponse)
            }
            .eraseToAnyPublisher()
    }
}
