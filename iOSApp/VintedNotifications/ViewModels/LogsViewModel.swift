//
//  LogsViewModel.swift
//  Vinted Notifications
//

import Foundation
import Combine

class LogsViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to LogService updates
        LogService.shared.$logs
            .receive(on: DispatchQueue.main)
            .assign(to: &$logs)
    }

    func clearLogs() {
        LogService.shared.clearLogs()
    }
}
