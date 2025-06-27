//
//  UploadSessionDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation
import Combine


final class UploadSessionDelegate : NSObject, URLSessionDelegate, URLSessionTaskDelegate, StreamDelegate {
    private let pinning: PinningDelegate
    
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
        print("didSendBodyData \(value)")
        progress.send(value)
        if value == 1 {
            progress.send(completion: .finished)
        }
    }
    
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }
    lazy var boundStreams: Streams = {
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
        print("Create streams")
    
        return Streams(input: input, output: output)
    }()
    
    var canWrite = true
    private var streamingTimer: Timer?
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        print("Delegate: needNewBodyStream")
        completionHandler(boundStreams.input)
        
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
                        return self.boundStreams.output.write(buffer, maxLength: messageCount)
                    }
                    if bytesWritten < messageCount {
                        // Handle writing less data than expected.
                    }
                }
            }
            
            self.streamingTimer?.fire()
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard aStream == boundStreams.output else {
            print("Delegate: Unexpected stream \(aStream)")
            return
        }
        if eventCode.contains(.hasSpaceAvailable) {
            print("Delegate: Has space available")
            canWrite = true
        }
        if eventCode.contains(.errorOccurred) {
            // Close the streams and alert the user that the upload failed.
            print("Delegate: Error occurred")
            aStream.close()
        }
        
        print("Delegate: Stream event: \(eventCode)")
    }
}
