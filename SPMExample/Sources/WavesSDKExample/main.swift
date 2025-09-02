import Foundation
import WavesSDKCrypto

// Example: Generate a new seed phrase and derive keys
print("🌊 WavesSDK-iOS SPM Example")
print(String(repeating: "=", count: 40))

let crypto = WavesCrypto.shared

// Generate random seed
let seed = crypto.randomSeed()
print("📱 Generated seed phrase:")
print(seed)
print("")

// Generate key pair
if let keyPair = crypto.keyPair(seed: seed) {
    print("🔐 Public Key:")
    print(keyPair.publicKey)
    print("")
    print("🗝️ Private Key:")
    print(keyPair.privateKey)
    print("")
}

// Generate address
if let address = crypto.address(seed: seed, chainId: UInt8(87)) { // W = 87 for mainnet
    print("📍 Waves Address (Mainnet):")
    print(address)
    print("")
}

// Test crypto functions
let testData = "Hello Waves!".data(using: .utf8)!
let testBytes = Array(testData)

// Blake2b hash
let blake2Hash = crypto.blake2b256(input: testBytes)
let blake2Base64 = crypto.base64encode(input: blake2Hash)
print("🔐 Blake2b-256 hash:")
print(blake2Base64)
print("")

// SHA-256 hash
let sha256Hash = crypto.sha256(input: testBytes)
let sha256Base64 = crypto.base64encode(input: sha256Hash)
print("🔐 SHA-256 hash:")
print(sha256Base64)
print("")

print("✅ WavesSDK-iOS SPM integration working successfully!")