#!/usr/bin/env ruby
# Removes the entire `assessment_examples:` block (and its nested score keys)
# from the YAML front matter of every SAF markdown file under _safs/.
# Leaves everything else untouched.

require 'pathname'

root = Pathname.new(File.dirname(__FILE__)).parent
glob = root.join('_safs', '**', '*.md').to_s
changed = []

Dir.glob(glob).each do |file|
  content = File.read(file)
  # Detect front matter
  unless content.start_with?("---\n")
    next
  end
  parts = content.split(/^---\n/, 3)
  # parts: ["", front, rest] or if malformed skip
  if parts.length < 3
    next
  end
  front = parts[1]
  body = parts[2]

  lines = front.lines
  new_lines = []
  skipping = false
  lines.each_with_index do |line, idx|
    if !skipping && line.strip == 'assessment_examples:'
      skipping = true
      next
    end
    if skipping
      # Continue skipping while line is indented (starts with space) OR blank.
      # Stop when we see a non-indented line that looks like another top-level key.
      if line =~ /^\s*$/
        # still part of the block (blank line inside)
        next
      elsif line.start_with?(' ') || line.start_with?("\t")
        # indented continuation of the block (score keys or their literals)
        next
      else
        # Unindented line -> end of block
        skipping = false
        # Fall through to normal processing of this line (it's the next key)
      end
    end
    new_lines << line unless skipping
  end

  new_front = new_lines.join
  if new_front != front
    File.write(file, "---\n#{new_front}---\n#{body}")
    changed << file
  end
end

puts "Removed assessment_examples from #{changed.size} files." unless changed.empty?
puts 'No assessment_examples blocks found.' if changed.empty?