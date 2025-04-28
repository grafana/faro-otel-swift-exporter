extension FaroAppInfo {
    /// Creates a FaroAppInfo instance from FaroExporterOptions
    /// - Parameter options: The exporter options containing app information
    /// - Returns: A configured FaroAppInfo instance
    static func create(from options: FaroExporterOptions) -> FaroAppInfo {
        FaroAppInfo(
            name: options.appName,
            namespace: options.namespace,
            version: options.appVersion,
            environment: options.appEnvironment,
            bundleId: nil,
            release: nil
        )
    }
}
