//
//  PinnedSessionDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 18/6/25.
//

import Foundation
import CryptoKit
import CommonCrypto

import TrustKit

class TrustKitPinnedSessionDelegate: NSObject, URLSessionDelegate {
    
    override init() {
        super.init()
        let trustKitConfig: [String: Any] = [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "api.openweathermap.org": [ // Must match the URL you connect to
                    kTSKIncludeSubdomains: false,
                    kTSKPublicKeyHashes: [
                        "UByNN6wh6WJFNj04mBWbj+iAfJP3C60LXpHBZXmMXwk=",
                        "BByNN6wh6WJFNj04mBWbj+iAfJP3C60LXpHBZXmMXww="
                    ],
                    // Allowing invalid certs if needed for testing (not for production)
//                    kTSKDisableDefaultReportUri: true,
                ]
            ]
        ]
        
        TrustKit.initSharedInstance(withConfiguration:trustKitConfig)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if TrustKit.sharedInstance().pinningValidator.handle(challenge, completionHandler: completionHandler) == false {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedKeyHashBase64 = "WHa2dTgIa0REVgQ+xPY6BMoZvJLHWWjVuzT9x9JEkQM="
    
    let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    
    private func sha256(data : Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

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
            print("Key type:", keyAttributes[kSecAttrKeyType as String] ?? "Unknown")
            print("Key size:", keyAttributes[kSecAttrKeySizeInBits as String] ?? "Unknown")
        }
        
        let keyHashBase64 = sha256(data:serverPublicKeyData)
        print("Public Key Hash (Base64):", keyHashBase64)

        // Compare against your pinned hash
        if keyHashBase64 == pinnedKeyHashBase64 {
            let credential = URLCredential(trust: serverTrust)
            debugPrint("useCredential ✅")
            completionHandler(.useCredential, credential)
        } else {
            debugPrint("cancelAuthenticationChallenge ❌")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
