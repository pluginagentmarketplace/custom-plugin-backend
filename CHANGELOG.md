# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-12-28

### Added
- SASMP v1.3.0 compliance for all agents and skills
- Golden Format structure for all 7 skills
- Real template files (YAML, SQL, Dockerfile, Shell scripts)
- Comprehensive reference documentation
- marketplace.json for plugin registry
- Custom License (Dr. Umit Kacar & Muhsin Elcicek)
- CONTRIBUTING.md with contribution guidelines
- Professional README.md with badges and tables

### Changed
- Upgraded all agent frontmatter with full SASMP fields
- Migrated skills from basic structure to Golden Format
- Fixed plugin.json with correct author format and repository URL
- Updated hooks.json to correct object format

### Fixed
- Typo in repository URL (custum → custom)
- Author format in plugin.json (string → object)
- License format (MIT → SEE LICENSE IN LICENSE)
- hooks.json format (array → object)
- docs/README.md typos and license reference

### Replaced
- Old HTML tutorial site in docs/ replaced with standard plugin docs:
  - docs/INSTALLATION.md
  - docs/USAGE.md
  - docs/TROUBLESHOOTING.md
- HTML site moved to `/tmp/custom-plugin-backend-cleanup/docs-html-site/`

### Removed (Moved to /tmp for recovery)
Old agent folders replaced by SASMP-compliant .md files:
- `agents/01-programming-fundamentals/`
- `agents/02-database-management/`
- `agents/03-api-development/`
- `agents/04-architecture-patterns/`
- `agents/05-caching-performance/`
- `agents/06-devops-infrastructure/`
- `agents/07-testing-security/`

Legacy JSON analysis files (no longer needed):
- `api-development-comprehensive-guide.json`
- `architecture-design-patterns.json`
- `backend_database_comprehensive_guide.json`
- `backend_roadmap_analysis.json`
- `backend_testing_security_monitoring_comprehensive.json`
- `backend-performance-optimization-guide.json`
- `devops-infrastructure-comprehensive.json`

**Recovery Location:** `/tmp/custom-plugin-backend-cleanup/`

## [1.0.0] - 2025-11-18

### Added
- Initial release with 7 agents
- Basic skill structure
- Learning path documentation
- Backend development curriculum

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 2.0.0 | 2025-12-28 | SASMP v1.3.0 + Golden Format migration + Cleanup |
| 1.0.0 | 2025-11-18 | Initial release |
