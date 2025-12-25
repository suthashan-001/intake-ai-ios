import Foundation
import Network
import SwiftUI

// MARK: - Network Monitor
/// Monitors network connectivity status
@MainActor
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wired: return "cable.connector"
            case .unknown: return "questionmark.circle"
            }
        }

        var label: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wired: return "Wired"
            case .unknown: return "Unknown"
            }
        }
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        }
        return .unknown
    }
}

// MARK: - Offline Banner View
struct OfflineBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var isVisible = false

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: DesignSystem.IconSize.md, weight: .semibold))

                Text("You're offline")
                    .font(DesignSystem.Typography.titleSmall)

                Spacer()

                Text("Changes will sync when connected")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(.white.opacity(0.8))
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.error)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : -50)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
        }
    }
}
