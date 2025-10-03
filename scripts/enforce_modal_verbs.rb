#!/usr/bin/env ruby
# Enforces bold uppercase **SHOULD** and **MUST** inside the requirement: | block
# for every SAF file under _safs. Only modifies the requirement multiline scalar
# in the YAML front matter (before the terminating --- line).

require 'pathname'

ROOT = Pathname.new(File.expand_path('..', __dir__))
changed = []

Dir.glob(ROOT.join('_safs','**','*.md')).each do |file|
  content = File.read(file)
  # Split front matter and body
  unless content.start_with?("---\n")
    next
  end
  parts = content.split(/^---\s*$\n/, 3) # leading '', yaml, rest
  # After split: first element may be empty string before first ---
  if parts.length < 3
    next
  end
  yaml_section = parts[1]
  body = parts[2]

  lines = yaml_section.lines
  i = 0
  while i < lines.length
    line = lines[i]
    if line =~ /^requirement:\s*\|/  # start of block scalar
      i += 1
      # Collect requirement block lines until a blank line followed by a key OR end of yaml
      start_idx = i
      while i < lines.length
        nxt = lines[i]
        # Stop if we hit a blank line followed by a potential key OR we hit another top-level key pattern (non-indented alpha and colon)
        if nxt =~ /^\s*$/
          # lookahead
          if i+1 < lines.length && lines[i+1] =~ /^[A-Za-z0-9_]+:/
            break
          end
        elsif nxt =~ /^[A-Za-z0-9_]+:/
          break
        end
        i += 1
      end
      end_idx = i - 1
      if end_idx >= start_idx
        block = lines[start_idx..end_idx].join
        before = block.dup
        # 1. Collapse any run of >=2 asterisks around SHOULD/MUST to exactly **WORD**
        block.gsub!(/\*{2,}\s*(SHOULD|MUST)\s*\*{2,}/i) { "**#{$1.upcase}**" }
        # 2. Remove cases where extra asterisks still linger (e.g. ******SHOULD******)
        block.gsub!(/\*{2,}(\*{2,})(SHOULD|MUST)(\*{2,})\*{2,}/i) { "**#{$2.upcase}**" }
        # 3. Replace standalone should/must not already bolded
        block.gsub!(/(?<!\*)\bshould\b(?!\*)/i, '**SHOULD**')
        block.gsub!(/(?<!\*)\bmust\b(?!\*)/i, '**MUST**')
        # 4. Final normalization: any pattern of more than 2 leading/trailing asterisks -> exactly two
        block.gsub!(/\*{3,}(SHOULD|MUST)\*{3,}/i) { "**#{$1.upcase}**" }
        if block != before
          lines[start_idx..end_idx] = block.lines
          changed << file unless changed.include?(file)
        end
      end
    else
      i += 1
    end
  end
  new_yaml = lines.join
  new_content = ["---", new_yaml, "---", body].join("\n")
  if new_content != content
    File.write(file, new_content)
  end
end

if changed.empty?
  warn "No changes made."
else
  puts "Updated requirement modal verbs in #{changed.size} file(s):"
  changed.each { |f| puts " - #{Pathname.new(f).relative_path_from(ROOT)}" }
end