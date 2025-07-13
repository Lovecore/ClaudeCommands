# GitHub Workflow Trigger Task

## Objective
Trigger the GitHub Actions workflow named `development_govt-assist-work-force.yml` located in the `AutoBridgeSystems/eppy-pipelines` repository.

## Context
- Repository containing the workflow: `AutoBridgeSystems/eppy-pipelines`
- Workflow file name: `development_govt-assist-work-force.yml`
- Default branch to trigger on: `main` (can be modified as needed)

## Task Requirements
Use the GitHub CLI (`gh`) to trigger this workflow. The command should:
1. Target the correct repository
2. Run the specific workflow file
3. Execute on the appropriate branch

## Expected Command Structure
```bash
gh workflow run development_govt-assist-work-force.yml \
  --repo AutoBridgeSystems/eppy-pipelines \
  --ref main
```

## Prerequisites
- GitHub CLI must be installed (`gh`)
- User must be authenticated with GitHub CLI (`gh auth status` to check)
- User must have appropriate permissions to trigger workflows in the target repository

## Additional Options (if needed)
- To trigger on a different branch: Change `--ref main` to `--ref <branch-name>`
- To pass inputs to the workflow (if it accepts them): Add `-f input_name=value`
- To monitor the workflow run: Follow up with `gh run list --repo AutoBridgeSystems/eppy-pipelines`

## Success Verification
After triggering, the workflow runs can be viewed at:
https://github.com/AutoBridgeSystems/eppy-pipelines/actions/workflows/development_govt-assist-work-force.yml

## Example Full Execution
```bash
# Trigger the workflow
gh workflow run development_govt-assist-work-force.yml --repo AutoBridgeSystems/eppy-pipelines --ref main

# Check recent runs
gh run list --repo AutoBridgeSystems/eppy-pipelines --workflow=development_govt-assist-work-force.yml --limit 5
```
