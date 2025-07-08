//
//  HTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

//enum UploadResponse {
//    case progress(percentage: Double)
//    case response(response: HTTPURLResponse, data: Data?)
//}

struct InvalidHTTPResponseError: Error {}

protocol HTTPClient<Request, Response> {
    associatedtype Request
    associatedtype Response
    func perform(request: Request) -> AnyPublisher<Response, Error>
}

protocol TaskCancelHTTPClient {
    func cancel(url: URL)
    func suspend(url: URL)
}

protocol UploadTaskHTTPClient {
    typealias UploadResponse = (Data?, HTTPURLResponse)
    func upload(request: (URLRequest, Data)) -> AnyPublisher<UploadResponse, Error>
    func resumeUpload(url: URL) -> AnyPublisher<UploadResponse, any Error>
}

protocol DownloadTaskHTTPClient {
    func download(request: URLRequest) -> AnyPublisher<HTTPURLResponse, any Error>
    func resumeDownload(url: URL) -> AnyPublisher<HTTPURLResponse, any Error>
}

protocol StreamUploadTaskHTTPClient {
    func upload(request: URLRequest) -> AnyPublisher<Void, Error>
}


