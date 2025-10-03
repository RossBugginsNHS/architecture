#!/usr/bin/env ruby
# Normalise assessment_examples formatting across all SAF markdown files.
# Goals:
#  - Ensure each assessment_examples value uses a YAML literal block (|)
#  - Remove excessive indentation causing markdown code blocks
#  - Preserve bullet list formatting and summary paragraph
#  - Do not alter content text (only whitespace at line starts + blank line separation)

require 'pathname'

ROOT = Pathname.new(File.dirname(__FILE__)).parent
SAF_DIR = ROOT.join('_safs')

files = Dir.glob(SAF_DIR.join('**', '*.md').to_s)

changed = []
files.each do |file|
  original = File.read(file)
  # Split front matter and body
  if original =~ /\A---\n(.*?\n?)---\n/m
    front_matter = $1
    body_start = Regexp.last_match.end(0)
    body = original[body_start..-1]
  else
    next
  end

  fm_lines = front_matter.lines
  in_examples = false
  current_key = nil
  buffer = []
  output_lines = []

  flush_block = lambda do
    next unless current_key
    # Normalise collected lines in buffer
    # Strip leading/trailing blank lines
    while buffer.first&.strip == ''
      buffer.shift
    end
    while buffer.last&.strip == ''
      buffer.pop
    end
    # Remove uniform leading indentation (capture minimal >0)
    min_indent = buffer.reject { |l| l.strip.empty? }.map { |l| l[/^\s*/].size }.min || 0
    normalised = buffer.map { |l| l[min_indent..-1] }
    # Re-indent each non-empty line with 4 spaces so YAML trims baseline -> left aligned content
    rebuilt = normalised.map do |l|
      if l.strip.empty?
        "    \n"
      else
        # Keep bullet or paragraph line as-is after trimming left indent
        "    #{l.rstrip}\n"
      end
    end
    output_lines << "  '#{current_key}': |\n"
    output_lines.concat(rebuilt)
    current_key = nil
    buffer.clear
  end

  fm_lines.each_with_index do |line, idx|
    if !in_examples
      output_lines << line
      in_examples = true if line.strip == 'assessment_examples:'
      next
    end

    # Inside assessment_examples mapping until we hit a non-indented top-level key (no leading spaces) or end
    if in_examples
      # Detect new score key lines like "  '0': |" or "  '0':" (accept without pipe and add one)
      if line =~ /^  '([0-5])':\s*(\|)?\s*$/
        # flush previous
        flush_block.call
        current_key = $1
        # Start collecting new block - we will rebuild with '|'
        next
      elsif line =~ /^\S/ # top-level key => end of assessment_examples
        flush_block.call
        in_examples = false
        output_lines << line
      else
        # Collect content lines belonging to current block (skip pure indentation if no current key yet)
        if current_key
          buffer << line
        else
          # Lines before first key after assessment_examples (unlikely) - just pass through
          output_lines << line
        end
      end
    end
  end
  # End processing: flush any remaining block
  flush_block.call

  new_front_matter = output_lines.join
  new_content = "---\n#{new_front_matter}---\n#{body}"

  if new_content != original
    File.write(file, new_content)
    changed << file
  end
end

puts "Updated #{changed.size} files with normalised assessment_examples formatting." unless changed.empty?
puts 'No files needed changes.' if changed.empty?