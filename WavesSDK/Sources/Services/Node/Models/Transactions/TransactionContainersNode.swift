//
//  TransactionContainers.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 29.08.2018.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import Foundation
import WavesSDKExtensions

extension NodeService.DTO {

    fileprivate enum TransactionType: Int, Decodable {
        case issue = 3
        case transfer = 4
        case reissue = 5
        case burn = 6
        case exchange = 7
        case lease = 8
        case leaseCancel = 9
        case alias = 10
        case massTransfer = 11
        case data = 12
        case script = 13
        case sponsorship = 14
        case assetScript = 15
        case invokeScript = 16
    }

    public enum TransactionError: Error {
        case none
    }

    public enum Transaction: Decodable {
        case unrecognised(NodeService.DTO.UnrecognisedTransaction)
        case issue(NodeService.DTO.IssueTransaction)
        case transfer(NodeService.DTO.TransferTransaction)
        case reissue(NodeService.DTO.ReissueTransaction)
        case burn(NodeService.DTO.BurnTransaction)
        case exchange(NodeService.DTO.ExchangeTransaction)
        case lease(NodeService.DTO.LeaseTransaction)
        case leaseCancel(NodeService.DTO.LeaseCancelTransaction)
        case alias(NodeService.DTO.AliasTransaction)
        case massTransfer(NodeService.DTO.MassTransferTransaction)
        case data(NodeService.DTO.DataTransaction)
        case script(NodeService.DTO.ScriptTransaction)
        case sponsorship(NodeService.DTO.SponsorshipTransaction)
        case assetScript(NodeService.DTO.AssetScriptTransaction)
        case invokeScript(NodeService.DTO.InvokeScriptTransaction)

        public init(from decoder: Decoder) throws {

            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(TransactionType.self, forKey: .type)

                self = try Transaction.transaction(from: decoder, type: type)
            } catch let e {
                SweetLogger.error(e)
                throw TransactionError.none
            }
        }


        fileprivate static func transaction(from decode: Decoder, type: TransactionType) throws -> Transaction {

            switch type {
            case .issue:
                return .issue( try NodeService.DTO.IssueTransaction(from: decode))

            case .transfer:
                return .transfer( try NodeService.DTO.TransferTransaction(from: decode))

            case .reissue:
                return .reissue( try NodeService.DTO.ReissueTransaction(from: decode))

            case .burn:
                return .burn( try NodeService.DTO.BurnTransaction(from: decode))

            case .exchange:
                return .exchange( try NodeService.DTO.ExchangeTransaction(from: decode))

            case .lease:
                return .lease( try NodeService.DTO.LeaseTransaction(from: decode))

            case .leaseCancel:
                return .leaseCancel( try NodeService.DTO.LeaseCancelTransaction(from: decode))

            case .alias:
                return .alias( try NodeService.DTO.AliasTransaction(from: decode))

            case .massTransfer:
                return .massTransfer( try NodeService.DTO.MassTransferTransaction(from: decode))

            case .data:
                return .data(try NodeService.DTO.DataTransaction(from: decode))

            case .script:
                return .script(try NodeService.DTO.ScriptTransaction(from: decode))

            case .assetScript:
                return .assetScript(try NodeService.DTO.AssetScriptTransaction(from: decode))

            case .sponsorship:
                return .sponsorship(try NodeService.DTO.SponsorshipTransaction(from: decode))
                
            case .invokeScript:
                return .invokeScript(try NodeService.DTO.InvokeScriptTransaction(from: decode))
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case type = "type"
    }

    public struct TransactionContainers: Decodable {
        
        public let transactions: [Transaction]
        
        public init(from decoder: Decoder) throws {

            var transactions: [Transaction] = []

            do {

                var container = try decoder.unkeyedContainer()
                var listForType = try container.nestedUnkeyedContainer()

                var listArray = listForType
                while !listForType.isAtEnd {

                    let objectType = try listForType.nestedContainer(keyedBy: CodingKeys.self)

                    do {
                        let type = try objectType.decode(TransactionType.self, forKey: .type)

                        switch type {
                        case .issue:
                            let tx = try listArray.decode(NodeService.DTO.IssueTransaction.self)
                            transactions.append(.issue(tx))

                        case .transfer:
                            let tx = try listArray.decode(NodeService.DTO.TransferTransaction.self)
                            transactions.append(.transfer(tx))

                        case .reissue:
                            let tx = try listArray.decode(NodeService.DTO.ReissueTransaction.self)
                            transactions.append(.reissue(tx))

                        case .burn:
                            let tx = try listArray.decode(NodeService.DTO.BurnTransaction.self)
                            transactions.append(.burn(tx))

                        case .exchange:
                            let tx = try listArray.decode(NodeService.DTO.ExchangeTransaction.self)
                            transactions.append(.exchange(tx))

                        case .lease:
                            let tx = try listArray.decode(NodeService.DTO.LeaseTransaction.self)
                            transactions.append(.lease(tx))

                        case .leaseCancel:
                            let tx = try listArray.decode(NodeService.DTO.LeaseCancelTransaction.self)
                            transactions.append(.leaseCancel(tx))

                        case .alias:
                            let tx = try listArray.decode(NodeService.DTO.AliasTransaction.self)
                            transactions.append(.alias(tx))

                        case .massTransfer:
                            let tx = try listArray.decode(NodeService.DTO.MassTransferTransaction.self)
                            transactions.append(.massTransfer(tx))

                        case .data:
                            let tx = try listArray.decode(NodeService.DTO.DataTransaction.self)
                            transactions.append(.data(tx))

                        case .script:
                            let tx = try listArray.decode(NodeService.DTO.ScriptTransaction.self)
                            transactions.append(.script(tx))

                        case .assetScript:
                            let tx = try listArray.decode(NodeService.DTO.AssetScriptTransaction.self)
                            transactions.append(.assetScript(tx))

                        case .sponsorship:
                            let tx = try listArray.decode(NodeService.DTO.SponsorshipTransaction.self)
                            transactions.append(.sponsorship(tx))
                            
                        case .invokeScript:
                            let tx = try listArray.decode(NodeService.DTO.InvokeScriptTransaction.self)
                            transactions.append(.invokeScript(tx))
                        }
                    } catch let e {

                        if let tx = try? listArray.decode(NodeService.DTO.UnrecognisedTransaction.self) {
                            transactions.append(.unrecognised(tx))
                            SweetLogger.error("Unrecognised \(e)")
                        } else {
                            SweetLogger.error("Not Found type \(e)")
                        }
                    }
                }

            } catch let e {
                SweetLogger.error("WTF \(e)")
            }

            self.transactions = transactions
        }
    }
}
