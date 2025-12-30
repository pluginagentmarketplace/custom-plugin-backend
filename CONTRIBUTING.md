# Contributing to Backend Plugin

Thank you for your interest in contributing to this Claude Code plugin!

## How to Contribute

1. **Fork** the repository
2. **Create** your feature branch (`git checkout -b feature/amazing-feature`)
3. **Follow** the Golden Format for new skills
4. **Test** your changes thoroughly
5. **Commit** your changes (`git commit -m 'feat: Add amazing feature'`)
6. **Push** to the branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

## Guidelines

### SASMP v2.0.0 Compliance

All contributions must follow SASMP (Standardized Agent/Skill Metadata Protocol) v2.0.0:

- Agents must include `sasmp_version: "2.0.0"` with production-grade configurations
- Skills must include `bonded_agent`, `bond_type`, `atomic_operations`, and `parameter_validation` fields
- Commands must have YAML frontmatter with standardized exit codes

### Agent Development

```yaml
---
name: agent-name
description: Agent description
model: sonnet
tools: Read, Write, Bash
sasmp_version: "2.0.0"

input_schema:
  type: object
  properties:
    query:
      type: string
      required: true

output_schema:
  type: object
  properties:
    response:
      type: string

error_handling:
  types: [VALIDATION_ERROR, PROCESSING_ERROR]
  fallback_strategy: graceful_degradation

retry_config:
  max_attempts: 3
  backoff: exponential
  initial_delay_ms: 1000

token_budget:
  max_input: 4000
  max_output: 2000
---
```

### Skill Development (Golden Format)

```
skills/skill-name/
├── SKILL.md          # Main skill definition
├── assets/           # Templates, configs, schemas
├── scripts/          # Automation scripts
└── references/       # Documentation, guides
```

SKILL.md frontmatter:
```yaml
---
name: skill-name
description: Skill description
sasmp_version: "2.0.0"
bonded_agent: agent-name
bond_type: PRIMARY_BOND

atomic_operations:
  - OPERATION_1
  - OPERATION_2

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5

retry_logic:
  max_attempts: 3
  backoff: exponential
  initial_delay_ms: 1000

logging_hooks:
  on_invoke: "skill.name.invoked"
  on_success: "skill.name.completed"
  on_error: "skill.name.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  PROCESSING_ERROR: 2
---
```

### Command Development

```yaml
---
name: command-name
description: Command description
allowed-tools: Read, Glob

parameter_validation:
  query:
    type: string
    required: true

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  EXECUTION_ERROR: 2
---
```

## Testing Requirements

- Test all new features locally
- Verify agent/skill bonding
- Run `/plugin validate` before submitting
- Ensure no integrity errors (orphan skills, broken bonds, circular dependencies)

## Code of Conduct

- Be respectful and constructive
- Follow existing code style
- Document your changes
- Test before submitting

## Questions?

Open an issue for any questions or suggestions.

---

(c) 2025 Dr. Umit Kacar & Muhsin Elcicek. All Rights Reserved.
