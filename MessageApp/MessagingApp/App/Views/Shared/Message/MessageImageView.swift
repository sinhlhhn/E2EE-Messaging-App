//
//  MessageView 2.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//


import SwiftUI

struct MessageImageView: View {
    @State private var viewModel: MessageImageViewModel
    
    init(viewModel: MessageImageViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        contentView
    }
    
    private var contentView: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView()
            case .completed(let image):
                Image(uiImage: image)
                    .resizable()
                    .clipShape(.rect(cornerRadius: 10))
                    .frame(maxWidth: 200, maxHeight: 400)
            }
        }.task {
            viewModel.getData()
        }
        
    }
}

import Combine
@Observable
class MessageImageViewModel {
    enum ViewState {
        case loading
        case completed(UIImage)
    }
    
    private(set) var viewState: ViewState = .loading
    
    private let path: String
    private let downloadNetwork: NetworkModule
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(path: String, downloadNetwork: NetworkModule) {
        self.path = path
        self.downloadNetwork = downloadNetwork
    }
    
    func getData() {
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            return
        }
        
        //TODO: use original name instead of path
        let downloadDirectory = document.appending(path: "Images")
        let destinationURL = downloadDirectory.appending(path: path)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            debugPrint("✅ load data from local")
            guard let image = UIImage(contentsOfFile: destinationURL.path) else {
                debugPrint("❌ Cannot load image")
                return
            }
            viewState = .completed(image)
            return
        }
        debugPrint("✅ load data from remote")
        fetchImageFromCloud(source: path)
        
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

//#Preview {
//    MessageImageView(image: "tiger")
//}
