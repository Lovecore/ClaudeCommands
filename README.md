# Claude Tools
A comprehensive collection of custom hooks, commands, agents, and utility scripts for Claude Code to enhance your AI-powered development workflow.

## Overview

This repository provides a complete toolkit for extending Claude Code with specialized functionality:

- **Hooks**: Automated workflows that trigger during Claude Code sessions
- **Commands**: Chat shortcuts that provide quick access to common development tasks
- **Agents**: Specialized AI assistants for specific development scenarios
- **Utility Scripts**: Standalone tools that complement your development workflow

## Quick Start

```bash
# Clone the repository
git clone git@github.com:Lovecore/ClaudeCommands.git
cd ClaudeCommands

# Run the installation script
./install.sh
```

During installation, you'll be prompted to choose between:

- **Copy mode** (default) - Creates independent copies in ~/.claude directory
- **Symlink mode** - Creates symbolic links to source files (ideal for development)

The installer also sets up utility scripts in ~/.local/bin for system-wide access.

## File Structure

### Installation Scripts

#### install.sh
The main installation script that handles deployment of all Claude Code extensions and utility scripts. Features include:
- Automatic backup of existing files with timestamps
- Support for both copy and symlink installation modes
- Creation of necessary directory structures
- Installation of utility scripts to ~/.local/bin
- PATH validation and setup guidance
- Comprehensive installation summary with usage instructions

#### new-worktree.sh
A Git worktree management utility that creates isolated development environments without switching branches in your main working directory. Supports:
- Feature branch creation with descriptive names
- Issue-based branch naming conventions
- Combined feature and issue branch workflows
- Automatic worktree directory management
- Branch switching and navigation

Installed as `new-worktree` command with usage:
```bash
new-worktree -f feature-name        # Create feature branch
new-worktree -i 123                 # Create issue branch  
new-worktree -f login -i 456        # Create combined branch
```

### Commands Directory

Commands provide quick access to common development workflows through Claude Code chat interface.

#### abs-create-all-issues.md
Creates comprehensive GitHub issues from analysis documents, extracting actionable items and converting them into properly formatted issues with labels, assignments, and project associations.

#### compound-issue.md
Handles complex development tasks that span multiple components, repositories, or systems. Breaks down large initiatives into manageable subtasks with proper tracking and coordination.

#### documentchanges.md
Automatically generates documentation for code changes, including API documentation updates, changelog entries, and architectural decision records.

#### dowork.md
A comprehensive workflow command that guides through the complete development cycle from task analysis to completion, including planning, implementation, testing, and documentation.

#### githubissues.md
Provides GitHub issue management capabilities including creation, updating, labeling, assignment, and project board management with bulk operations support.

#### pr.md
Manages pull request workflows including creation, review preparation, merge conflict resolution, and automated checks integration.

#### securityreview.md
Conducts comprehensive security reviews of codebases, identifying vulnerabilities, analyzing attack vectors, and providing remediation guidance with compliance checking.

#### startwork.md
Initializes development sessions by setting up the workspace, checking dependencies, reviewing recent changes, and preparing the development environment for productive work.

### Agents Directory

Agents are specialized AI assistants designed for specific development scenarios and workflows.

#### document-agent.md
Specialized agent for creating and maintaining technical documentation including API docs, user guides, architectural documentation, and code comments with consistency checking.

#### gh-issue-analyst.md
Analyzes GitHub issues for patterns, priorities, and project planning. Provides insights into issue trends, identifies bottlenecks, and suggests workflow improvements.

#### gh-worker.md
Handles GitHub-related development tasks including repository management, issue processing, pull request coordination, and automated workflow execution.

#### issue-extraction-agent.md
Analyzes documents such as meeting notes, code reviews, security audits, and reports to automatically extract actionable items and convert them into properly structured GitHub issues.

#### merge-conflict-agent.md
Provides expert guidance on resolving Git merge conflicts, implementing conflict prevention strategies, and managing complex merge scenarios across different file types.

#### meta-agent.md
Generates new Claude Code sub-agent configurations from user descriptions, enabling the creation of custom specialized agents tailored to specific project needs.

#### pr-agent.md
Manages the complete pull request lifecycle including creation, branch management, commit organization, description generation, and GitHub issue linking.

#### qa-agent.md
Creates comprehensive test suites, analyzes test coverage, fixes failing tests, and establishes testing strategies for any programming language with support for unit, integration, and end-to-end testing.

#### refactor-agent.md
Improves existing code structure, readability, and maintainability without changing functionality. Handles code cleanup, duplication reduction, naming improvements, and logic simplification.

#### repo-analysis-agent.md
Performs comprehensive architectural reviews of codebases including system design analysis, performance bottleneck identification, security posture evaluation, and production readiness assessment.

#### security-audit-agent.md
Conducts thorough security audits of codebases, identifying vulnerabilities in authentication mechanisms, input validation, data protection, API security, dependencies, and infrastructure configurations.

#### technical-writer.md
Creates comprehensive technical documentation, API documentation, onboarding guides, and technical architecture documentation with focus on clarity and maintainability.

### Hooks Directory

Currently empty but reserved for automated workflows that trigger during Claude Code sessions such as pre-commit validations, automated testing, and deployment preparations.

## Usage

After installation, access the tools through Claude Code:

1. **Commands**: Type `@command-name` in Claude Code chat (e.g., `@dowork`, `@compound-issue`)
2. **Agents**: Access through Claude Code's task system for specialized workflows
3. **Utility Scripts**: Use directly from command line (e.g., `new-worktree -f feature-name`)
