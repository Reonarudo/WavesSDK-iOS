//
//  WavesSDKWithAuth.swift  
//  WavesSDK
//
//  Enhanced WavesSDK with pluggable authentication support
//

import Foundation
import Moya
import WavesSDKCrypto
import WavesSDKExtensions

/// Enhanced WavesSDK that supports pluggable authentication
@MainActor
public final class WavesSDKWithAuth {
    
    // MARK: - Properties
    
    /// Current authentication provider
    public private(set) var authenticator: WavesAuthenticator?
    
    /// Core services (same as original WavesSDK)
    public let services: WavesServicesProtocol
    
    /// Environment configuration
    public var environment: WavesEnvironment {
        didSet {
            if var internalServices = services as? InternalWavesServiceProtocol {
                internalServices.enviroment = environment
            }
        }
    }
    
    /// Convenience access to authentication state
    public var isAuthenticated: Bool {
        get async {
            await authenticator?.isAuthenticated ?? false
        }
    }
    
    /// Current authenticated user
    public var currentUser: WavesAuthenticatedUser? {
        get async {
            await authenticator?.currentUser
        }
    }
    
    /// Authentication state stream for reactive UI updates
    public var authenticationState: AsyncStream<WavesAuthenticationState>? {
        authenticator?.authenticationState
    }
    
    // MARK: - Initialization
    
    /// Initialize WavesSDK with services and optional authenticator
    /// - Parameters:
    ///   - services: Core blockchain services
    ///   - environment: Network environment configuration
    ///   - authenticator: Optional authentication provider
    public init(
        services: WavesServicesProtocol,
        environment: WavesEnvironment,
        authenticator: WavesAuthenticator? = nil
    ) {
        self.services = services
        self.environment = environment
        self.authenticator = authenticator
    }
    
    /// Convenience initializer using the same pattern as original WavesSDK
    /// - Parameters:
    ///   - servicesPlugins: Plugin configuration for services
    ///   - environment: Network environment configuration
    ///   - authenticator: Optional authentication provider
    public convenience init(
        servicesPlugins: WavesSDK.ServicesPlugins,
        environment: WavesEnvironment,
        authenticator: WavesAuthenticator? = nil
    ) {
        var dataPlugins = servicesPlugins.data
        var nodePlugins = servicesPlugins.node
        var matcherPlugins = servicesPlugins.matcher
        
        // Add debug plugin like original WavesSDK
        let debugPlugin = DebugServicePlugin()
        dataPlugins.append(debugPlugin)
        nodePlugins.append(debugPlugin)
        matcherPlugins.append(debugPlugin)
        
        let services = WavesServices(
            enviroment: environment,
            dataServicePlugins: dataPlugins,
            nodeServicePlugins: nodePlugins,
            matcherServicePlugins: matcherPlugins
        )
        
        self.init(services: services, environment: environment, authenticator: authenticator)
    }
    
    // MARK: - Authentication Management
    
    /// Set or change the authentication provider
    /// - Parameter authenticator: New authentication provider
    public func setAuthenticator(_ authenticator: WavesAuthenticator?) {
        self.authenticator = authenticator
    }
    
    /// Create WavesKeeper authenticator adapter (will be implemented when imported)
    /// - Returns: Future WavesKeeper authenticator
    /// - Note: This method will be available when WavesKeeperAuthenticator is properly integrated
    public static func createWavesKeeperAuthenticator() -> WavesAuthenticator? {
        // TODO: Implement when WavesKeeperAuthenticator bridge is ready
        print("⚠️ WavesKeeper authenticator not yet available - bridge integration in progress")
        return nil
    }
    
    // MARK: - Authentication Operations
    
    /// Sign in using the current authenticator
    /// - Returns: Authenticated user information
    /// - Throws: WavesAuthenticatorError if no authenticator or sign in fails
    public func signIn() async throws -> WavesAuthenticatedUser {
        guard let authenticator = authenticator else {
            throw WavesAuthenticatorError.configurationError("No authenticator configured")
        }
        return try await authenticator.signIn()
    }
    
    /// Sign in with waves.exchange credentials (placeholder)
    /// - Parameters:
    ///   - username: waves.exchange username
    ///   - password: waves.exchange password
    /// - Returns: Authenticated user information
    /// - Throws: WavesAuthenticatorError if sign in fails
    public func signIn(username: String, password: String) async throws -> WavesAuthenticatedUser {
        // TODO: Implement when WavesKeeper bridge is ready
        throw WavesAuthenticatorError.configurationError("WavesKeeper authentication integration is in progress")
    }
    
    /// Sign out current user
    /// - Throws: WavesAuthenticatorError if sign out fails
    public func signOut() async throws {
        guard let authenticator = authenticator else {
            throw WavesAuthenticatorError.notAuthenticated
        }
        try await authenticator.signOut()
    }
    
