//
//  WavesAuthenticationStateManager.swift
//  WavesSDK
//
//  Helper class for managing authentication state streams
//

import Foundation

/// Helper class to manage authentication state for authenticator implementations
@MainActor
public class WavesAuthenticationStateManager: ObservableObject {
    
    /// Published current authentication state for SwiftUI integration
    @Published public private(set) var currentState: WavesAuthenticationState = .idle
    
    /// AsyncStream for reactive state updates
    public var stateStream: AsyncStream<WavesAuthenticationState> {
        AsyncStream { continuation in
            let task = Task {
                for await state in stateUpdates {
                    continuation.yield(state)
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    /// Private stream continuation for state updates
    private let stateContinuation: AsyncStream<WavesAuthenticationState>.Continuation
    private let stateUpdates: AsyncStream<WavesAuthenticationState>
    
    public init() {
        (stateUpdates, stateContinuation) = AsyncStream<WavesAuthenticationState>.makeStream()
    }
    
    /// Update the current authentication state
    /// - Parameter newState: The new authentication state
    public func updateState(_ newState: WavesAuthenticationState) {
        currentState = newState
        stateContinuation.yield(newState)
    }
    
    /// Mark authentication as in progress
    public func setAuthenticating() {
        updateState(.authenticating)
    }
    
    /// Mark authentication as successful
    /// - Parameter user: The authenticated user
    public func setAuthenticated(user: WavesAuthenticatedUser) {
        updateState(.authenticated(user: user))
    }
    
    /// Mark authentication as failed
    /// - Parameter error: The authentication error
    public func setFailed(error: WavesAuthenticatorError) {
        updateState(.failed(error: error))
    }
    
    /// Mark sign out as in progress
    public func setSigningOut() {
        updateState(.signingOut)
    }
    
    /// Reset to idle state
    public func setIdle() {
        updateState(.idle)
    }
    
    /// Clean up resources
    deinit {
        stateContinuation.finish()
    }
}

/// Convenience extension for state checking
public extension WavesAuthenticationStateManager {
    
    /// Check if currently authenticated
    var isAuthenticated: Bool {
        if case .authenticated = currentState {
            return true
        }
        return false
    }
    
    /// Get current user if authenticated
    var currentUser: WavesAuthenticatedUser? {
        if case .authenticated(let user) = currentState {
            return user
        }
        return nil
    }
    
    /// Check if authentication is in progress
    var isAuthenticating: Bool {
        return currentState == .authenticating
    }
    
    /// Check if sign out is in progress
    var isSigningOut: Bool {
        return currentState == .signingOut
    }
}