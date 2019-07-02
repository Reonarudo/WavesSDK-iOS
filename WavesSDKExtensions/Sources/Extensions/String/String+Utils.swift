//
//  StringExtension.swift
//  WavesWallet-iOS
//
//  Created by Alexey Koloskov on 03/05/2017.
//  Copyright © 2017 Waves Platform. All rights reserved.
//

import Foundation

public extension String {
    
    func trimmingLeadingWhitespace() -> String {
        let range = (self as NSString).range(of: "^\\s*", options: [.regularExpression])
        return (self as NSString).replacingCharacters(in: range, with: "")
    }
    
    func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }

    func removeCharacters(from: String) -> String {
        return removeCharacters(from: CharacterSet(charactersIn: from))
    }
}

public extension String {
    
    func arrayWithSize() -> [UInt8] {
        return Array(utf8).arrayWithSize()
    }
    
    func arrayWithSize32() -> [UInt8] {
        return Array(utf8).arrayWithSize32()
    }
}

public extension Array where Element == UInt8 {

    func arrayWithSize() -> [UInt8] {
        let b: [UInt8] = self
        return toByteArray(Int16(Swift.min(Int(Int16.max), b.count))) + b
    } 
    
    func arrayWithSize32() -> [UInt8] {
        let b: [UInt8] = self
        return toByteArray(Int32(b.count)) + b
    }
}
