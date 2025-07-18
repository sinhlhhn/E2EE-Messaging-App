//
//  MessageAttachmentView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI

struct MessageAttachmentView: View {
    
    let viewModel: MessageAttachmentViewModel
    
    init(viewModel: MessageAttachmentViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        switch viewModel.viewState {
        case .loading:
            LoadingView()
        case .completed(let fileTitle, let fileSize):
            HStack(alignment: .top) {
                Image(systemName: "newspaper")
                    .padding()
                    .background(Color.red)
                    .clipShape(Circle())
                VStack {
                    Text(fileTitle)
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
    }
}

import Combine
@Observable
class MessageAttachmentViewModel {
    enum ViewState {
        case loading
        case completed(String, String)
    }
    
    private(set) var viewState: ViewState = .loading
    
    private let url: URL
    private let downloadNetwork: NetworkModule
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(url: URL, downloadNetwork: NetworkModule) {
        self.url = url
        self.downloadNetwork = downloadNetwork
    }
    
    func getData() {
        print("start get data from \(url)")
        if FileManager.default.fileExists(atPath: url.path) {
            let fileName = url.lastPathComponent
            viewState = .completed(fileName, String(getFileSize(from: url.path)))
            return
        }
        
        fetchImageFromCloud(source: url.path)
        
    }
    
    private func fetchImageFromCloud(source: String) {
        downloadNetwork.downloadData(url: source)
            .sink { completion in
                switch completion {
                case .finished: debugPrint("fetchImageFromCloud finish")
                case .failure(let error): debugPrint("fetchImageFromCloud failure with error \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] result in
                debugPrint("fetchImageFromCloud result \(result)")
                let fileName = result.lastPathComponent
                self?.viewState = .completed(fileName, String(getFileSize(from: result.path)))
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
