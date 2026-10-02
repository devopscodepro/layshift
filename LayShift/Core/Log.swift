import os

enum Log {
    private static let subsystem = "pro.devopscode.LayShift"

    static let sources = Logger(subsystem: subsystem, category: "sources")
    static let shortcuts = Logger(subsystem: subsystem, category: "shortcuts")
    static let settings = Logger(subsystem: subsystem, category: "settings")
}
