//
//  BaseWavesAuthenticator.swift
//  WavesSDK
//
//  Base implementation for WavesAuthenticator with common functionality
//

import Foundation
import WavesSDKCrypto

/// Base class providing common functionality for WavesAuthenticator implementations
@MainActor
open class BaseWavesAuthenticator: WavesAuthenticator {
    
    /// State manager for authentication state
    public let stateManager = WavesAuthenticationStateManager()
    
    /// Crypto instance for signing operations
    protected let crypto: WavesCrypto
    
    /// Current chain ID
    protected var chainId: UInt8
    
    public init(chainId: UInt8 = 87) { // Default to mainnet (87 = 'W')
        self.crypto = WavesCrypto.shared
        self.chainId = chainId
    }
    
    // MARK: - WavesAuthenticator Protocol Implementation
    
    public var isAuthenticated: Bool {
        get async {
            await stateManager.isAuthenticated
        }
    }
    
    public var currentUser: WavesAuthenticatedUser? {
        get async {
            await stateManager.currentUser
        }
    }
    
    public var authenticationState: AsyncStream<WavesAuthenticationState> {
        stateManager.stateStream
    }
    
    // MARK: - Abstract Methods (Must be implemented by subclasses)
    
    /// Sign in - must be implemented by subclasses
    open func signIn() async throws -> WavesAuthenticatedUser {
        fatalError("signIn() must be implemented by subclasses")
    }
    
    /// Sign out - must be implemented by subclasses  
    open func signOut() async throws {
        fatalError("signOut() must be implemented by subclasses")
    }
    
    // MARK: - Common Implementation
    
    /// Sign a transaction using the crypto library
    public func sign(transaction: NodeService.Query.Transaction) async throws -> WavesSignedTransaction {
        guard await isAuthenticated, let user = await currentUser else {
            throw WavesAuthenticatorError.notAuthenticated
        }
        
        // Get signing data from transaction
        let signingData = try await getTransactionSigningBytes(transaction)
        
        // Get private key for signing (must be implemented by subclasses)
        let privateKey = try await getPrivateKeyForSigning()
        
        // Sign the transaction
        guard let signatureBytes = crypto.signBytes(bytes: signingData, privateKey: privateKey) else {
            throw WavesAuthenticatorError.signingFailed(reason: "Failed to generate signature")
        }
        
        // Convert signature to Base58
        guard let signatureBase58 = crypto.base58encode(input: signatureBytes) else {
            throw WavesAuthenticatorError.signingFailed(reason: "Failed to encode signature")
        }
        
        // Calculate transaction ID
        let transactionId = try await calculateTransactionId(transaction, signature: signatureBase58)
        
        return WavesSignedTransaction(
            transaction: transaction,
            signature: signatureBase58,
            publicKey: user.publicKey,
            transactionId: transactionId
        )
    }
    
    /// Get address for authenticated user
    public func getAddress(chainId: UInt8?) async throws -> String {
        guard let user = await currentUser else {
            throw WavesAuthenticatorError.notAuthenticated
        }
        
        if let customChainId = chainId {
            // Generate address for specific chain ID
            guard let address = crypto.address(publicKey: user.publicKey, chainId: customChainId) else {
                throw WavesAuthenticatorError.signingFailed(reason: "Failed to generate address for chain ID \(customChainId)")
            }
            return address
        }
        
        return user.address
    }
    
    // MARK: - Abstract Helper Methods (Must be implemented by subclasses)
    
    /// Get private key for signing - must be implemented by subclasses
    protected func getPrivateKeyForSigning() async throws -> String {
        fatalError("getPrivateKeyForSigning() must be implemented by subclasses")
    }
    
    // MARK: - Helper Methods
    
    /// Generate Waves address from public key
    protected func generateAddress(publicKey: String, chainId: UInt8? = nil) -> String? {
        return crypto.address(publicKey: publicKey, chainId: chainId ?? self.chainId)
    }
    
    /// Validate Waves address
    protected func validateAddress(_ address: String, chainId: UInt8? = nil, publicKey: String? = nil) -> Bool {
        return crypto.verifyAddress(address: address, chainId: chainId ?? self.chainId, publicKey: publicKey)
    }
    
    /// Verify signature
    protected func verifySignature(publicKey: String, bytes: [UInt8], signature: [UInt8]) -> Bool {
        return crypto.verifySignature(publicKey: publicKey, bytes: bytes, signature: signature)
    }
    
    // MARK: - Private Helper Methods
    
    /// Get signing bytes for transaction
    private func getTransactionSigningBytes(_ transaction: NodeService.Query.Transaction) async throws -> [UInt8] {
        // This would need to be implemented based on how WavesSDK generates signing bytes
        // For now, we'll use a placeholder that would need to be connected to the actual signing logic
        throw WavesAuthenticatorError.unsupportedOperation("Transaction signing bytes generation not yet implemented")
    }
    
    /// Calculate transaction ID from signed transaction
    private func calculateTransactionId(_ transaction: NodeService.Query.Transaction, signature: String) async throws -> String {
        // This would calculate the transaction ID based on the signed transaction
        // For now, return a placeholder
        return "placeholder_tx_id_\(UUID().uuidString.prefix(8))"
    }
}

/// Extension to provide common state management helpers
extension BaseWavesAuthenticator {
    
    /// Helper to set authenticated state
    protected func setAuthenticated(user: WavesAuthenticatedUser) {
        stateManager.setAuthenticated(user: user)
    }
    
    /// Helper to set failed state
    protected func setFailed(error: WavesAuthenticatorError) {
        stateManager.setFailed(error: error)
    }
    
    /// Helper to set authenticating state
    protected func setAuthenticating() {
        stateManager.setAuthenticating()
    }
    
    /// Helper to set idle state
    protected func setIdle() {
        stateManager.setIdle()
    }
    
    /// Helper to set signing out state
    protected func setSigningOut() {
        stateManager.setSigningOut()
    }
}