# itelo

`itelo` is an on-device AI assistant for iOS, built with SwiftUI and SwiftData.
It is designed for private, local-first conversations, reminders, and lightweight image workflows.

## Why itelo

- Local-first chat experience
- SwiftUI interface with modern iOS patterns
- SwiftData-backed chat sessions
- Reminder parsing and creation hooks
- Image generation entry point via Image Playground APIs

## Requirements

- macOS
- Xcode 17 or newer
- iOS Simulator SDK supported by this project

## Quick Start

1. Clone the repository:

```bash
git clone https://github.com/<your-org-or-username>/itelo.git
cd itelo
```

2. Open the project:

```bash
open AIchatbot.xcodeproj
```

3. (Optional) Download local model assets:

```bash
bash scripts/download_models.sh
```

4. Build from CLI:

```bash
xcodebuild -project AIchatbot.xcodeproj -scheme AIchatbot -configuration Debug -sdk iphonesimulator build
```

## Open Source Standards

This repository includes:

- MIT license
- Contribution guidelines
- Code of Conduct
- Security policy
- Issue templates and PR template
- Starter CI workflow for pull requests

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

## Security

Report vulnerabilities according to [`SECURITY.md`](SECURITY.md).

## License

Released under the [`MIT License`](LICENSE).
