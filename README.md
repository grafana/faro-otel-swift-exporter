# Faro OpenTelemetry-Swift Exporter

<img src="./docs/assets/faro_logo.png" alt="Grafana Faro logo" width="300" />

The Faro Exporter is an OpenTelemetry exporter that sends telemetry data to [Grafana Faro](https://grafana.com/oss/faro/), an open-source frontend application monitoring solution. This exporter supports both traces and logs in a single instance with automatic session management, allowing you to monitor your iOS applications using either Grafana Cloud or your own self-hosted infrastructure using [Grafana Alloy](https://grafana.com/docs/alloy) as your collector

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

## Privacy

This SDK utilizes certain APIs that require privacy declarations as mandated by Apple:

- **Identifier For Vendor (`identifierForVendor`):** Used via `UIDevice.current.identifierForVendor` or `WKInterfaceDevice.current().identifierForVendor` (depending on the platform) to generate a unique identifier for the device. This helps correlate telemetry data and errors to a specific device instance for observability purposes within your application's sessions, without relying on personally identifiable information across different app vendors. The reason declared in the privacy manifest is `CA92.1` (App Functionality).
- **User Defaults (`UserDefaults`):** Used as a fallback mechanism to store a generated unique device identifier _only_ when `identifierForVendor` is unavailable (e.g., on macOS or older watchOS versions where it wasn't available or reliable). This ensures consistent device identification for telemetry within the scope of this SDK's usage. The reason declared in the privacy manifest is `CA92.1` (App Functionality).

A `PrivacyInfo.xcprivacy` file is included in this package (located at `Sources/FaroOtelExporter/PrivacyInfo.xcprivacy`), declaring the usage of these APIs. When you integrate this SDK into your application, this manifest will be bundled, contributing to your app's overall privacy report. Please review Apple's documentation on [Privacy Manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) to understand how this impacts your app submission process.

## Additional Resources

- [Grafana Faro Documentation](https://grafana.com/oss/faro/)
- [Grafana Alloy Setup Guide](https://grafana.com/docs/alloy/latest/set-up/)
- [Frontend Monitoring Dashboard](https://grafana.com/grafana/dashboards/17766-frontend-monitoring/)

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project, including setting up your development environment and guidelines for code style.
