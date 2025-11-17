# Skill: Package Management & Dependency Management

## Objective
Understand how to manage dependencies, handle versioning, resolve conflicts, and maintain a healthy project ecosystem.

## What is Package Management?

A package manager is a tool that:
- **Installs** external libraries and frameworks
- **Tracks** dependencies and versions
- **Updates** packages to newer versions
- **Resolves** conflicts between dependencies
- **Manages** project metadata and configuration
- **Enables** reproducible builds across environments

## Core Concepts

### Packages & Libraries
- **Package**: Reusable code published to a repository
- **Library**: Code providing specific functionality
- **Framework**: Opinionated structure for building applications
- **Dependency**: External package required by your project

### Versioning (Semantic Versioning)

Format: `MAJOR.MINOR.PATCH` (e.g., 1.2.3)

- **MAJOR** - Incompatible API changes
- **MINOR** - Backward-compatible new features
- **PATCH** - Backward-compatible bug fixes

#### Version Specifiers
- `1.2.3` - Exact version
- `^1.2.3` - Compatible with version (caret)
- `~1.2.3` - Approximately equivalent to version (tilde)
- `>=1.2.3` - Greater than or equal
- `1.2.x` - Patch version can be anything
- `*` - Any version

### Dependency Types
- **Direct Dependencies** - Explicitly required by your project
- **Transitive Dependencies** - Required by your dependencies
- **Dev Dependencies** - Only needed during development
- **Peer Dependencies** - Expected to be installed by consuming package
- **Optional Dependencies** - Nice to have, installation may fail

## Package Managers by Language

### Node.js / JavaScript

#### npm (Node Package Manager)
**Default package manager for Node.js**

**Key Features**:
- Largest package ecosystem (1M+ packages)
- Built into Node.js
- `package.json` and `package-lock.json`
- Scripts automation
- npm CLI for management

**Basic Commands**:
```bash
npm init                 # Create package.json
npm install package-name # Install dependency
npm install --save-dev   # Install dev dependency
npm update               # Update packages
npm uninstall package    # Remove package
npm audit               # Check security issues
npm run script-name     # Run defined script
npm publish             # Publish to npm registry
```

**Configuration**: `package.json`
```json
{
  "name": "my-app",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

#### yarn
**Advanced package manager built on npm**

**Advantages**:
- Faster installation (parallel downloads)
- Better dependency resolution
- Workspaces for monorepos
- Offline installation support
- More deterministic builds

**Basic Commands**:
```bash
yarn init               # Initialize project
yarn add package-name   # Add dependency
yarn add -D package     # Add dev dependency
yarn upgrade            # Update dependencies
yarn remove             # Remove package
yarn install            # Install from lock file
yarn workspaces        # Manage monorepos
```

#### pnpm
**Space-efficient package manager**

**Advantages**:
- Content-addressable storage (50%+ disk savings)
- Fast installation
- Strict dependency management
- Monorepo support
- Alternative to npm and yarn

**Basic Commands**:
```bash
pnpm init              # Initialize
pnpm add package       # Add dependency
pnpm add -D package    # Add dev dependency
pnpm install           # Install
pnpm update            # Update packages
pnpm remove            # Remove package
```

---

### Python

#### pip
**Default Python package manager**

**Key Features**:
- Simple command-line interface
- PyPI (Python Package Index) repository
- Virtual environment support
- requirements.txt for dependency tracking

**Basic Commands**:
```bash
pip install package-name          # Install package
pip install -r requirements.txt   # Install from file
pip freeze > requirements.txt     # Export dependencies
pip list                          # List installed packages
pip show package-name             # Show package info
pip uninstall package-name        # Remove package
pip cache purge                   # Clear cache
```

**requirements.txt Format**:
```
requests==2.28.0
numpy>=1.20.0
pandas~=1.3.0
-e git+https://github.com/user/repo.git#egg=package
```

#### Poetry
**Modern Python dependency management and packaging**

**Advantages**:
- Deterministic builds (poetry.lock)
- Intuitive dependency declaration
- Virtual environment management
- Build and publish tools
- Dependency resolution

**Basic Commands**:
```bash
poetry init                  # Create pyproject.toml
poetry add package-name      # Add dependency
poetry add --group dev pkg   # Add dev dependency
poetry install              # Install from lock file
poetry update               # Update dependencies
poetry remove package       # Remove package
poetry build                # Build distribution
poetry publish              # Publish to PyPI
```

#### Conda
**Package manager for data science (Anaconda/Miniconda)**

**Key Features**:
- Handles both Python and non-Python dependencies
- Conda-forge for extended packages
- Environment management
- Great for data science workflows

**Basic Commands**:
```bash
conda create -n env-name python=3.9    # Create environment
conda activate env-name                 # Activate environment
conda install package-name              # Install package
conda list                              # List packages
conda update package-name               # Update package
conda remove package-name               # Remove package
conda env export > environment.yml      # Export environment
```

---

### Java

#### Maven
**Build automation and package management**

**Key Features**:
- Dependency management through POM (Project Object Model)
- Plugins for compilation, testing, packaging
- Central repository
- Standardized project structure
- Build lifecycle management

**Project Structure**:
```
my-app/
├── pom.xml                 # Maven configuration
├── src/
│   ├── main/java/         # Source code
│   └── test/java/         # Test code
└── target/                 # Build output
```

**pom.xml Example**:
```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter</artifactId>
    <version>2.7.0</version>
  </dependency>
