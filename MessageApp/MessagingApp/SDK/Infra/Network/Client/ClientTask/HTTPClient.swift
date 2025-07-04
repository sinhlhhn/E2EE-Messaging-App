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

protocol UploadTaskHTTPClient {
    func upload(request: (URLRequest, Data)) -> AnyPublisher<(Data?, HTTPURLResponse), Error>
    func suspend(id: Int)
    func cancel(id: Int)
    func resume(id: Int) -> AnyPublisher<(Optional<Data>, HTTPURLResponse), any Error>
}

protocol StreamUploadTaskHTTPClient {
    func upload(request: URLRequest) -> AnyPublisher<Void, Error>
}

protocol DownloadTaskHTTPClient {
    func download(request: URLRequest) -> AnyPublisher<HTTPURLResponse, any Error>
}


