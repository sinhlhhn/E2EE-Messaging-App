//
//  ECCPinnedSessionDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 20/6/25.
//

import Foundation
import CryptoKit

import Combine

final class ECCPinning: PinningDelegate {
    private let pinnedKeyHashBase64s = [
        "2IoUR8KJqun7XAiN6g8Jz3DIXfmY2d4+aPdWPRQAyk4=",
        "WpOCr2ySOjvGzA1wkEHhaAE+CgPa+mslzbO8Mz7LwK8="
    ]
    
    func handleChallenge(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCerts =  SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let leafServerCerts = serverCerts.first else {
            debugPrint("cancelAuthenticationChallenge ❌")
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }

        // Extract public key from certificate
        guard let serverPublicKey = SecCertificateCopyKey(leafServerCerts),
              let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            debugPrint("cancelAuthenticationChallenge ❌")
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }
        
        
        if let keyAttributes = SecKeyCopyAttributes(serverPublicKey) as? [String: Any] {
            debugPrint("Key type:", keyAttributes[kSecAttrKeyType as String]  ?? "Unknown")
            debugPrint("Key size:", keyAttributes[kSecAttrKeySizeInBits as String] ?? "Unknown")
        }
        
        guard let p256 = try? P256.Signing.PublicKey(x963Representation: serverPublicKeyData) else {
            debugPrint("cannot parse the public key ❌")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let keyHash = SHA256.hash(data: p256.derRepresentation)
        let keyHashBase64 = Data(keyHash).base64EncodedString()
        print("Public Key Hash (Base64):", keyHashBase64)

        // Compare against your pinned hash
        for pinnedKeyHashBase64 in pinnedKeyHashBase64s {
            if keyHashBase64 == pinnedKeyHashBase64 {
                let credential = URLCredential(trust: serverTrust)
                debugPrint("useCredential ✅")
                completionHandler(.useCredential, credential)
                return
            }
        }
        debugPrint("cancelAuthenticationChallenge ❌")
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
