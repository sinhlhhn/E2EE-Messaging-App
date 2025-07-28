//
//  Movie.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/7/25.
//

import CoreTransferable


struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { receivedData in
            let fileName = receivedData.file.lastPathComponent
            let copy: URL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            if !FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.copyItem(at: receivedData.file, to: copy)
            }
            
            return .init(url: copy)
        }
    }
}
