import SwiftUI
import AgentAuthority
import AgentAuthorityUI

/// The app's compiled-in authority policy and broker limits.
///
/// This is the part a product team owns: which agent may hold which scope,
/// for how long, and how deep a delegation chain may go. The broker enforces
/// it — and enforces its own floor (consent for every sensitive scope, a hard
/// lifetime ceiling, a hard chain ceiling) even if this table is wrong.
enum DemoPolicy {
    static let ledger = StaticAuthorityPolicy(rules: [
        // Siri via App Intents: everything, sensitive scopes behind consent.
        .appIntent: .init(
            allowedScopes: Set(Ledger.allScopes),
            maxLifetime: 300, stepUpTier: .sensitive, maxChainLength: 2
        ),
        // The app's own on-device model: no data export, short-lived tokens.
        .onDeviceModel: .init(
            allowedScopes: [Ledger.readTransactions, Ledger.categorize, Ledger.initiatePayment],
            maxLifetime: 120, stepUpTier: .sensitive, maxChainLength: 2
        ),
        // A remote MCP client: read-only, and may not re-delegate.
        .remoteMCP: .init(
            allowedScopes: [Ledger.readTransactions],
            maxLifetime: 600, stepUpTier: .sensitive, maxChainLength: 1
        ),
    ])

    static var configuration: BrokerConfiguration {
        var config = BrokerConfiguration()
        config.hardMaxLifetime = 600
        config.proofWindow = 30
        config.auditCapacity = 256
        return config
    }
}

@main
struct DemoApp: App {
    @State private var model: AuthorityConsoleModel?
    @State private var startupError: String?

    init() {
        do {
            _model = State(initialValue: try AuthorityConsoleModel(
                policy: DemoPolicy.ledger,
                configuration: DemoPolicy.configuration
            ))
        } catch {
            _startupError = State(initialValue: String(describing: error))
        }
    }

    var body: some Scene {
        WindowGroup {
            if let model {
                AuthorityConsoleView(model: model)
            } else {
                ContentUnavailableView(
                    "Broker failed to start",
                    systemImage: "exclamationmark.triangle",
                    description: Text(startupError ?? "The compiled-in configuration was rejected.")
                )
            }
        }
    }
}
