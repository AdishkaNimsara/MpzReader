//import Foundation
//import RNCryptor
//
//
//public class AESDecryptionWrapper {
//    
//    public init() {}
//    
//    /// Decrypts the given data using AES.
//    /// This is a placeholder. You must implement the actual AES decryption logic here.
//    /// - Parameter data: The encrypted data.
//    /// - Returns: The decrypted data, or the original data if decryption fails/is not implemented.
//    public func decrypt(data: Data) -> Data {
//        // TODO: Implement AES decryption (e.g., using CryptoKit or CommonCrypto)
//        // Ensure you have the correct key and IV.
//        // For now, checks for basic validity or just returns data.
//        
//        print("AESDecryptionWrapper: Decrypting \(data.count) bytes...")
//        
//        // Example logic placeholder:
//        // let key = ...
//        // let iv = ...
//        // return AES.decrypt(data, key: key, iv: iv)
//        
//        return data
//    }
//}
//
//
//



import Foundation

public class AESDecryptionWrapper {
    
    public init() {}
    
    /// Decrypts the given data using AES.
    /// This is a placeholder. You must implement the actual AES decryption logic here.
    /// - Parameter data: The encrypted data.
    /// - Returns: The decrypted data, or the original data if decryption fails/is not implemented.
    public func decrypt(data: Data) -> Data {
        // 1. Convert Data -> String (Base64 implied by legacy logic, but usually it's just raw bytes of the file?)
        // The legacy logic in DownloadAlert says: `Cryptor.toText(base64Cypher: cypher, key: key)`
        // `toText` takes a base64 string.
        // So the input `data` here is the file content of an xhtml inside the epub.
        // If it was encrypted with RNCryptor/AES, it's binary data.
        
        // However, the legacy `onHtmlTransform` signature was `(String) -> String`.
        // The current `MpzConfig` has `onHtmlTransform : ((_ raw : String) -> String)?`
        
        // This implies the encrypted content is EXPECTED to be read as a String first?
        // Or we should convert the Data to a String (likely Base64) to pass it to the legacy handler?
         
        // Looking at the old code commented out in `DownloadAlert+Download.swift`:
        // config.onHtmlTransform = { cypher -> String in ... Cryptor.toText(base64Cypher: cypher ... }
        // So the input was expected to be a "cypher" string (likely Base64 encoded).
        
        // The `AESResource` reads the file data.
        // So we should encode `data` to Base64 String -> pass to `onHtmlTransform` -> get decrypted String -> convert to Data (utf8).
        
        guard let transform = MpzReader.configs.onHtmlTransform else {
            print("AESDecryptionWrapper: No onHtmlTransform configured. Returning original data.")
            return data
        }
        
        // The file content of the encrypted html resource.
        // The logs indicate the file content starts with 65 ('A'), which suggests the file contains
        // the Base64 string itself, not the raw binary ciphertext.
        // Therefore, we should convert the raw bytes to a String, which gives us the Base64 ciphertext.
        
        guard let base64Cypher = String(data: data, encoding: .utf8) else {
            print("AESDecryptionWrapper: Failed to decode data as UTF-8 string")
            return data
        }
        
        // Pass the Base64 string from the file directly to the transformer.
        // The transformer (Cryptor) will then decode this Base64 string to get the raw RNCryptor payload.
        let decryptedString = transform(base64Cypher)
        
        // If decryption failed, it might return the error HTML or empty string.
        guard let decryptedData = decryptedString.data(using: .utf8) else {
             print("AESDecryptionWrapper: Failed to convert decrypted string to data.")
             return data
        }
        
        return decryptedData
    }
}
