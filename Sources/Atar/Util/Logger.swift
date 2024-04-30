//
//  Logger.swift
//
//
//  Created by Alex Austin on 4/1/24.
//

import Foundation

class Logger {
    static var shared: Logger = Logger(debugMode: true)  // Default to non-debug mode
    
    private var debugMode: Bool

    private init(debugMode: Bool) {
        self.debugMode = debugMode
    }

    static func initialize(withDebugMode debugMode: Bool) {
        shared = Logger(debugMode: debugMode)
    }

    func log(_ message: String) {
        if !debugMode {
            return
        }
        print(message)
    }

    func setDebugMode(_ isEnabled: Bool) {
        debugMode = isEnabled
    }
}
