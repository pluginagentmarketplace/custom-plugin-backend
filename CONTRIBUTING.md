# Contributing to Backend Development Assistant

Thank you for your interest in contributing! This document provides guidelines for contributing to this plugin.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment.

## How to Contribute

### Reporting Issues

1. Check existing issues to avoid duplicates
2. Use a clear and descriptive title
3. Provide detailed reproduction steps
4. Include relevant error messages or logs

### Suggesting Enhancements

1. Describe the enhancement clearly
2. Explain the use case and benefits
3. Consider backward compatibility

### Pull Requests

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes following our guidelines
4. Test your changes thoroughly
5. Submit a pull request with a clear description

## Development Guidelines

### Agent Development

All agents must follow SASMP v1.3.0:

```yaml
---
name: agent-name
description: Clear description
model: sonnet
domain: custom-plugin-backend
tools: Read, Write, Edit, Bash, Grep, Glob
skills:
  - bonded-skill-name
triggers:
  - "trigger phrase"
sasmp_version: "1.3.0"
eqhm_enabled: true
---
```

### Skill Development

All skills must follow Golden Format:

```
skills/
└── skill-name/
    ├── SKILL.md          # Main skill file with SASMP frontmatter
    ├── assets/           # Templates and configurations
    │   └── README.md
    ├── scripts/          # Executable scripts
    │   └── README.md
    └── references/       # Documentation
        └── README.md
```

### Commit Messages

Follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Tests
- `chore:` Maintenance

### Code Style

- Use clear, descriptive names
- Add comments for complex logic
- Follow existing patterns in the codebase

## Testing

Before submitting:

1. Verify agent frontmatter is valid YAML
2. Check all skill directories have required files
3. Test scripts are executable
4. Validate JSON files are properly formatted

## Questions?

Open an issue with the `question` label or contact plugins@pluginagentmarketplace.com.

---

Thank you for contributing!