</dependencies>
```

**Basic Commands**:
```bash
mvn clean compile           # Compile project
mvn test                    # Run tests
mvn package                 # Create JAR/WAR
mvn install                 # Install to local repository
mvn dependency:tree         # Show dependency tree
mvn dependency:update-help  # Check for updates
```

#### Gradle
**Advanced build automation tool**

**Advantages**:
- Groovy/Kotlin DSL for configuration
- Faster builds than Maven
- Incremental compilation
- Plugin ecosystem
- Multi-project builds

**Basic Commands**:
```bash
gradle build                # Build project
gradle test                 # Run tests
gradle jar                  # Create JAR
gradle dependencies         # Show dependencies
gradle dependencyUpdates    # Check for updates
gradle clean                # Clean build artifacts
```

**build.gradle Example**:
```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter:2.7.0'
    testImplementation 'junit:junit:4.13.2'
}
```

---

### C# / .NET

#### NuGet
**Package manager for .NET ecosystem**

**Key Features**:
- nuget.org central repository
- Visual Studio integration
- Package.config or PackageReference
- Restore, update, uninstall operations

**Basic Commands**:
```bash
dotnet add package package-name        # Add NuGet package
dotnet remove package package-name     # Remove package
dotnet restore                         # Restore packages
dotnet list package                    # List installed
dotnet package search package-name     # Search packages
dotnet add package package --version 2.0.0  # Specific version
```

**Project File (.csproj)**:
```xml
<ItemGroup>
  <PackageReference Include="Newtonsoft.Json" Version="13.0.1" />
</ItemGroup>
```

---

### PHP

#### Composer
**Dependency manager for PHP**

**Key Features**:
- PSR standards compliance
- Packagist.org repository
- Autoloading support
- Version constraints
- Lock file (composer.lock)

**Basic Commands**:
```bash
composer init                   # Create composer.json
composer require vendor/package # Add dependency
composer require --dev vendor/pkg  # Add dev dependency
composer install               # Install from composer.lock
composer update                # Update dependencies
composer remove vendor/package # Remove package
composer dump-autoload         # Generate autoloader
```

**composer.json Example**:
```json
{
  "require": {
    "monolog/monolog": "^2.0"
  },
  "require-dev": {
    "phpunit/phpunit": "^9.0"
  }
}
```

---

### Go

#### Go Modules
**Built-in dependency management (since Go 1.11)**

**Key Features**:
- No separate package manager needed
- `go.mod` and `go.sum` files
- Semantic versioning
- Decentralized package hosting
- Reproducible builds

**Basic Commands**:
```bash
go mod init module/name            # Initialize module
go get github.com/user/package    # Add dependency
go get -u package                 # Update package
go mod tidy                       # Clean up dependencies
go mod vendor                     # Vendor dependencies
go mod graph                      # Show dependency graph
```

**go.mod Example**:
```
module github.com/myuser/myapp

go 1.19

