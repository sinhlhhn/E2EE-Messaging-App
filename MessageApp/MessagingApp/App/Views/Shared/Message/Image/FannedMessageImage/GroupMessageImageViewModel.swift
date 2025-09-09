//
//  GroupMessageImageViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 9/9/25.
//


import SwiftUI
import Combine

@Observable
class GroupMessageImageViewModel {
    enum ViewState {
        case loading
        case completed([UIImage])
    }
    
    private(set) var viewState: ViewState = .loading
    
    private let message: [ImageMessage]
    private var urls: [URL] {
        message.map { $0.path }
    }
    
    var originalName: [String] {
        message.map { $0.originalName }
    }
    private let downloadNetwork: NetworkModule
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(message: [ImageMessage], downloadNetwork: NetworkModule) {
        self.message = message
        self.downloadNetwork = downloadNetwork
    }
    
    func getData() {
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            return
        }
        
        // The local path is difference from the remote path
        // We only need the file name when retrieving from the local
        // And use the full path to retrieve data from remote
        let downloadDirectory = document.appending(path: "Images")
        
        // Check local cache first
        var localImages: [UIImage] = []
        var remoteURLs: [URL] = []
        
        for url in urls {
            let destinationURL = downloadDirectory.appending(path: url.lastPathComponent)
            if fileManager.fileExists(atPath: destinationURL.path),
               let image = UIImage(contentsOfFile: destinationURL.path) {
                localImages.append(image)
            } else {
                remoteURLs.append(url)
            }
        }
        
        if remoteURLs.isEmpty {
            // all loaded locally
            viewState = .completed(localImages)
            return
        }
        
        // Otherwise fetch the missing ones
        fetchImagesFromCloud(remoteURLs, existing: localImages)
    }
    
    func saveFile(from tempUrl: URL, to url: URL) throws -> URL {
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            throw NSError(domain: "", code: 0)
        }
        let downloadDirectory = document.appending(path: "Images")
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
    
    private func fetchImagesFromCloud(_ remoteURLs: [URL], existing: [UIImage]) {
        let publishers = remoteURLs.map { url in
            downloadNetwork.downloadData(url: url.path)
                .tryCompactMap { [weak self] result -> UIImage? in
                    guard let self else { return nil }
                    switch result {
                    case .downloading:
                        //TODO: Update UI with percentage
                        return nil
                    case .downloaded(let tempUrl, let originalFileName):
                        let directoryURL = URL.documentsDirectory.appending(path: originalFileName)
                        let destinationURL = try self.saveFile(from: tempUrl, to: directoryURL)
                        return UIImage(contentsOfFile: destinationURL.path)
                    }
                }
                .eraseToAnyPublisher()
        }
        
        Publishers.MergeMany(publishers)
            .collect() // gather all results into [UIImage]
            .sink { completion in
                if case let .failure(error) = completion {
                    debugPrint("❌ download failed: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] images in
                guard let self else { return }
                let allImages = existing + images
                self.viewState = .completed(allImages)
            }
            .store(in: &cancellables)
    }
}