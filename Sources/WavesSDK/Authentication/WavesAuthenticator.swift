//
//  WavesAuthenticator.swift
//  WavesSDK
//
//  Authentication strategy protocol for pluggable authentication in WavesSDK
//

import Foundation

/// Protocol defining authentication capabilities for WavesSDK
/// Enables pluggable authentication strategies (waves.exchange, local wallet, WalletConnect, etc.)
public protocol WavesAuthenticator: AnyObject {
    
    /// Current authentication state
    var isAuthenticated: Bool { get async }
    
    /// Currently authenticated user information
    var currentUser: WavesAuthenticatedUser? { get async }
    
    /// Authentication state changes publisher for reactive UI updates
    var authenticationState: AsyncStream<WavesAuthenticationState> { get }
    
    /// Sign in with authenticator-specific method
    /// - Returns: Authenticated user information
    /// - Throws: WavesAuthenticatorError on failure
    func signIn() async throws -> WavesAuthenticatedUser
    
    /// Sign out current user
    /// - Throws: WavesAuthenticatorError on failure
    func signOut() async throws
    
    /// Refresh authentication session if supported
    /// - Returns: Updated user information or nil if refresh not needed/supported
    /// - Throws: WavesAuthenticatorError on failure
    func refreshSession() async throws -> WavesAuthenticatedUser?
    
    /// Sign a Waves transaction with the authenticated user's credentials
    /// - Parameter transaction: Transaction to sign
    /// - Returns: Signed transaction with signature and public key
    /// - Throws: WavesAuthenticatorError if not authenticated or signing fails
    func sign(transaction: NodeService.Query.Transaction) async throws -> WavesSignedTransaction
    
    /// Get the public address for the authenticated user
    /// - Parameter chainId: Optional chain ID (defaults to current network)
    /// - Returns: Waves address string
    /// - Throws: WavesAuthenticatorError if not authenticated
    func getAddress(chainId: UInt8?) async throws -> String
    
    /// Get available accounts/addresses (for multi-account authenticators)
    /// - Returns: Array of available addresses
    /// - Throws: WavesAuthenticatorError if not authenticated
    func getAccounts() async throws -> [WavesAccount]
}

/// User information from any authentication method
public struct WavesAuthenticatedUser: Equatable, Codable {
    /// Unique user identifier (format depends on authenticator)
    public let id: String
    
    /// Primary Waves address for this user
    public let address: String
    
    /// Public key in Base58 format
    public let publicKey: String
    
    /// User display name (optional)
    public let displayName: String?
    
    /// Authentication method used
    public let authenticationMethod: String
    
    /// Additional metadata (authenticator-specific)
    public let metadata: [String: String]
    
    public init(
        id: String,
        address: String,
        publicKey: String,
        displayName: String? = nil,
        authenticationMethod: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.address = address
        self.publicKey = publicKey
        self.displayName = displayName
        self.authenticationMethod = authenticationMethod
        self.metadata = metadata
    }
}

/// Signed transaction result from any authenticator
public struct WavesSignedTransaction: Equatable {
    /// Original transaction that was signed
    public let transaction: NodeService.Query.Transaction
    
    /// Signature in Base58 format
    public let signature: String
    
    /// Public key that created the signature
    public let publicKey: String
    
    /// Transaction ID (calculated from signed transaction)
    public let transactionId: String
    
    public init(
        transaction: NodeService.Query.Transaction,
        signature: String,
        publicKey: String,
        transactionId: String
    ) {
        self.transaction = transaction
        self.signature = signature
        self.publicKey = publicKey
        self.transactionId = transactionId
    }
}

/// Account information for multi-account scenarios
public struct WavesAccount: Equatable, Codable, Identifiable {
    /// Unique account identifier
    public let id: String
    
    /// Waves address
    public let address: String
    
    /// Public key in Base58 format
    public let publicKey: String
    
    /// Account name/label
    public let name: String?
    
    /// Whether this is the primary account
    public let isPrimary: Bool
    
    public init(
        id: String,
        address: String,
        publicKey: String,
        name: String? = nil,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.address = address
        self.publicKey = publicKey
        self.name = name
        self.isPrimary = isPrimary
    }
}

/// Authentication states for reactive UI updates
public enum WavesAuthenticationState: Equatable {
    case idle
    case authenticating
    case authenticated(user: WavesAuthenticatedUser)
    case failed(error: WavesAuthenticatorError)
    case signingOut
}

/// Errors specific to authentication operations
public enum WavesAuthenticatorError: Error, LocalizedError {
    case notAuthenticated
    case authenticationFailed(reason: String)
    case signingFailed(reason: String)
    case sessionExpired
    case networkError(Error)
    case unsupportedOperation(String)
    case invalidCredentials
    case userCancelled
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .signingFailed(let reason):
            return "Transaction signing failed: \(reason)"
        case .sessionExpired:
            return "Authentication session has expired"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unsupportedOperation(let operation):
            return "Operation not supported: \(operation)"
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .userCancelled:
            return "Operation cancelled by user"
        case .configurationError(let details):
            return "Configuration error: \(details)"
        }
    }
}

/// Extension to provide default implementations for optional protocol methods
public extension WavesAuthenticator {
    
    /// Default implementation for authenticators that don't support session refresh
    func refreshSession() async throws -> WavesAuthenticatedUser? {
        return nil
    }
    
    /// Default implementation for single-account authenticators
    func getAccounts() async throws -> [WavesAccount] {
        guard let user = await currentUser else {
            throw WavesAuthenticatorError.notAuthenticated
        }
        
        return [WavesAccount(
            id: user.id,
            address: user.address,
            publicKey: user.publicKey,
            name: user.displayName,
            isPrimary: true
        )]
    }
}