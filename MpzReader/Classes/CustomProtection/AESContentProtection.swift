import Foundation
import ReadiumShared

/// Custom ContentProtection for AES-encrypted EPUB content.
/// This implementation intercepts XHTML resources and decrypts them on-the-fly.
public class AESContentProtection: ContentProtection {
    
    private let decryptionWrapper: AESDecryptionWrapper
    
    public init() {
        self.decryptionWrapper = AESDecryptionWrapper()
    }
    
    public func open(
        asset: Asset,
        credentials: String?,
        allowUserInteraction: Bool,
        sender: Any?
    ) async -> Result<ContentProtectionAsset, ContentProtectionOpenError> {
        
        print("AESContentProtection: Checking asset for AES protection...")
        
        // Check if the asset is a container (e.g., an EPUB archive)
        guard case let .container(containerAsset) = asset else {
            // Not a container, this protection doesn't apply
            return .failure(.assetNotSupported(nil))
        }
        
        print("AESContentProtection: Wrapping container with decryption transformer.")
        
        // Create a transformer that decrypts XHTML resources
        let decryptionWrapper = self.decryptionWrapper
        let transformer: ResourceTransformer = { href, resource in
            // Check if this resource should be decrypted
            // Use the string representation of the URL to check extension
            let hrefString = href.string
            if hrefString.hasSuffix(".xhtml") || hrefString.hasSuffix(".html") {
                print("AESContentProtection: Intercepting encrypted resource: \(href)")
                return AESResource(resource: resource, decryptionWrapper: decryptionWrapper)
            }
            return resource
        }
        
        // Wrap the container with our transformer
        let transformedContainer = TransformingContainer(
            container: containerAsset.container,
            transformer: transformer
        )
        
        // Return the ContentProtectionAsset with onCreatePublication to inject the transformed container
        return .success(ContentProtectionAsset(
            asset: asset,
            onCreatePublication: { manifest, container, services in
                // Replace the container with our decrypting one (mutate in place)
                container = transformedContainer
            }
        ))
    }
}
