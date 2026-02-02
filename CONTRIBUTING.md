# Contributing to HealthQL

Thank you for your interest in contributing to HealthQL! This document provides guidelines and information for contributors.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Assume good intentions

## Getting Started

### Prerequisites

- Xcode 15.0+
- Swift 6.0+
- macOS 13.0+

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/HealthQL.git
   cd HealthQL
   ```
3. Run tests to verify setup:
   ```bash
   swift test
   ```

## Development Workflow

### Branching

- Create a feature branch from `main`:
  ```bash
  git checkout -b feature/your-feature-name
  ```
- Use descriptive branch names:
  - `feature/add-blood-pressure-support`
  - `fix/parser-handles-empty-input`
  - `docs/update-readme-examples`

### Making Changes

1. **Write tests first** - We follow TDD. Write failing tests before implementation.
2. **Keep changes focused** - One feature or fix per PR.
3. **Follow existing patterns** - Match the code style of surrounding code.
4. **Update documentation** - If adding features, update README and code comments.

### Code Style

- Use Swift's standard naming conventions
- Keep functions focused and small
- Add documentation comments for public APIs:
  ```swift
  /// Parses a SQL query string into a HealthQuery IR
  /// - Parameter query: The SQL query string
  /// - Returns: The compiled HealthQuery
  /// - Throws: LexerError, ParserError, or CompilerError
  public static func parse(_ query: String) throws -> HealthQuery
  ```
- Use meaningful variable names
- Prefer clarity over brevity

### Commit Messages

Follow conventional commits format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `test` - Adding or updating tests
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `chore` - Maintenance tasks

**Examples:**
```
feat(parser): add support for BETWEEN operator

fix(executor): handle empty result sets correctly

docs: add examples for workout queries

test: add edge case tests for date parsing
```

### Testing

- All new code must have tests
- Run the full test suite before submitting:
  ```bash
  swift test
  ```
- Aim for meaningful test coverage, not just line coverage
- Test edge cases and error conditions

**Test naming convention:**
```swift
@Test("Parser handles empty WHERE clause")
func parserEmptyWhere() throws {
    // ...
}
```

## Pull Request Process

### Before Submitting

- [ ] All tests pass (`swift test`)
- [ ] Code follows project style
- [ ] Documentation is updated if needed
- [ ] Commit messages follow convention
- [ ] Branch is up to date with `main`

### PR Description

Include:
- **What** - Brief description of changes
- **Why** - Motivation or issue being fixed
- **How** - Approach taken (if not obvious)
- **Testing** - How you tested the changes

**Example:**
```markdown
## Summary
Add support for the HAVING clause in aggregation queries.

## Motivation
Closes #42. Users need to filter aggregated results.

## Changes
- Added HAVING token to lexer
- Extended parser to handle HAVING after GROUP BY
- Added `having` field to HealthQuery IR
- Updated executor to apply HAVING predicates

## Testing
- Added 5 new parser tests for HAVING syntax
- Added 3 integration tests for execution
```

### Review Process

1. Submit PR against `main`
2. Automated tests will run
3. Maintainer will review
4. Address feedback if needed
5. PR will be merged when approved

## Adding New Health Types

To add a new HealthKit type:

1. **Schema** - Add to `QuantityType` or `CategoryType` enum in `Sources/HealthQL/Core/`
2. **Compiler** - Update table name mapping in `Sources/HealthQLParser/Compiler.swift`
3. **Handler** - Ensure handler supports the new type
4. **Tests** - Add parser and execution tests
5. **Docs** - Update README with new type

## Adding New SQL Features

1. **Lexer** - Add new tokens in `Sources/HealthQLParser/Lexer.swift`
2. **AST** - Add node types in `Sources/HealthQLParser/AST.swift`
3. **Parser** - Implement parsing in `Sources/HealthQLParser/Parser.swift`
4. **Compiler** - Add IR generation in `Sources/HealthQLParser/Compiler.swift`
5. **IR** - Extend `HealthQuery` if needed in `Sources/HealthQL/Core/IR.swift`
6. **Executor** - Implement execution in `Sources/HealthQL/Executor/`
7. **Tests** - Add comprehensive tests at each layer

## Reporting Issues

### Bug Reports

Include:
- HealthQL version
- iOS/macOS version
- Minimal reproduction case
- Expected vs actual behavior
- Error messages or logs

### Feature Requests

Include:
- Use case description
- Proposed syntax (if applicable)
- Examples of how it would work

## Questions?

- Open a GitHub Discussion for questions
- Check existing issues before creating new ones
- Tag issues appropriately (`bug`, `enhancement`, `question`)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to HealthQL!
