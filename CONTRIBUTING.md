# Contributing to Faro OpenTelemetry-Swift Exporter

Thank you for considering contributing! We welcome contributions from the community. Please follow these guidelines to help us manage the process.

## Development Environment Setup

1.  Clone the repository:
    ```bash
    git clone git@github.com:grafana/faro-otel-swift-exporter.git
    cd faro-otel-swift-exporter
    ```
2.  Open the project in Xcode or build using Swift Package Manager:
    ```bash
    swift build
    ```

## Running Tests

To ensure your changes don't break existing functionality, please run the test suite:

```bash
swift test
```

Make sure all tests pass before submitting a pull request.

## Code Style & Formatting

This project uses [SwiftLint](https://github.com/realm/SwiftLint) for linting and [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for code formatting to ensure consistency and maintainability. Adhering to these standards is required for contributions.

### Installation

If you don't have them installed already, you can install them using Homebrew:

```bash
brew install swiftlint swiftformat
```

### Usage

- **Formatting:** Before committing, format the code according to the project's style:
  ```bash
  swiftformat .
  ```
- **Linting:** Check for style violations and potential errors:
  ```bash
  swiftlint lint
  ```
  To automatically correct some linting issues (use with caution and review changes):
  ```bash
  swiftlint lint --fix
  ```

The CI pipeline will run these checks automatically on pull requests. Please ensure your code is formatted and linted correctly locally before pushing.

## Submitting Changes

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix (`git checkout -b feature/my-new-feature` or `git checkout -b fix/issue-123`).
3.  Make your changes, including tests for new functionality.
4.  Ensure tests pass (`swift test`).
5.  Format and lint your code (`swiftformat .` and `swiftlint lint`).
6.  Commit your changes with a clear commit message.
7.  Push your branch to your fork (`git push origin feature/my-new-feature`).
8.  Open a pull request against the `main` branch of the original repository. Describe your changes clearly in the pull request description.

## Questions?

Feel free to open an issue if you have questions about contributing.
