//
//  MessageAttachmentViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 31/7/25.
//


import SwiftUI
import Combine

@Observable
class MessageAttachmentViewModel {
    enum ViewState {
        case loading
        case completed(String)
    }
    
    private(set) var viewState: ViewState = .loading
    
    private let attachmentMessage: AttachmentMessage
    private var url: URL {
        attachmentMessage.path
    }
    
    var originalName: String {
        attachmentMessage.originalName
    }
    private let downloadNetwork: NetworkModule
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(attachmentMessage: AttachmentMessage, downloadNetwork: NetworkModule) {
        self.attachmentMessage = attachmentMessage
        self.downloadNetwork = downloadNetwork
    }
    
    func getData() {
        guard let destinationURL = getDestinationURL() else {
            return
        }
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            debugPrint("load data from local")
            viewState = .completed(getFileSize(from: destinationURL.path))
            return
        }
        debugPrint("load data from remote")
        fetchImageFromCloud(source: url.path)
        
    }
    
    func getDestinationURL() -> URL? {
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            return nil
        }
        
        let downloadDirectory = document.appending(path: "Download")
        let destinationURL = downloadDirectory.appending(path: url.lastPathComponent)
        
        return destinationURL
    }
    
    func saveFile(from tempUrl: URL, to url: URL) throws -> URL {
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            throw NSError(domain: "", code: 0)
        }
        let downloadDirectory = document.appending(path: "Download")
        let destinationURL = downloadDirectory.appending(path: url.lastPathComponent)
        
        if !fileManager.fileExists(atPath: downloadDirectory.path) {
            do {
                try fileManager.createDirectory(at: downloadDirectory, withIntermediateDirectories: true)
            } catch {
                debugPrint("❌ createDirectory error \(error.localizedDescription)")
                throw error
            }
        }
        do {
            try fileManager.moveItem(at: tempUrl, to: destinationURL)
            return destinationURL
        } catch {
            debugPrint("❌ moveItem error \(error.localizedDescription)")
            throw error
        }
    }
    
    private func fetchImageFromCloud(source: String) {
        downloadNetwork.downloadData(url: source)
            .sink { completion in
                switch completion {
                case .finished: debugPrint("fetchImageFromCloud finish")
                case .failure(let error): debugPrint("fetchImageFromCloud failure with error \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }
                debugPrint("fetchImageFromCloud result \(result)")
                switch result {
                case .downloading(let percentage):
                    //TODO: Update UI with percentage
                    break
                case .downloaded(let url, let originalFileName):
                    let directoryURL = URL.documentsDirectory.appending(path: originalFileName)
                    do {
                        let destinationURL = try saveFile(from: url, to: directoryURL)
                        viewState = .completed(getFileSize(from: destinationURL.path))
                    } catch {
                        debugPrint("❌ save file error \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)
    }
}

func getFileSize(from path: String) -> String {
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        if let fileSize = attributes[.size] as? NSNumber {
            let byteCount = fileSize.int64Value
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: byteCount)
        }
    } catch {
        debugPrint("❌ Failed to get file attributes: \(error.localizedDescription)")
    }
    return "Unknown size"
}
