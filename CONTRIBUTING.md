# Contributing to VIT Verse

Thank you for your interest in contributing to VIT Verse! This document provides guidelines for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
3. [Development Setup](#development-setup)
4. [Contribution Workflow](#contribution-workflow)
5. [Coding Standards](#coding-standards)
6. [Commit Guidelines](#commit-guidelines)

---

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other contributors

---

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots (if applicable)
- Device and app version information

### Suggesting Features

Feature suggestions are welcome! Please create an issue with:
- A clear description of the feature
- Use cases and benefits
- Any potential implementation ideas

### Code Contributions

We welcome pull requests for:
- Bug fixes
- New features
- Performance improvements
- Documentation updates
- Code refactoring

---

## Development Setup

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Setup Steps

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/vit-connect.git
   cd vit-connect
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Create .env file**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## Contribution Workflow

1. **Create a new branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow the project's coding standards
   - Add comments where necessary

3. **Test your changes**
   - Test on multiple devices/screen sizes
   - Ensure no existing functionality is broken
   - Check for performance issues

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of changes
   - Reference any related issues
   - Include screenshots/videos if UI changes

---

## Coding Standards

### Dart/Flutter

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Keep functions small and focused
- Document complex logic with comments
- Use const constructors where possible

### File Organization

```
lib/
├── core/           # Core utilities, config, theme
├── features/       # Feature modules
├── firebase/       # Firebase integration
└── supabase/       # Supabase integration
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`

---

## Commit Guidelines

We follow conventional commits for clear commit history:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `perf:` Performance improvements
- `test:` Adding or updating tests
- `chore:` Build process or auxiliary tool changes

**Example:**
```
feat: add dark mode toggle in settings
fix: resolve login crash on Android 12
docs: update README with new setup instructions
```

---

## Questions?

If you have questions about contributing, feel free to:
- Open an issue with the `question` label
- Email: itzdivyanshupatel@gmail.com

---

Thank you for contributing to VIT Verse! 🚀
