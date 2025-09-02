//
//  LocalWalletAuthenticator.swift
//  WavesSDK
//
//  Local wallet authenticator for direct private key management
//

import Foundation
import WavesSDKCrypto

/// LocalWalletAuthenticator provides authentication using directly managed private keys
/// This authenticator is suitable for apps that manage their own wallet infrastructure
@MainActor
public final class LocalWalletAuthenticator: BaseWavesAuthenticator {
    
    // MARK: - Private Properties
    
    /// The private key for signing (kept in memory during authenticated session)
    private var privateKey: String?
    
    /// The seed phrase for key derivation (optional, for seed-based wallets)  
    private var seedPhrase: String?
    
    /// User information
    private var authenticatedUser: WavesAuthenticatedUser?
    
    // MARK: - Initialization
    
    /// Initialize with default mainnet chain ID
    public override init(chainId: UInt8 = 87) {
        super.init(chainId: chainId)
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in using a private key directly
    /// - Parameter privateKey: Base58-encoded private key
    /// - Returns: Authenticated user information
    /// - Throws: WavesAuthenticatorError if key is invalid
    /// - Note: Currently not supported by WavesCrypto - use seed phrase instead
    public func signIn(privateKey: String) async throws -> WavesAuthenticatedUser {
        // WavesCrypto doesn't directly support private key to public key conversion
        // This would need to be implemented in a future version
        throw WavesAuthenticatorError.unsupportedOperation("Private key authentication not supported by WavesCrypto. Use seed phrase instead.")
    }
    
    /// Sign in using a seed phrase
    /// - Parameters:
    ///   - seedPhrase: BIP39 seed phrase (12/15/18/21/24 words)
    /// - Returns: Authenticated user information
    /// - Throws: WavesAuthenticatorError if seed is invalid
    /// - Note: Account index parameter removed as WavesCrypto doesn't support it
    public func signIn(seedPhrase: String) async throws -> WavesAuthenticatedUser {
        setAuthenticating()
        
        do {
            // Validate seed phrase format (basic validation)
            let words = seedPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            guard [12, 15, 18, 21, 24].contains(words.count) else {
                throw WavesAuthenticatorError.invalidCredentials
            }
            
            // Generate key pair from seed
            guard let keyPair = crypto.keyPair(seed: seedPhrase) else {
                throw WavesAuthenticatorError.authenticationFailed(reason: "Failed to derive key pair from seed phrase")
            }
            
            // Generate address
            guard let address = crypto.address(seed: seedPhrase, chainId: chainId) else {
                throw WavesAuthenticatorError.signingFailed(reason: "Failed to generate address from seed phrase")
            }
            
            // Create user object
            let user = WavesAuthenticatedUser(
                id: address,
                address: address,
                publicKey: keyPair.publicKey,
                displayName: "Seed Wallet (\(String(address.prefix(8)))...)",
                authenticationMethod: "local_wallet",
                metadata: [
                    "chainId": String(chainId),
                    "keyType": "seed_phrase"
                ]
            )
            
            // Store authentication data
            self.privateKey = keyPair.privateKey
            self.seedPhrase = seedPhrase
            self.authenticatedUser = user
            
            // Update state
            setAuthenticated(user: user)
            
            return user
            
        } catch let error as WavesAuthenticatorError {
            setFailed(error: error)
            throw error
        } catch {
            let authError = WavesAuthenticatorError.authenticationFailed(reason: error.localizedDescription)
            setFailed(error: authError)
            throw authError
        }
    }
    
    /// Sign in with an existing WavesSDKCrypto KeyPair
    /// - Parameter keyPair: Pre-generated key pair
    /// - Returns: Authenticated user information
    /// - Throws: WavesAuthenticatorError if key pair is invalid
    public func signIn(keyPair: WavesSDKCrypto.KeyPair) async throws -> WavesAuthenticatedUser {
        setAuthenticating()
        
        do {
            // Generate address from public key
            guard let address = generateAddress(publicKey: keyPair.publicKey, chainId: chainId) else {
                throw WavesAuthenticatorError.signingFailed(reason: "Failed to generate address from key pair")
            }
            
            // Create user object
            let user = WavesAuthenticatedUser(
                id: address,
                address: address,
                publicKey: keyPair.publicKey,
                displayName: "KeyPair Wallet (\(String(address.prefix(8)))...)",
                authenticationMethod: "local_wallet",
                metadata: [
                    "chainId": String(chainId),
                    "keyType": "key_pair"
                ]
            )
            
            // Store authentication data
            self.privateKey = keyPair.privateKey
            self.authenticatedUser = user
            
            // Update state
            setAuthenticated(user: user)
            
            return user
            
        } catch let error as WavesAuthenticatorError {
            setFailed(error: error)
            throw error
        } catch {
            let authError = WavesAuthenticatorError.authenticationFailed(reason: error.localizedDescription)
            setFailed(error: authError)
            throw authError
        }
    }
    
    // MARK: - Required Protocol Implementations
    
    /// Required signIn() method for base protocol - throws configuration error
    /// Use one of the specific signIn methods instead
    public override func signIn() async throws -> WavesAuthenticatedUser {
        throw WavesAuthenticatorError.configurationError("LocalWalletAuthenticator requires explicit credentials. Use signIn(privateKey:), signIn(seedPhrase:), or signIn(keyPair:)")
    }
    
    /// Sign out and clear stored keys from memory
    public override func signOut() async throws {
        setSigningOut()
        
        // Clear sensitive data from memory
        privateKey = nil
        seedPhrase = nil
        authenticatedUser = nil
        
        // Update state
        setIdle()
    }
    
    /// Get private key for signing operations
    internal override func getPrivateKeyForSigning() async throws -> String {
        guard let privateKey = privateKey else {
            throw WavesAuthenticatorError.notAuthenticated
        }
        return privateKey
    }
    
    // MARK: - Advanced Features
    
    /// Generate a new random seed phrase
    /// - Returns: 12-word BIP39 seed phrase
    public static func generateSeedPhrase() -> String {
        return WavesCrypto.shared.randomSeed()
    }
    
    /// Generate a new random key pair
    /// - Returns: New key pair for Waves
    public static func generateKeyPair() -> WavesSDKCrypto.KeyPair? {
        let seed = generateSeedPhrase()
        return WavesCrypto.shared.keyPair(seed: seed)
    }
    
    /// Derive multiple accounts from a seed phrase
    /// - Parameters:
    ///   - seedPhrase: Master seed phrase
    ///   - accountCount: Number of accounts to derive
    ///   - chainId: Chain ID for address generation
    /// - Returns: Array of account information
    public static func deriveAccounts(
        from seedPhrase: String,
        accountCount: Int,
        chainId: UInt8 = 87
    ) -> [WavesAccount] {
        let crypto = WavesCrypto.shared
        var accounts: [WavesAccount] = []
        
        // Note: WavesCrypto doesn't support account derivation with nonce
        // For now, we'll just return the single account from the seed
        if let keyPair = crypto.keyPair(seed: seedPhrase),
           let address = crypto.address(seed: seedPhrase, chainId: chainId) {
            
            let account = WavesAccount(
                id: address,
                address: address,
                publicKey: keyPair.publicKey,
                name: "Primary Account",
                isPrimary: true
            )
            accounts.append(account)
        }
        
        return accounts
    }
    
    /// Validate a seed phrase format
    /// - Parameter seedPhrase: Seed phrase to validate
    /// - Returns: True if format appears valid
    public static func isValidSeedPhrase(_ seedPhrase: String) -> Bool {
        let words = seedPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        return [12, 15, 18, 21, 24].contains(words.count)
    }
    
    /// Check if currently using seed-based authentication
    public var isUsingSeedPhrase: Bool {
        return seedPhrase != nil
    }
    
    /// Get the current account index (for seed-based wallets)
    /// - Note: Currently returns 0 as WavesCrypto doesn't support multiple account derivation
    public var currentAccountIndex: Int? {
        guard isUsingSeedPhrase else {
            return nil
        }
        return 0 // Single account derivation for now
    }
}

// MARK: - Convenience Extensions

public extension LocalWalletAuthenticator {
    
