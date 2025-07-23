//
//  MessageAttachmentView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI

struct MessageAttachmentView: View {
    
    @State private var viewModel: MessageAttachmentViewModel
    
    init(viewModel: MessageAttachmentViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView()
            case .completed(let fileSize):
                HStack(alignment: .top) {
                    Image(systemName: "newspaper")
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                    VStack {
                        Text(viewModel.originalName)
                            .font(.title)
                        Text(fileSize)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.5))
                .clipShape(.rect(cornerRadius: 20))
            }
        }.onAppear {
            viewModel.getData()
        }
    }
}

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
        let fileManager = FileManager.default
        guard let document = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ cannot get document directory ")
            return
        }
        
        let downloadDirectory = document.appending(path: "Download")
        let destinationURL = downloadDirectory.appending(path: url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            debugPrint("load data from local")
            viewState = .completed(String(getFileSize(from: destinationURL.path)))
            return
        }
        debugPrint("load data from remote")
        fetchImageFromCloud(source: url.path)
        
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
                        viewState = .completed(String(getFileSize(from: destinationURL.path)))
                    } catch {
                        debugPrint("❌ save file error \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)
    }
}

func getFileSize(from path: String) -> Int {
    var contentLength = 0
    let attributes = try! FileManager.default.attributesOfItem(atPath: path)
    if let fileSize = attributes[.size] as? NSNumber {
        contentLength = fileSize.intValue
        print("Content-Length: \(contentLength)")
    }
    return contentLength
}

//#Preview {
//    MessageAttachmentView(fileTitle: "File title", fileSize: "File size")
//}
