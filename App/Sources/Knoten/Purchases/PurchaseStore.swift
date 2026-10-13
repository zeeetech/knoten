import StoreKit
import SwiftUI

enum ProductID {
    static let proLifetime = "knoten.pro.lifetime"
    static let tips = [
        "knoten.tip.espresso",
        "knoten.tip.cappuccino",
        "knoten.tip.coldbrew",
    ]
}

@MainActor
@Observable
final class PurchaseStore {
    private(set) var isPro = false

    func refresh() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == ProductID.proLifetime {
                entitled = true
            }
        }
        isPro = entitled
    }

    /// Keeps the entitlement honest across devices, refunds and family sharing.
    func watch() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await refresh()
            }
        }
    }
}
