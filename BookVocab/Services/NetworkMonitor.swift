//
//  NetworkMonitor.swift
//  BookVocab
//
//  Monitors network connectivity for offline/online mode switching.
//  Uses NWPathMonitor for real-time network status updates.
//
//  Features:
//  - Real-time connectivity monitoring
//  - Published property for SwiftUI binding
//  - Connection type detection (WiFi, Cellular, etc.)
//  - Debug logging for network changes
//

import Foundation
import Network
import Combine
import os.log

/// Logger for network monitoring
private let logger = Logger(subsystem: "com.bookvocab.app", category: "NetworkMonitor")

// MARK: - Connection Type

/// Represents the type of network connection.
enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
    case none
    
    var description: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        case .none: return "No Connection"
        }
    }
}

// MARK: - Network Monitor

/// Monitors network connectivity and publishes status changes.
/// Use this to determine if the app should work in online or offline mode.
@MainActor
class NetworkMonitor: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide network monitoring.
    static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    
    /// Whether the device is currently connected to the internet.
    @Published private(set) var isConnected: Bool = true
    
    /// The current connection type.
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    /// Whether the connection is considered expensive (cellular data).
    @Published private(set) var isExpensive: Bool = false
    
    /// Whether the connection is constrained (low data mode).
    @Published private(set) var isConstrained: Bool = false
    
    // MARK: - Private Properties
    
    /// The network path monitor.
    private let monitor: NWPathMonitor
    
    /// The dispatch queue for monitoring.
    private let queue = DispatchQueue(label: "com.bookvocab.networkmonitor")
    
    /// Tracks if monitoring has started.
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    /// Creates a new NetworkMonitor and starts monitoring.
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    // Note: deinit removed because this is a singleton that never deallocates,
    // and calling @MainActor methods from deinit causes concurrency issues.
    
    // MARK: - Monitoring
    
    /// Starts monitoring network changes.
    func startMonitoring() {
        guard !isMonitoring else {
            logger.debug("🌐 Network monitoring already active")
            return
        }
        
        logger.info("🌐 Starting network monitoring")
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: queue)
        isMonitoring = true
    }
    
    /// Stops monitoring network changes.
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        logger.info("🌐 Stopping network monitoring")
        monitor.cancel()
        isMonitoring = false
    }
    
    /// Handles network path updates.
    private func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        
        // Update connection status
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.status == .satisfied {
            connectionType = .unknown
        } else {
            connectionType = .none
        }
        
        // Log changes
        if wasConnected != isConnected {
            if isConnected {
                logger.info("🌐 Network CONNECTED via \(self.connectionType.description)")
                // Notify that we're back online
                NotificationCenter.default.post(name: .networkBecameAvailable, object: nil)
            } else {
                logger.warning("🌐 Network DISCONNECTED - switching to offline mode")
                // Notify that we're offline
                NotificationCenter.default.post(name: .networkBecameUnavailable, object: nil)
            }
        }
        
        logger.debug("🌐 Network status: \(self.isConnected ? "Online" : "Offline"), Type: \(self.connectionType.description), Expensive: \(self.isExpensive), Constrained: \(self.isConstrained)")
    }
    
    // MARK: - Utility Methods
    
    /// Checks if the current connection is suitable for large downloads.
    var isSuitableForLargeDownloads: Bool {
        isConnected && !isExpensive && !isConstrained
    }
    
    /// Returns a user-friendly status string.
    var statusDescription: String {
        if isConnected {
            var status = "Online (\(connectionType.description))"
            if isExpensive {
                status += " - Cellular Data"
            }
            return status
        }
        return "Offline"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when network becomes available.
    static let networkBecameAvailable = Notification.Name("networkBecameAvailable")
    
    /// Posted when network becomes unavailable.
    static let networkBecameUnavailable = Notification.Name("networkBecameUnavailable")
}

