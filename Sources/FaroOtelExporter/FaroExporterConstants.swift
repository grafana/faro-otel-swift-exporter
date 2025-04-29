import Foundation

/// Constants used throughout the FaroOtelExporter
public enum FaroOtelConstants {
    public enum ChangeUser {
        /// String to use as the otel log body for the change user event
        public static let otelBody = "otel_change_user"

        // swiftlint:disable:next nesting
        public enum AttributeKeys {
            /// The user id attribute key
            public static let userId = "user_id"
            /// The username attribute key
            public static let username = "username"
            /// The user email attribute key
            public static let userEmail = "user_email"
        }
    }
}

enum FaroConstants {
    /// Constants related to Faro events
    enum Events {
        /// Name of the internal user updated event
        static let userUpdated = "faro_internal_user_updated"
    }
}
