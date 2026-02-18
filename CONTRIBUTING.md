# Contributing to itelo

Thanks for your interest in contributing.

## Ground Rules

- Be respectful and constructive.
- Keep pull requests focused and small.
- Open an issue before large architectural changes.

## Development Setup

1. Fork and clone the repository.
2. Open `AIchatbot.xcodeproj` in Xcode.
3. Build locally:

```bash
xcodebuild -project AIchatbot.xcodeproj -scheme AIchatbot -configuration Debug -sdk iphonesimulator build
```

4. Run tests (if available in your branch):

```bash
xcodebuild -project AIchatbot.xcodeproj -scheme AIchatbot -configuration Debug -sdk iphonesimulator test
```

## Pull Request Checklist

- [ ] Build passes locally.
- [ ] Tests added or updated when behavior changes.
- [ ] Public API and UX changes are documented.
- [ ] Large binaries are not committed directly.
- [ ] Model-related changes include reproducible download/setup instructions.

## Commit Style

- Use clear, imperative commit messages.
- Reference issue IDs when relevant (for example: `Fix #42`).

## Reporting Bugs

Use the bug issue template and include:

- Reproduction steps
- Expected vs actual behavior
- Device/Simulator + iOS version
- Xcode version
