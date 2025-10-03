#!/usr/bin/env ruby
# Reconstruct assessment_examples blocks that lost keys (e.g. only 0,2,4 present)
# Heuristic: treat consecutive bullet/paragraph groups separated by a blank line
# as one score bucket, preserving order. Attach non-dash lines to the previous bullet group.

require 'pathname'

ROOT = Pathname.new(File.dirname(__FILE__)).parent
SAF_DIR = ROOT.join('_safs')

files = Dir.glob(SAF_DIR.join('**', '*.md').to_s)
updated = []

files.each do |path|
  text = File.read(path)
  # Only process if front matter present
  next unless text =~ /\A---\n(.*?\n?)---\n/m
  front = $1
  body_start = Regexp.last_match.end(0)
  body = text[body_start..-1]

  fm_lines = front.lines
  out = []
  i = 0
  while i < fm_lines.length
    line = fm_lines[i]
    if line.strip == 'assessment_examples:'
      # Collect block lines until next top-level key or end
      block = [line]
      i += 1
      while i < fm_lines.length
        l = fm_lines[i]
        break if l.start_with?('#') # comment top-level ignore
        # next top-level key: no leading space, contains ':' (simple heuristic) and not a quoted digit key
        if l =~ /^\S/ && l.include?(':') && l !~ /^'[0-5]':/ && l !~ /^---/ && l !~ /^\S+\s*:\s*\|?$/
          break
        end
        block << l
        i += 1
      end

      # Analyse existing keys inside block
      keys = block.grep(/^  '[0-5]':/)
      if keys.size == 6
        # Keep block as-is
        out.concat(block)
      else
        # Reconstruct
        # Extract all content lines after 'assessment_examples:' ignoring existing (possibly partial) key lines
        content_lines = block[1..-1].reject { |l| l =~ /^  '[0-5]':/ }
        # Normalise line endings
        # Build groups: split on blank line followed by line starting with optional spaces + '- '
        groups = []
        current = []
        content_lines.each_with_index do |cl, idx|
          if cl.strip.empty?
            # Potential group boundary; keep as separator but don't push yet
            if !current.empty? && (idx + 1 < content_lines.length) && content_lines[idx+1].lstrip.start_with?('- ')
              groups << current
              current = []
            else
              current << cl # retain blank line inside group
            end
          else
            # Non blank
            if cl.lstrip.start_with?('- ')
              # If previous line ended a group and current is bullet we continue existing group or start new if current empty
              current << cl
            else
              # Paragraph / continuation -> append to current (if no group started, start one)
              current << cl
            end
          end
        end
        groups << current unless current.empty?

        # If we ended with not enough groups but have a very large first group representing multiple scores collapsed,
        # attempt fallback: split by lines that start with two spaces + '-' AND have two or more consecutive blank lines after.
        if groups.size < 6
          merged = groups.flatten
          # Split by pattern: blank line then bullet
          temp_groups = []
            g = []
            merged.each_with_index do |cl, idx|
              if cl.strip.empty? && idx+1 < merged.length && merged[idx+1].lstrip.start_with?('- ')
                g << cl
                temp_groups << g unless g.empty?
                g = []
              else
                g << cl
              end
            end
            temp_groups << g unless g.empty?
          groups = temp_groups if temp_groups.size >= 6
        end

        # Trim to first six groups / pad if needed
        groups = groups.first(6)
        while groups.size < 6
          groups << ["(placeholder \n)"]
        end

        # Clean groups: remove leading/trailing blank lines and normalise indentation
        cleaned = groups.map do |g|
          arr = g.dup
          arr.shift while arr.first&.strip == ''
            arr.pop while arr.last&.strip == ''
          arr
        end

        out << "assessment_examples:\n"
        cleaned.each_with_index do |g, idx|
          out << "  '#{idx}': |\n"
          g.each do |cl|
            content = cl.gsub(/^\s+/, '') # strip leading spaces
            out << "    #{content.rstrip}\n"
          end
          out << "\n" unless idx == 5
        end
      end
      next # already advanced i inside loop
    else
      out << line
      i += 1
    end
  end

  new_front = out.join
  new_text = "---\n#{new_front}---\n#{body}"
  if new_text != text
    File.write(path, new_text)
    updated << path
  end
end

puts "Reconstructed assessment_examples in #{updated.size} files." if updated.any?
puts 'No changes applied.' if updated.empty?