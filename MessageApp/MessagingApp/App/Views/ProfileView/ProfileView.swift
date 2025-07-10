//
//  ProfileView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 25/6/25.
//

import SwiftUI

struct ProfileView: View {
    
    private let viewModel: ProfileViewModel
    
    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            Image("keypad")
                .frame(width: 100, height: 100)
                .background(Color.gray)
                .clipShape(Circle())
            Button {
                viewModel.downloadData()
            } label: {
                Text("Download data")
            }
            
            Button {
                viewModel.uploadImage()
            } label: {
                Text("Upload image")
            }
            
            Button {
                viewModel.uploadStreamRawData()
            } label: {
                Text("Upload Raw Stream data")
            }

        }
    }
}

@Observable
class ProfileViewModel {
    private let service: ProfileUseCase
    private var cancellables: Set<AnyCancellable> = []
    
    init(service: ProfileUseCase) {
        self.service = service
    }
    
    func downloadData() {
        service.downloadImage()
    }
    
    func uploadImage() {
        guard let image = UIImage(named: "tiger") else {
            print("Failed to load image")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        service.uploadImage(image: ImageData(image: imageData, userName: "", fileName: "tiger.jpg", fieldName: "image"))
            .sink { _ in
                
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)

    }
    
    func uploadStreamRawData() {
        service.uploadStreamRawData()
    }
}

struct ImageData {
    let id = UUID()
    let image: Data
    let userName: String
    let fileName: String
    let fieldName: String
}

protocol ProfileUseCase {
    func uploadImage(image: ImageData) -> AnyPublisher<Void, Error>
    func uploadStreamRawData()
    func downloadImage()
}

import Combine
class ProfileService: ProfileUseCase {
    private let network: NetworkModule
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(network: NetworkModule) {
        self.network = network
    }
    
    func uploadImage(image: ImageData) -> AnyPublisher<Void, Error> {
        let images: [MultipartImage] = [
            .init(data: image.image, fieldName: image.fieldName, fileName: image.fileName, mimeType: "jpg")
        ]
        return network.uploadImage(images: images, fields: [])
            .map { _ in
                Void()
            }
            .eraseToAnyPublisher()
        
    }
    
    func cancel(image: ImageData) {
        network.cancelRequest()
    }
    
    func uploadStreamRawData() {
        network.uploadStreamRawData()
            .sink { completion in
                
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)
    }
    
    func downloadImage() {
        network.downloadData(url: "download/1752128810223-708544664.jpg")
            .sink { completion in
                switch completion {
                case .finished: print("downloadImage finish")
                case .failure(let error): print("downloadImage \(error.localizedDescription)")
                }
                
            } receiveValue: { url in
                print("downloadImage url \(url)")
            }
            .store(in: &cancellables)

    }
    
    func downloadData() {
        network.downloadData(url: "download/backup.data")
            .sink { completion in
                switch completion {
                case .finished: print("downloadData finish")
                case .failure(let error): print("downloadData \(error.localizedDescription)")
                }
                
            } receiveValue: { url in
                print("downloadData url \(url)")
            }
            .store(in: &cancellables)
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel(service: NullProfileService()))
}
