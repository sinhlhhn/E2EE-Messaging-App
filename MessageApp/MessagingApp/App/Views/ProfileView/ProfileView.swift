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
    let image: Data
    let userName: String
    let fileName: String
    let fieldName: String
}

protocol ProfileUseCase {
    func uploadImage(image: ImageData) -> AnyPublisher<UploadResponse, Error>
    func uploadStreamRawData()
//    func downloadImage()
}

import Combine
class ProfileService: ProfileUseCase {
    private let network: NetworkModule
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(network: NetworkModule) {
        self.network = network
    }
    
    func uploadImage(image: ImageData) -> AnyPublisher<UploadResponse, Error> {
        let images: [MultipartImage] = [
            .init(data: image.image, fieldName: image.fieldName, fileName: image.fileName, mimeType: "jpg")
        ]
        return network.uploadImage(images: images, fields: [])
            .map { _ in
                UploadResponse.progress(percentage: 0)
            }
            .eraseToAnyPublisher()
        
    }
    
    func uploadStreamRawData() {
        network.uploadStreamRawData()
            .sink { completion in
                
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)
    }
    
//    func downloadImage() -> AnyPublisher<UploadResponse, Error> {
//        
//    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel(service: NullProfileService()))
}
