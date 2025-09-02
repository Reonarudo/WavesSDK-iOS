//
//  AddressScriptInfo.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 21/01/2019.
//  Copyright © 2019 Waves Platform. All rights reserved.
//

import Foundation

public extension NodeService.DTO {

    struct AddressScriptInfoMeta: Decodable {
        public let address: String
        public let meta: Meta
    }

    struct Meta: Decodable {
        public let version: String
        public let isArrayArguments: Bool
        public let callableFuncTypes: [String: [CallableFuncType]]
    }

    struct CallableFuncType: Decodable {
        public let name: String
        public let type: TypeEnum
    }

    enum TypeEnum: String, Codable {
        case boolean = "Boolean"
        case int = "Int"
        case string = "String"
    }
}