require github.com/gin-gonic/gin v1.8.1
```

---

### Ruby

#### RubyGems
**Package manager for Ruby**

**Key Features**:
- rubygems.org repository
- Simple and straightforward
- Bundler for dependency management
- Gem specification

**Basic Commands**:
```bash
gem install gem-name               # Install gem
gem uninstall gem-name            # Remove gem
gem list                          # List gems
gem search gem-name               # Search gems
gem update                        # Update gems
gem fetch gem-name                # Download gem
```

#### Bundler
**Dependency management for Ruby**

**Better Practice for Projects**

**Basic Commands**:
```bash
bundle init                   # Create Gemfile
bundle add gem-name           # Add gem
bundle install               # Install from Gemfile.lock
bundle update                # Update gems
bundle show gem-name         # Show gem location
bundle exec command          # Run command with bundle context
```

**Gemfile Example**:
```ruby
source 'https://rubygems.org'

gem 'rails', '~> 7.0'
gem 'sqlite3', '~> 1.4'

group :development, :test do
  gem 'rspec-rails'
end
```

---

## Best Practices for Package Management

### 1. Lock Files
Always commit lock files to version control:
- `package-lock.json` (npm)
- `yarn.lock` (yarn)
- `composer.lock` (PHP)
- `poetry.lock` (Python)
- `Gemfile.lock` (Ruby)
- `go.sum` (Go)

**Why**: Ensures reproducible builds across environments

### 2. Version Constraints
Use semantic versioning wisely:
```
✓ Good:  "express": "^4.18.0"    # Allow minor/patch updates
✗ Bad:   "express": "*"           # Too loose
✓ Good:  "lodash": "~1.2.3"      # Lock minor version
✗ Bad:   "special": "1.2.3"       # Too strict (maintenance burden)
```

### 3. Minimize Dependencies
- Reduce transitive dependency bloat
- Evaluate necessity of each package
- Consider alternatives for heavy packages
- Remove unused dependencies

### 4. Security Management
```bash
# Check for vulnerabilities
npm audit
npm audit fix

# Python
pip list --outdated
safety check

# Composer (PHP)
composer audit

# Go
go list -u -m all
```

### 5. Regular Updates
- Schedule dependency updates
- Test after updates
- Monitor breaking changes
- Use automated tools (Dependabot, Renovate)

### 6. Private Packages
- Use private registries for proprietary code
- npm private packages
- GitHub Packages
- Artifactory or Nexus

### 7. Monorepo Management
For multiple packages in one repository:
- npm workspaces
- Yarn workspaces
- pnpm monorepo mode
- Lerna (JavaScript)
- Gradle multi-project (Java)
- Poetry monorepos (Python)

## Dependency Resolution

### Common Issues

**Diamond Dependency Problem**:
```
App
├── Package A (requires B v1.0)
└── Package C (requires B v2.0)
```

**Solution**: Use version constraints to find compatible version

**Circular Dependencies**:
- A requires B, B requires A
- Break circular reference
- Refactor code structure

**Version Conflicts**:
- Different packages require incompatible versions
- Use virtual environments/sandboxes
- Negotiate version compatibility

## Reproducible Builds

### Key Principles
1. **Lock all dependencies** - Use lock files
2. **Pin versions explicitly** - No floating versions
3. **Isolated environments** - Virtual environments/containers
4. **Document setup** - README with setup instructions
5. **CI/CD verification** - Test in clean environments

### Example Workflow
```bash
# Development
npm install            # Install from lock file

# Production
npm ci                 # Clean install (respects lock file)

# Docker
COPY package*.json ./
RUN npm ci --only=production
```

## Auditing & Maintenance

### Regular Tasks
- **Weekly**: Check for security updates
- **Bi-weekly**: Update non-critical packages
- **Monthly**: Major version updates (with thorough testing)
- **Quarterly**: Dependency cleanup and optimization

### Tools
- Dependabot (GitHub)
- Renovate (GitLab, GitHub, Gitea)
- npm audit / pip safety
- OWASP Dependency-Check

## Success Criteria

- [ ] Chosen and configured appropriate package manager
- [ ] Created project configuration file (package.json, Pipfile, etc.)
- [ ] Installed and managed dependencies
- [ ] Understood version constraints and semantic versioning
- [ ] Created lock file and committed to version control
- [ ] Resolved dependency conflicts
- [ ] Implemented security scanning workflow
- [ ] Automated dependency updates and vulnerability checks
