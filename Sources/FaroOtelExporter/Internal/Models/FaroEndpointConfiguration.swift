import Foundation

/// Configuration for connecting to a Faro collector endpoint
struct FaroEndpointConfiguration {
    /// URL of the Faro collector endpoint
    let collectorUrl: URL

    /// API key for authentication with the Faro backend
    let apiKey: String
}
