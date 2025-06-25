//
//  HTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

enum UploadResponse {
    case progress(percentage: Double)
    case response(response: HTTPURLResponse, data: Data?)
}

struct InvalidHTTPResponseError: Error {}

protocol HTTPClient<Request, Response> {
    associatedtype Request
    associatedtype Response
    func perform(request: Request) -> AnyPublisher<Response, Error>
}


