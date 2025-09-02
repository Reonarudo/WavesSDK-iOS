//
//  AddressScriptInfo.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 21/01/2019.
//  Copyright © 2019 Waves Platform. All rights reserved.
//

import Foundation

public extension NodeService.DTO {

    struct AddressScriptInfo: Decodable {
        public let address: String
        public let script: String?
        public let scriptText: String?
        public let version: Int64
        public let complexity: Int64
        public let verifierComplexity: Int64?
        public let callableComplexities: [String:Int64]?
        public let extraFee: Int64?
    }
}
