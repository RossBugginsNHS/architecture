#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'

# Script to sync the requirement field with requirement_master field
# in SAF markdown files
#
# Usage:
#   ruby scripts/sync_requirement_from_master.rb
#
# The script:
#   1. Finds all SAF markdown files in _safs directory
#   2. Copies the content from requirement_master to requirement field
#   3. Preserves all other content and formatting

SAFS_DIR = '_safs'

def find_saf_files
  # Find all .md files in _safs directory recursively
  Dir.glob("#{SAFS_DIR}/**/*.md")
end

def extract_saf_code_from_filename(filepath)
  # Extract code from filename, e.g., _safs/ru/ru01.md -> RU01
  filename = File.basename(filepath, '.md')
  filename.upcase
end

def sync_requirement_field(filepath)
  content = File.read(filepath)
  
  # Check if file has YAML front matter
  unless content.start_with?('---')
    puts "  Warning: #{filepath} doesn't have YAML front matter, skipping"
    return false
  end
  
  # Split content into front matter and body
  parts = content.split(/^---\s*$/, 3)
  
  if parts.length < 3
    puts "  Warning: #{filepath} has malformed front matter, skipping"
    return false
  end
  
  front_matter_text = parts[1]
  body = parts[2]
  
  # Parse the front matter
  begin
    front_matter = YAML.load(front_matter_text)
  rescue => e
    puts "  Error parsing YAML in #{filepath}: #{e.message}"
    return false
  end
  
  # Check if requirement_master exists
  unless front_matter.key?('requirement_master')
    puts "  Warning: #{filepath} doesn't have requirement_master field, skipping"
    return false
  end
  
  # Copy requirement_master to requirement
  front_matter['requirement'] = front_matter['requirement_master']
  
  # Clear requirement_master field after syncing
  front_matter.delete('requirement_master')
  
  # Convert back to YAML
  new_front_matter = front_matter.to_yaml
  
  # Remove the leading "---\n" that to_yaml adds
  new_front_matter = new_front_matter.sub(/^---\n/, '')
  
  # Reconstruct the file
  new_content = "---\n#{new_front_matter}---#{body}"
  
  # Write back to file
  File.write(filepath, new_content)
  
  true
end

def main
  puts "Finding SAF markdown files in #{SAFS_DIR}..."
  saf_files = find_saf_files
  puts "Found #{saf_files.length} SAF files"
  
  updated_count = 0
  skipped_count = 0
  error_count = 0
  
  puts "\nSyncing requirement field from requirement_master..."
  saf_files.each do |filepath|
    code = extract_saf_code_from_filename(filepath)
    print "  Processing #{code} (#{filepath})... "
    
    result = sync_requirement_field(filepath)
    
    if result == true
      puts "✓"
      updated_count += 1
    elsif result == false
      puts "⊘ (skipped)"
      skipped_count += 1
    else
      puts "✗"
      error_count += 1
    end
  end
  
  puts "\n" + "="*60
  puts "Summary:"
  puts "  Successfully synced:  #{updated_count}"
  puts "  Skipped:              #{skipped_count}"
  puts "  Errors:               #{error_count}"
  puts "="*60
end

main if __FILE__ == $PROGRAM_NAME
