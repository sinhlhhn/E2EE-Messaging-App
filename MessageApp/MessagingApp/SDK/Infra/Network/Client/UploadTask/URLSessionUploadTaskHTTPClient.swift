//
//  URLSessionUploadTaskHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 24/6/25.
//

import Foundation
import Combine

final class URLSessionUploadTaskHTTPClient: UploadTaskHTTPClient {
    private let session: URLSession
    
    private let queue: DispatchQueue = .init(label: "com.slh.URLSessionUploadTaskHTTPClient")
    private var taskDictionary: [Int: URLSessionUploadTask] = [:]
    private var taskSubjectDictionary: [Int: PassthroughSubject<(Data?, HTTPURLResponse), Error>] = [:]
    private var resumeDataDictionary: [Int: Data] = [:]
    
    init(session: URLSession) {
        self.session = session
    }
    
    func upload(request: (URLRequest, Data)) -> AnyPublisher<(Optional<Data>, HTTPURLResponse), any Error> {
        let (request, data) = request
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<(Data?, HTTPURLResponse), Error> = .init()
        let task = session.uploadTask(with: request, from: data) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send((data, httpResponse))
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
    
    func suspend(id: Int) {
        let task = getTask(id: id)
        task?.suspend()
    }
    
    func cancel(id: Int) {
        let task = getTask(id: id)
        task?.cancel { [weak self] data in
            self?.resumeDataDictionary[id] = data
        }
    }
    
    func resume(id: Int) -> AnyPublisher<(Optional<Data>, HTTPURLResponse), any Error> {
        guard let data = getResumeData(id: id) else {
            debugPrint("Cannot resume task with ID \(id): no resume data found.")
            return Empty<(Optional<Data>, HTTPURLResponse), any Error>().eraseToAnyPublisher()
        }
        guard let subject = getTaskSubject(id: id) else {
            debugPrint("Cannot resume task with ID \(id): no task subject found.")
            return Empty<(Optional<Data>, HTTPURLResponse), any Error>().eraseToAnyPublisher()
        }
        
        debugPrint("Resume task with ID \(id)")
        
        let task = session.uploadTask(withResumeData: data) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send((data, httpResponse))
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
    
    private func updateTask(_ task: URLSessionUploadTask?, id: Int) {
        queue.async(flags: .barrier) {
            self.taskDictionary[id] = task
        }
    }
    
    private func getTask(id: Int) -> URLSessionUploadTask? {
        queue.sync {
            self.taskDictionary[id]
        }
    }
    
    private func getResumeData(id: Int) -> Data? {
        queue.sync {
            self.resumeDataDictionary[id]
        }
    }
    
    private func updateTaskSubject(_ subject: PassthroughSubject<(Data?, HTTPURLResponse), Error>, id: Int) {
        queue.async(flags: .barrier) {
            self.taskSubjectDictionary[id] = subject
        }
    }
    
    private func getTaskSubject(id: Int) -> PassthroughSubject<(Data?, HTTPURLResponse), Error>? {
        queue.sync {
            self.taskSubjectDictionary[id]
        }
    }
}
