//
//  URLSessionDownloadTaskHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation
import Combine

final class URLSessionDownloadTaskHTTPClient: DownloadTaskHTTPClient, TaskCancelHTTPClient {
    private let session: URLSession
    
    private let queue: DispatchQueue = .init(label: "com.slh.URLSessionDownloadTaskHTTPClient")
    private var taskDictionary: [Int: URLSessionDownloadTask] = [:]
    private var taskSubjectDictionary: [Int: PassthroughSubject<HTTPURLResponse, Error>] = [:]
    private var resumeDataDictionary: [Int: Data] = [:]
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func download(request: URLRequest) -> AnyPublisher<HTTPURLResponse, any Error> {
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<HTTPURLResponse, Error> = .init()
        let task = session.downloadTask(with: request) { url, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send(httpResponse)
            subject.send(completion: .finished)
        }
        
        task.resume()
        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    func suspend(url: URL) {
        let task = getTask(url: url)
        task?.suspend()
    }
    
    func cancel(url: URL) {
        let task = getTask(url: url)
        task?.cancel { [weak self] data in
            self?.resumeDataDictionary[id] = data
        }
    }
    
    func resumeDownload(id: Int) -> AnyPublisher<HTTPURLResponse, any Error> {
        guard let data = getResumeData(id: id) else {
            debugPrint("Cannot resume task with ID \(id): no resume data found.")
            return Empty<HTTPURLResponse, any Error>().eraseToAnyPublisher()
        }
        guard let subject = getTaskSubject(id: id) else {
            debugPrint("Cannot resume task with ID \(id): no task subject found.")
            return Empty<HTTPURLResponse, any Error>().eraseToAnyPublisher()
        }
        
        debugPrint("Resume task with ID \(id)")
        
        let task = session.downloadTask(withResumeData: data) { url, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send(httpResponse)
            subject.send(completion: .finished)
        }
        
        updateTask(task, id: task.taskIdentifier)
        updateTaskSubject(subject, id: task.taskIdentifier)
        
        task.resume()
        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    private func updateTask(_ task: URLSessionDownloadTask?, id: Int) {
        queue.async(flags: .barrier) {
            self.taskDictionary[url] = task
        }
    }
    
    private func getTask(url: URL) -> URLSessionDownloadTask? {
        queue.sync {
            self.taskDictionary[url]
        }
    }
    
    private func getResumeData(id: Int) -> Data? {
        queue.sync {
            self.resumeDataDictionary[id]
        }
    }
    
    private func updateTaskSubject(_ subject: PassthroughSubject<HTTPURLResponse, Error>, id: Int) {
        queue.async(flags: .barrier) {
            self.taskSubjectDictionary[id] = subject
        }
    }
    
    private func getTaskSubject(id: Int) -> PassthroughSubject<HTTPURLResponse, Error>? {
        queue.sync {
            self.taskSubjectDictionary[id]
        }
    }
}
