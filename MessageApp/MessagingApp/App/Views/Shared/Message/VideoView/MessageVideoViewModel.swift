//
//  MessageVideoViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 17/7/25.
//

import SwiftUI
import Combine

@Observable
class MessageVideoViewModel {
    enum ViewState {
        case loading
        case completed(URL)
    }
    
    private(set) var viewState: ViewState = .loading
    private var cancellables: Set<AnyCancellable> = []
    
    private let message: VideoMessage
    private var url: URL {
        message.path
    }
    
    private let downloadNetwork: NetworkModule
    
    init(message: VideoMessage, downloadNetwork: NetworkModule) {
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
        let downloadDirectory = document.appending(path: "Videos")
        let destinationURL = downloadDirectory.appending(path: url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            debugPrint("✅ load data from local")
            viewState = .completed(destinationURL)
            return
        }
        debugPrint("✅ load data from remote")
        fetchDataFromCloud(source: url.path)
        
    }
    
    func saveFile(from tempUrl: URL, to url: URL) throws -> URL {
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            throw NSError(domain: "", code: 0)
        }
        let downloadDirectory = document.appending(path: "Videos")
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
    
    private func fetchDataFromCloud(source: String) {
        downloadNetwork.downloadData(url: source)
            .sink { completion in
                switch completion {
                case .finished: debugPrint("fetchDataFromCloud finish")
                case .failure(let error): debugPrint("fetchDataFromCloud failure with error \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }
                debugPrint("fetchDataFromCloud result \(result)")
                switch result {
                case .downloading(let percentage):
                    //TODO: Update UI with percentage
                    break
                case .downloaded(let url, let originalFileName):
                    let directoryURL = URL.documentsDirectory.appending(path: originalFileName)
                    do {
                        let destinationURL = try saveFile(from: url, to: directoryURL)
                        viewState = .completed(destinationURL)
                    } catch {
                        debugPrint("❌ save file error \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)
    }
}
