# Troubleshooting Guide

## Common Issues

### Plugin Not Found

**Symptom:** Plugin doesn't appear in Claude Code

**Solution:**
1. Clear plugin cache: `rm -rf ~/.claude/plugins/cache/`
2. Restart Claude Code
3. Reinstall plugin

### Agent Not Triggering

**Symptom:** Agent doesn't activate on expected phrases

**Solution:**
1. Check agent triggers in `agents/*.md`
2. Use exact trigger phrases
3. Verify SASMP frontmatter is valid

### Skill Assets Missing

**Symptom:** Templates/scripts not found

**Solution:**
1. Verify skill structure:
   ```
   skills/{name}/
   ├── SKILL.md
   ├── assets/
   ├── scripts/
   └── references/
   ```
2. Check file permissions

## Validation Commands

```bash
# Check plugin structure
ls -la .claude-plugin/

# Verify agents have SASMP
grep -l "sasmp_version" agents/*.md

# Check skill bonding
grep -l "bonded_agent" skills/*/SKILL.md
```

## Getting Help

- [GitHub Issues](https://github.com/pluginagentmarketplace/custom-plugin-backend/issues)
- Email: plugins@pluginagentmarketplace.com