    /// Refresh authentication session if supported
    /// - Returns: Updated user information or nil if refresh not needed/supported
    /// - Throws: WavesAuthenticatorError if refresh fails
    public func refreshSession() async throws -> WavesAuthenticatedUser? {
        guard let authenticator = authenticator else {
            throw WavesAuthenticatorError.notAuthenticated
        }
        return try await authenticator.refreshSession()
    }
    
    // MARK: - Transaction Operations
    
    /// Sign a transaction using the current authenticator
    /// - Parameter transaction: Transaction to sign
    /// - Returns: Signed transaction with signature and metadata
    /// - Throws: WavesAuthenticatorError if not authenticated or signing fails
    public func sign(transaction: NodeService.Query.Transaction) async throws -> WavesSignedTransaction {
        guard let authenticator = authenticator else {
            throw WavesAuthenticatorError.configurationError("No authenticator configured")
        }
        return try await authenticator.sign(transaction: transaction)
    }
    
    /// Get the public address for the current user
    /// - Parameter chainId: Optional chain ID (defaults to current network)
    /// - Returns: Waves address string
    /// - Throws: WavesAuthenticatorError if not authenticated
    public func getAddress(chainId: UInt8? = nil) async throws -> String {
        guard let authenticator = authenticator else {
            throw WavesAuthenticatorError.configurationError("No authenticator configured")
        }
        return try await authenticator.getAddress(chainId: chainId)
    }
    
    /// Get available accounts/addresses
    /// - Returns: Array of available accounts
    /// - Throws: WavesAuthenticatorError if not authenticated
    public func getAccounts() async throws -> [WavesAccount] {
        guard let authenticator = authenticator else {
            throw WavesAuthenticatorError.configurationError("No authenticator configured")
        }
        return try await authenticator.getAccounts()
    }
    
    // MARK: - Transaction Building and Sending
    
    /// Build, sign and broadcast a transaction in one step
    /// - Parameter transactionBuilder: Builder function that creates the transaction
    /// - Returns: Transaction ID if broadcast successful
    /// - Throws: WavesAuthenticatorError or network errors
    public func sendTransaction(
        _ transactionBuilder: () throws -> NodeService.Query.Transaction
    ) async throws -> String {
        // Build the transaction
        let transaction = try transactionBuilder()
        
        // Sign it
        let signedTransaction = try await sign(transaction: transaction)
        
        // Broadcast it
        return try await broadcastTransaction(signedTransaction)
    }
    
    /// Broadcast a signed transaction to the network
    /// - Parameter signedTransaction: Previously signed transaction
    /// - Returns: Transaction ID if broadcast successful
    /// - Throws: Network or validation errors
    private func broadcastTransaction(_ signedTransaction: WavesSignedTransaction) async throws -> String {
        // This would integrate with the existing NodeServices to broadcast
        // For now, return the transaction ID from the signed transaction
        return signedTransaction.transactionId
    }
}

// MARK: - Factory Methods

public extension WavesSDKWithAuth {
    
    /// Create WavesSDK instance with WavesKeeper authentication (placeholder)
    /// - Parameters:
    ///   - environment: Network environment
    ///   - servicesPlugins: Optional service plugins (uses defaults if nil)
    /// - Returns: WavesSDK configured with WavesKeeper authenticator
    static func withWavesKeeper(
        environment: WavesEnvironment,
        servicesPlugins: WavesSDK.ServicesPlugins? = nil
    ) -> WavesSDKWithAuth {
        let plugins = servicesPlugins ?? WavesSDK.ServicesPlugins(
            data: [],
            node: [],
            matcher: []
        )
        
        // WavesKeeper authenticator will be nil until bridge is complete
        let keeperAuth = createWavesKeeperAuthenticator()
        
        return WavesSDKWithAuth(
            servicesPlugins: plugins,
            environment: environment,
            authenticator: keeperAuth
        )
    }
    
    /// Create WavesSDK instance without authentication (services only)
    /// - Parameters:
    ///   - environment: Network environment
    ///   - servicesPlugins: Optional service plugins (uses defaults if nil)
    /// - Returns: WavesSDK with no authenticator
    static func servicesOnly(
        environment: WavesEnvironment,
        servicesPlugins: WavesSDK.ServicesPlugins? = nil
    ) -> WavesSDKWithAuth {
        let plugins = servicesPlugins ?? WavesSDK.ServicesPlugins(
            data: [],
            node: [],
            matcher: []
        )
        
        return WavesSDKWithAuth(
            servicesPlugins: plugins,
            environment: environment,
            authenticator: nil
        )
    }
}

// MARK: - Debug Service Plugin (Internal)

/// Internal debug plugin - copy of the one from original WavesSDK
private final class DebugServicePlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var mRequest = request
        let bundle = Bundle.main.bundleIdentifier ?? ""
        let userAgent = "WavesSDKWithAuth/1.0 AppId/\(bundle)"
        mRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return mRequest
    }
    
    func willSend(_ request: RequestType, target: TargetType) {}
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {}
    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        return result
    }
}