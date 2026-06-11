//import Foundation
//import ReadiumShared
//
//
///// A Resource wrapper that decrypts content on-the-fly using AES.
//public class AESResource: Resource {
//    /// The wrapped resource (the original encrypted resource).
//    private let resource: Resource
//    private let decryptionWrapper: AESDecryptionWrapper
//    
//    /// Cached decrypted data to avoid re-decrypting multiple times.
//    private var decryptedData: ReadResult<Data>?
//    
//    public var sourceURL: AbsoluteURL? { resource.sourceURL }
//    
//    public init(resource: Resource, decryptionWrapper: AESDecryptionWrapper) {
//        self.resource = resource
//        self.decryptionWrapper = decryptionWrapper
//    }
//    
//    public func properties() async -> ReadResult<ResourceProperties> {
//        await resource.properties()
//    }
//    
//    public func estimatedLength() async -> ReadResult<UInt64?> {
//        // After decryption, length might change. If we have decrypted data, return that length.
//        if let cached = decryptedData {
//            switch cached {
//            case .success(let data):
//                return .success(UInt64(data.count))
//            case .failure(let error):
//                return .failure(error)
//            }
//        }
//        return await resource.estimatedLength()
//    }
//    
//    public func stream(range: Range<UInt64>?, consume: @escaping (Data) -> Void) async -> ReadResult<Void> {
//        // For simplicity, read all, decrypt, then stream.
//        let readResult = await read(range: nil)
//        switch readResult {
//        case .success(let data):
//            if let range = range {
//                let lower = min(Int(range.lowerBound), data.count)
//                let upper = min(Int(range.upperBound), data.count)
//                if lower < upper {
//                    consume(data.subdata(in: lower..<upper))
//                }
//            } else {
//                consume(data)
//            }
//            return .success(())
//        case .failure(let error):
//            return .failure(error)
//        }
//    }
//    
//    public func read(range: Range<UInt64>?) async -> ReadResult<Data> {
//        // If we already decrypted, use cached version
//        if let cached = decryptedData {
//            return sliceData(cached, range: range)
//        }
//        
//        // Read all data from the underlying resource
//        let result = await resource.read(range: nil)
//        switch result {
//        case .success(let encryptedData):
//            let decrypted = decryptionWrapper.decrypt(data: encryptedData)
//            let successResult: ReadResult<Data> = .success(decrypted)
//            self.decryptedData = successResult
//            return sliceData(successResult, range: range)
//            
//        case .failure(let error):
//            let failureResult: ReadResult<Data> = .failure(error)
//            self.decryptedData = failureResult
//            return failureResult
//        }
//    }
//    
//    private func sliceData(_ result: ReadResult<Data>, range: Range<UInt64>?) -> ReadResult<Data> {
//        guard let range = range else {
//            return result
//        }
//        
//        switch result {
//        case .success(let data):
//            let len = UInt64(data.count)
//            let lower = min(range.lowerBound, len)
//            let upper = min(range.upperBound, len)
//            
//            if lower >= upper {
//                return .success(Data())
//            }
//            
//            let subdata = data.subdata(in: Int(lower)..<Int(upper))
//            return .success(subdata)
//            
//        case .failure(let error):
//            return .failure(error)
//        }
//    }
//    
//    public func close() async {
//        await resource.close()
//        decryptedData = nil
//    }
//}


import Foundation
import ReadiumShared

/// A Resource wrapper that decrypts content on-the-fly using AES.
public class AESResource: Resource {
    /// The wrapped resource (the original encrypted resource).
    private let resource: Resource
    private let decryptionWrapper: AESDecryptionWrapper
    
    /// Cached decrypted data to avoid re-decrypting multiple times.
    private var decryptedData: ReadResult<Data>?
    
    public var sourceURL: AbsoluteURL? { resource.sourceURL }
    
    public init(resource: Resource, decryptionWrapper: AESDecryptionWrapper) {
        self.resource = resource
        self.decryptionWrapper = decryptionWrapper
    }
    
    public func properties() async -> ReadResult<ResourceProperties> {
        await resource.properties()
    }
    
    public func estimatedLength() async -> ReadResult<UInt64?> {
        // After decryption, length might change. If we have decrypted data, return that length.
        if let cached = decryptedData {
            switch cached {
            case .success(let data):
                return .success(UInt64(data.count))
            case .failure(let error):
                return .failure(error)
            }
        }
        return await resource.estimatedLength()
    }
    
    public func stream(range: Range<UInt64>?, consume: @escaping (Data) -> Void) async -> ReadResult<Void> {
        // For simplicity, read all, decrypt, then stream.
        let readResult = await read(range: nil)
        switch readResult {
        case .success(let data):
            if let range = range {
                let lower = min(Int(range.lowerBound), data.count)
                let upper = min(Int(range.upperBound), data.count)
                if lower < upper {
                    consume(data.subdata(in: lower..<upper))
                }
            } else {
                consume(data)
            }
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func read(range: Range<UInt64>?) async -> ReadResult<Data> {
        // If we already decrypted, use cached version
        if let cached = decryptedData {
            return sliceData(cached, range: range)
        }
        
        // Read all data from the underlying resource
        let result = await resource.read(range: nil)
        switch result {
        case .success(let encryptedData):
            do {
                let decrypted = try decryptionWrapper.decrypt(data: encryptedData)
                let successResult: ReadResult<Data> = .success(decrypted)
                self.decryptedData = successResult
                return sliceData(successResult, range: range)
            } catch {
                let failureResult: ReadResult<Data> = .failure(.decoding(error))
                self.decryptedData = failureResult
                return failureResult
            }
            
        case .failure(let error):
            let failureResult: ReadResult<Data> = .failure(error)
            self.decryptedData = failureResult
            return failureResult
        }
    }
    
    private func sliceData(_ result: ReadResult<Data>, range: Range<UInt64>?) -> ReadResult<Data> {
        guard let range = range else {
            return result
        }
        
        switch result {
        case .success(let data):
            let len = UInt64(data.count)
            let lower = min(range.lowerBound, len)
            let upper = min(range.upperBound, len)
            
            if lower >= upper {
                return .success(Data())
            }
            
            let subdata = data.subdata(in: Int(lower)..<Int(upper))
            return .success(subdata)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func close() async {
        await resource.close()
        decryptedData = nil
    }
}
