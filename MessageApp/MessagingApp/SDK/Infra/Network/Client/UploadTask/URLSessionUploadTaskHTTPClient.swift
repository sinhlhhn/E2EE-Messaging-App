//
//  URLSessionUploadTaskHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 24/6/25.
//

import Foundation
import Combine

final class URLSessionUploadTaskHTTPClient: UploadTaskHTTPClient, TaskCancelHTTPClient {
    
    private let session: URLSession
    
    private let queue: DispatchQueue = .init(label: "com.slh.URLSessionUploadTaskHTTPClient")
    private var taskDictionary: [URL?: URLSessionUploadTask] = [:]
    private var taskSubjectDictionary: [URL?: PassthroughSubject<UploadResponse, Error>] = [:]
    private var resumeDataDictionary: [URL?: Data] = [:]
    
    init(session: URLSession) {
        self.session = session
    }
    
    func upload(request: (URLRequest, Data)) -> AnyPublisher<UploadResponse, any Error> {
        let (request, data) = request
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<UploadResponse, Error> = .init()
        
        guard let url = request.url else {
            subject.send(completion: .failure(InvalidHTTPResponseError()))
            
        }
        
        let task = session.uploadTask(with: request, from: data) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send((data, httpResponse))
            subject.send(completion: .finished)
        }
        
        updateTask(task, url: url)
        updateTaskSubject(subject, url: url)
        
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
            self?.resumeDataDictionary[url] = data
        }
    }
    
    func resumeUpload(url: URL) -> AnyPublisher<UploadResponse, any Error> {
        guard let data = getResumeData(url: url) else {
            debugPrint("Cannot resume task with \(url): no resume data found.")
            return Empty<UploadResponse, any Error>().eraseToAnyPublisher()
        }
        guard let subject = getTaskSubject(url: url) else {
            debugPrint("Cannot resume task with \(url): no task subject found.")
            return Empty<UploadResponse, any Error>().eraseToAnyPublisher()
        }
        
        debugPrint("Resume task with \(url)")
        
        let task = session.uploadTask(withResumeData: data) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send((data, httpResponse))
            subject.send(completion: .finished)
        }
        
        updateTask(task, url: url)
        updateTaskSubject(subject, url: url)
        
        task.resume()
        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    private func updateTask(_ task: URLSessionUploadTask?, url: URL?) {
        queue.async(flags: .barrier) {
            self.taskDictionary[url] = task
        }
    }
    
    private func getTask(url: URL) -> URLSessionUploadTask? {
        queue.sync {
            self.taskDictionary[url]
        }
    }
    
    private func getResumeData(url: URL) -> Data? {
        queue.sync {
            self.resumeDataDictionary[url]
        }
    }
    
    private func updateTaskSubject(_ subject: PassthroughSubject<UploadResponse, Error>, url: URL?) {
        queue.async(flags: .barrier) {
            self.taskSubjectDictionary[url] = subject
        }
    }
    
    private func getTaskSubject(url: URL) -> PassthroughSubject<UploadResponse, Error>? {
        queue.sync {
            self.taskSubjectDictionary[url]
        }
    }
}
