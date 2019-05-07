//
//  UtilsNode.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 3/12/19.
//  Copyright © 2019 Waves Platform. All rights reserved.
//

import Foundation

public extension Node.DTO {
    enum Utils {}
}

public extension Node.DTO.Utils {
    
    struct Time: Decodable {
        public let system: Int64
        public let NTP: Int64
    }
}
