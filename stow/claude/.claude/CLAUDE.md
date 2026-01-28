# Documentation for Agents
Please see `AGENTS.md` in the project's root directory for the main project documentation and guidance.
For detailed module-specific implementation guides, also check for `AGENTS.md` files in subdirectories throughout the project.
These component-specific `AGENTS.md` files contain targeted guidance for working with those particular areas of the codebase.

## Updating AGENTS.md Files
When you discover new information that would be helpful for future development work, please:
- **Update existing `AGENTS.md` files** when you learn implementation details, debugging insights, or architectural patterns specific to that component
- **Create new `AGENTS.md` files** in relevant directories when working with areas that don't yet have documentation
- **Add valuable insights** such as common pitfalls, debugging techniques, dependency relationships, or implementation patterns

This helps build a comprehensive knowledge base for the codebase over time.

## Scope Discipline
**CRITICAL: Minimal changes only. Zero scope creep.**

### Rules
- Change ONLY what was explicitly requested in current prompt
- Suggestions → conversation. DO NOT implement without explicit approval
- Work iteratively: complete one atomic task → STOP → report → ask permission for next
- Code should be self-documenting. No unsolicited comments/PHPDoc

### Workflow
- **Before:** State plan. "I will modify `Class::method()` to fix X" (confirm minimal scope)
- **During:** If related work discovered (tests/templates) → STOP, ask permission
- **After:** Report changes made + list related work NOT implemented → await direction

### Prohibited
- Adding features/enhancements not requested
- Refactoring outside direct scope
- Adding documentation unless requested
- Changing multiple concerns in one commit (controllers + tests + templates)
- "Cleaning up" adjacent code
- Implementing suggestions proactively

### Interaction Pattern
- ✗ WRONG: Fix bug → change controller + 3 test files + templates + refactor helper (247 lines)
- ✓ CORRECT: Fix bug → change controller (3 lines) → STOP → "Test needs update. Proceed?" → await approval

**Measure success: minimal lines changed, single-purpose atomic commits, zero scope creep.**
Small + correct > comprehensive + requires human fixes.

# Notes about this system:
- On this host machine, the `grep` command has been aliased to `rg` (ripgrep) meaning standard `grep` commands WILL NOT WORK. **Always** use `rg` instead.
- When running commands inside Docker containers, the original `grep` command will be available.
