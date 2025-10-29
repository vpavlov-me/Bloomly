# Dangerfile for BabyTrack
# Automated PR checks and suggestions

# ------------------------------------------------------------------------------
# 1. PR Metadata Checks
# ------------------------------------------------------------------------------

# Warn when PR is marked as WIP
warn("PR is marked as Work in Progress") if github.pr_title.include? "[WIP]"

# Encourage smaller PRs
warn("This PR is quite large (#{git.lines_of_code} lines changed). Consider splitting it into smaller PRs for easier review.") if git.lines_of_code > 500

# Ensure PR has a description
fail("Please add a description to your PR.") if github.pr_body.length < 10

# Encourage milestone assignment
warn("Please assign a milestone to this PR.") if github.pr_json["milestone"].nil?

# ------------------------------------------------------------------------------
# 2. Code Quality Checks
# ------------------------------------------------------------------------------

# Check for new SwiftLint violations
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files inline_mode: true

# Warn about force unwrapping
has_force_unwrap = git.modified_files.any? do |file|
  next unless file.end_with?('.swift')
  diff = git.diff_for_file(file)
  next unless diff

  diff.patch.include?('!')
end

warn("⚠️ This PR contains force unwrapping (!). Consider using optional binding or guard statements instead.") if has_force_unwrap

# Check for TODO/FIXME comments in added lines
added_todos = []
git.modified_files.each do |file|
  next unless file.end_with?('.swift')
  diff = git.diff_for_file(file)
  next unless diff

  diff.patch.split("\n").each_with_index do |line, index|
    if line.start_with?("+") && (line.include?("TODO") || line.include?("FIXME"))
      added_todos << "#{file}:#{index}"
    end
  end
end

if added_todos.any?
  message("📝 This PR adds #{added_todos.count} TODO/FIXME comment(s). Make sure to track them!")
end

# ------------------------------------------------------------------------------
# 3. Test Coverage Checks
# ------------------------------------------------------------------------------

# Warn if no tests were added for new Swift files
added_swift_files = git.added_files.select { |f| f.end_with?('.swift') && !f.include?('Tests') }
added_test_files = git.added_files.select { |f| f.end_with?('.swift') && f.include?('Tests') }

if added_swift_files.any? && added_test_files.empty?
  warn("🧪 New Swift files were added but no test files. Consider adding tests for the new functionality.")
end

# ------------------------------------------------------------------------------
# 4. Documentation Checks
# ------------------------------------------------------------------------------

# Check if README was modified for significant changes
significant_changes = git.lines_of_code > 100
readme_modified = git.modified_files.include?("README.md")

if significant_changes && !readme_modified
  warn("📚 This is a significant change. Consider updating the README.md if needed.")
end

# Check for documentation comments on public APIs
git.modified_files.each do |file|
  next unless file.end_with?('.swift')
  diff = git.diff_for_file(file)
  next unless diff

  # Look for public declarations without doc comments
  lines = diff.patch.split("\n")
  lines.each_with_index do |line, index|
    if line.start_with?("+") && line.include?("public ") &&
       index > 0 && !lines[index - 1].include?("///")
      message("Consider adding documentation comments for public APIs in #{file}")
      break
    end
  end
end

# ------------------------------------------------------------------------------
# 5. Package and Dependency Checks
# ------------------------------------------------------------------------------

# Warn about Package.swift changes
package_changes = git.modified_files.select { |f| f.include?('Package.swift') }
if package_changes.any?
  warn("📦 Package.swift was modified. Make sure dependencies are necessary and versions are pinned appropriately.")
end

# Check for Podfile/Cartfile changes (we use SPM)
if git.modified_files.include?("Podfile") || git.modified_files.include?("Cartfile")
  fail("❌ This project uses Swift Package Manager. Please don't add CocoaPods or Carthage dependencies.")
end

# ------------------------------------------------------------------------------
# 6. Specific File Type Checks
# ------------------------------------------------------------------------------

# Check for large asset files
large_files = git.added_files.select do |file|
  File.exist?(file) && File.size(file) > 1_000_000 # 1MB
end

if large_files.any?
  warn("⚠️ Large files detected (>1MB): #{large_files.join(', ')}. Consider optimizing or using Git LFS.")
end

# Warn about changes to Tuist configuration
tuist_changes = git.modified_files.select { |f| f.include?('Tuist/') || f == 'Project.swift' }
if tuist_changes.any?
  message("⚙️ Tuist configuration was modified. Make sure to run `tuist generate` after pulling these changes.")
end

# ------------------------------------------------------------------------------
# 7. Positive Reinforcement
# ------------------------------------------------------------------------------

# Celebrate clean PRs
if git.lines_of_code < 200 && added_test_files.any?
  message("✨ Great job! This PR is well-scoped and includes tests!")
end

# Celebrate documentation
if git.modified_files.any? { |f| f.start_with?('Docs/') }
  message("📖 Thanks for improving documentation!")
end

# ------------------------------------------------------------------------------
# 8. Summary
# ------------------------------------------------------------------------------

message("**PR Summary:**")
message("- 📝 #{git.lines_of_code} lines changed")
message("- 📁 #{git.added_files.count} files added")
message("- ✏️ #{git.modified_files.count} files modified")
message("- 🗑 #{git.deleted_files.count} files deleted")
