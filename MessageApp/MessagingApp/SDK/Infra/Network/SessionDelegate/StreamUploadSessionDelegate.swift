//
//  StreamUploadSessionDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 30/6/25.
//

import Foundation
import Combine

/// Responsibilities:
///     - Handle streaming upload data when triggering `uploadTask(withStreamedRequest:)`.
///     - Observe the data upload progress.
final class StreamUploadSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private let pinning: PinningDelegate
    
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }
    
    private var streamingTimer: Timer?
    private var canWrite = true
    private var boundStreams: [Int: Streams] = [:]
    
    private var progress = PassthroughSubject<Double, Error>()
    var progressPublisher: AnyPublisher<Double, Error> {
        progress.eraseToAnyPublisher()
    }
    
    init(pinning: PinningDelegate) {
        self.pinning = pinning
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        pinning.handleChallenge(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let value = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progress.send(value)
        if value == 1 {
            progress.send(completion: .finished)
        }
    }
}

extension StreamUploadSessionDelegate: StreamDelegate {
    func createStream(for id: Int) {
        
    }
    
    private func createStream() -> Streams {
        var inputOrNil: InputStream? = nil
        var outputOrNil: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: 1024,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` will contain non-nil streams.")
        }
        // configure and open output stream
        output.delegate = self
        output.schedule(in: .main, forMode: .default)
        output.open()
    
        return Streams(input: input, output: output)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        print("Delegate: needNewBodyStream")
        let boundStream = createStream()
        print("Create streams with \(task.taskIdentifier)")
        completionHandler(boundStream.input)
        startSendingData(boundStream)
        print("Delegate: start sending data")
    }
    
    private func startSendingData(_ boundStream: Streams) {
        DispatchQueue.main.async {
            self.streamingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
                [weak self] timer in
                guard let self = self else { return }
                
                if self.canWrite {
                    let message = "*** \(Date())\r\n"
                    guard let messageData = message.data(using: .utf8) else { return }
                    let messageCount = messageData.count
                    let bytesWritten: Int = messageData.withUnsafeBytes() { (buffer: UnsafePointer<UInt8>) in
                        self.canWrite = false
                        print("streaming: \(message)")
                        return boundStream.output.write(buffer, maxLength: messageCount)
                    }
                    if bytesWritten < messageCount {
                        // Handle writing less data than expected.
                        print("Delegate: Write less data than expected. \(bytesWritten) - \(messageCount)")
                    }
                }
            }
            
            self.streamingTimer?.fire()
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        if eventCode.contains(.hasSpaceAvailable) {
            print("Delegate: Has space available")
            canWrite = true
        }
        if eventCode.contains(.errorOccurred) {
            // Close the streams and alert the user that the upload failed.
            print("Delegate: Error occurred")
            closeStream(aStream)
        }
        
        if eventCode.contains(.endEncountered) {
            // Close the streams and alert the user that the upload failed.
            print("Delegate: Encountered")
            closeStream(aStream)
        }
        
        print("Delegate: Stream event: \(eventCode)")
    }
    
    private func closeStream(_ stream: Stream) {
        stream.close()
        streamingTimer?.invalidate()
        streamingTimer = nil
    }
}
