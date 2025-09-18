//
//  MessageImageViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 31/7/25.
//

import SwiftUI
import Combine

@Observable
class MessageImageViewModel {
    enum ViewState {
        case loading
        case completed(UIImage)
    }
    
    private(set) var viewState: ViewState = .loading
    
    @ObservationIgnored
    private lazy var reader = createImageReader()
    
    private func createImageReader() -> UIImageReader {
        var configuration = UIImageReader.Configuration()
        configuration.preparesImagesForDisplay = true
        configuration.preferredThumbnailSize = CGSize(width: 10000, height: 10000)
        return UIImageReader(configuration: configuration)
    }
    
    private let message: ImageMessage
    private var url: URL {
        message.path
    }
    
    var originalName: String {
        message.originalName
    }
    private let downloadNetwork: NetworkModule
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(message: ImageMessage, downloadNetwork: NetworkModule) {
        self.message = message
        self.downloadNetwork = downloadNetwork
    }
    
    func getData() async {
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            return
        }
        
        // The local path is difference from the remote path
        // We only need the file name when retrieving from the local
        // And use the full path to retrieve data from remote
        let downloadDirectory = document.appending(path: "Images")
        let destinationURL = downloadDirectory.appending(path: url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            debugPrint("✅ load data from local")
            guard let image = await reader.image(contentsOf: destinationURL) else {
                debugPrint("❌ Cannot load image")
                return
            }
            viewState = .completed(image)
            return
        }
        debugPrint("✅ load data from remote")
        fetchImageFromCloud(source: url.path)
        
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
    
    private func fetchImageFromCloud(source: String) {
        downloadNetwork.downloadData(url: source)
            .sink { completion in
                switch completion {
                case .finished: debugPrint("fetchImageFromCloud finish")
                case .failure(let error): debugPrint("fetchImageFromCloud from \(source) failure with error \(error.localizedDescription)")
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
                        guard let image = UIImage(contentsOfFile: destinationURL.path) else {
                            debugPrint("❌ Cannot load image")
                            return
                        }
                        viewState = .completed(image)
                    } catch {
                        debugPrint("❌ save file error \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)
    }
}
