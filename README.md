# Faro OpenTelemetry-Swift Exporter

<img src="./docs/assets/faro_logo.png" alt="Grafana Faro logo" width="300" />

The Faro Exporter is an OpenTelemetry exporter that sends telemetry data to [Grafana Faro](https://grafana.com/oss/faro/), an open-source frontend application monitoring solution. This exporter supports both traces and logs in a single instance with automatic session management, allowing you to monitor your iOS applications using either Grafana Cloud or your own self-hosted infrastructure using [Grafana Alloy](https://grafana.com/docs/alloy) as your collector

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/grafana/faro-otel-swift-exporter.git", from: "1.0.0")
]
```

Or in Xcode:

1. Go to File > Add Packages...
2. Enter the package URL: `https://github.com/grafana/faro-otel-swift-exporter.git`
3. Select the version or branch you want to use
4. Click "Add Package"

## Usage

### Configuration

Create a `FaroExporterOptions` instance with your configuration:

> **Note:** For Grafana Cloud users, you can find your collector URL in the Frontend Observability configuration section of your Grafana Cloud instance. For self-hosted setups using Grafana Alloy, refer to the [Quick Start Guide](https://github.com/grafana/faro-web-sdk/blob/main/docs/sources/tutorials/quick-start-browser.md) for detailed setup instructions.

```swift
let faroOptions = FaroExporterOptions(
    collectorUrl: "http://your-faro-collector.net/collect/YOUR_API_KEY",
    appName: "your-app-name",
    appVersion: "1.0.0",
    appEnvironment: "production"
)
```

### Traces Setup

To use the Faro exporter for traces:

```swift
// Create the Faro exporter
let faroExporter = try! FaroExporter(options: faroOptions)

// Create a span processor with the Faro exporter
let faroProcessor = BatchSpanProcessor(spanExporter: faroExporter)

// Configure the tracer provider
let tracerProvider = TracerProviderBuilder()
    .add(spanProcessor: faroProcessor)
    ...
    .build()
```

### Logs Setup

To use the Faro exporter for logs:

```swift
// Create the Faro exporter (or reuse the one from traces)
let faroExporter = try! FaroExporter(options: faroOptions)

// Create a log processor with the Faro exporter
let faroProcessor = BatchLogRecordProcessor(logRecordExporter: faroExporter)

// Configure the logger provider
let loggerProvider = LoggerProviderBuilder()
    .with(processors: [faroProcessor])
    ...
    .build()
```

### User Context

Faro supports defining a user for a session, which helps correlate telemetry data with specific users. Since OpenTelemetry doesn't currently have a native concept of user context, the Faro exporter implements a workaround using specialized log records.

To set the current user for your session:

```swift
// Import to access constants
import FaroOtelExporter

// Get a logger instance
let logger = loggerProvider.get(instrumentationScopeName: "your-scope-name")

// Set the current user by sending a special log with user attributes
logger.logRecordBuilder()
    .setBody(OpenTelemetryApi.AttributeValue.string(FaroOtelConstants.ChangeUser.otelBody))
    .setAttributes([
        FaroOtelConstants.ChangeUser.AttributeKeys.username: OpenTelemetryApi.AttributeValue.string("some_user"),
        FaroOtelConstants.ChangeUser.AttributeKeys.userEmail: OpenTelemetryApi.AttributeValue.string("some_user@example.com"),
        FaroOtelConstants.ChangeUser.AttributeKeys.userId: OpenTelemetryApi.AttributeValue.string("12345")
    ])
    .emit()
```

When the Faro exporter detects a log with the body text FaroOtelConstants.ChangeUser.otelBody ("otel_change_user"), it will:

1. Extract the user information from the attributes
2. Set this as the current user for the session
3. Not forward this message as a regular log
4. Any other attributes added to the regular log will be ignored
5. The log severity does not matter, it will be ignored

This approach allows you to maintain user context across your application's telemetry data without requiring changes to the OpenTelemetry protocol.

> **Note:** The example above uses constants from the `FaroOtelConstants` class for clean, maintainable code. You can also use string literals directly if preferred:
>
> ```swift
> logger.logRecordBuilder()
>    .setBody(OpenTelemetryApi.AttributeValue.string("otel_change_user"))
>    .setAttributes([
>        "username": OpenTelemetryApi.AttributeValue.string("some_user"),
>        "user_email": OpenTelemetryApi.AttributeValue.string("some_user@example.com"),
>        "user_id": OpenTelemetryApi.AttributeValue.string("12345")
>    ])
>    .emit()
> ```

## Privacy

This exporter utilizes certain APIs that require privacy declarations as mandated by Apple:

- **Device Identification:** The SDK uses `identifierForVendor` (via `UIDevice.current.identifierForVendor` or `WKInterfaceDevice.current().identifierForVendor`) and `UserDefaults` as a complementary mechanism to generate and persist a unique device identifier. This helps correlate telemetry data within your application's sessions without relying on personally identifiable information. On platforms where `identifierForVendor` might be unavailable (e.g., on macOS), `UserDefaults` with a generated UUID serves as a fallback mechanism to maintain consistent device identification.

A `PrivacyInfo.xcprivacy` file is included in this package (located at `Sources/FaroOtelExporter/PrivacyInfo.xcprivacy`), declaring the usage of these APIs. When you integrate this SDK into your application, this manifest will be bundled, contributing to your app's overall privacy report. Please review Apple's documentation on [Privacy Manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) to understand how this impacts your app submission process.

## Additional Resources

- [Grafana Faro Documentation](https://grafana.com/oss/faro/)
- [Grafana Alloy Setup Guide](https://grafana.com/docs/alloy/latest/set-up/)
- [Frontend Monitoring Dashboard](https://grafana.com/grafana/dashboards/17766-frontend-monitoring/)

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project, including setting up your development environment and guidelines for code style.