    /// Create and authenticate with a new random wallet
    /// - Parameter chainId: Chain ID (default: 87 for mainnet)
    /// - Returns: Configured and authenticated LocalWalletAuthenticator
    static func createRandomWallet(chainId: UInt8 = 87) async throws -> LocalWalletAuthenticator {
        let authenticator = LocalWalletAuthenticator(chainId: chainId)
        let seedPhrase = generateSeedPhrase()
        _ = try await authenticator.signIn(seedPhrase: seedPhrase)
        return authenticator
    }
    
    /// Create authenticator from existing private key
    /// - Parameters:
    ///   - privateKey: Base58-encoded private key
    ///   - chainId: Chain ID (default: 87 for mainnet)
    /// - Returns: Configured and authenticated LocalWalletAuthenticator
    static func fromPrivateKey(_ privateKey: String, chainId: UInt8 = 87) async throws -> LocalWalletAuthenticator {
        let authenticator = LocalWalletAuthenticator(chainId: chainId)
        _ = try await authenticator.signIn(privateKey: privateKey)
        return authenticator
    }
    
    /// Create authenticator from seed phrase
    /// - Parameters:
    ///   - seedPhrase: BIP39 seed phrase
    ///   - chainId: Chain ID (default: 87 for mainnet)
    /// - Returns: Configured and authenticated LocalWalletAuthenticator
    static func fromSeedPhrase(
        _ seedPhrase: String,
        chainId: UInt8 = 87
    ) async throws -> LocalWalletAuthenticator {
        let authenticator = LocalWalletAuthenticator(chainId: chainId)
        _ = try await authenticator.signIn(seedPhrase: seedPhrase)
        return authenticator
    }
}