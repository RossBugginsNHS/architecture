#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'

# Script to update the requirement_master field in SAF markdown files
# from the master_safs.yml file
#
# Usage:
#   ruby scripts/update_safs_from_master.rb
#
# The script:
#   1. Reads master_safs.yml to get the master requirements
#   2. Finds all SAF markdown files in _safs directory
#   3. Updates the requirement_master field in each file's front matter
#   4. Preserves all other content and formatting

MASTER_FILE = 'master_safs.yml'
SAFS_DIR = '_safs'

def load_master_safs
  unless File.exist?(MASTER_FILE)
    puts "Error: #{MASTER_FILE} not found. Run parse_master_safs.rb first."
    exit 1
  end

  data = YAML.load_file(MASTER_FILE)
  
  # Convert to hash for easy lookup by code
  master_safs = {}
  data['safs'].each do |saf|
    master_safs[saf['code']] = saf['requirement']
  end
  
  master_safs
end

def find_saf_files
  # Find all .md files in _safs directory recursively
  Dir.glob("#{SAFS_DIR}/**/*.md")
end

def extract_saf_code_from_filename(filepath)
  # Extract code from filename, e.g., _safs/ru/ru01.md -> RU01
  filename = File.basename(filepath, '.md')
  filename.upcase
end

def emphasize_modal_verbs(text)
  # Replace modal verbs with bold emphasis
  # Use word boundaries to avoid replacing parts of words
  result = text.dup
  
  # Replace "should" with "**SHOULD**" (case-insensitive)
  result.gsub!(/\bshould\b/i, '**SHOULD**')
  
  # Replace "must" with "**MUST**" (case-insensitive)
  result.gsub!(/\bmust\b/i, '**MUST**')
  
  result
end

def update_saf_file(filepath, new_requirement_master)
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
  
  # Emphasize modal verbs in the requirement_master
  emphasized_requirement = emphasize_modal_verbs(new_requirement_master)
  
  # Update the requirement_master field
  front_matter['requirement_master'] = emphasized_requirement
  
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
  puts "Loading master SAF requirements from #{MASTER_FILE}..."
  master_safs = load_master_safs
  puts "Loaded #{master_safs.length} master SAF requirements"
  
  puts "\nFinding SAF markdown files in #{SAFS_DIR}..."
  saf_files = find_saf_files
  puts "Found #{saf_files.length} SAF files"
  
  updated_count = 0
  not_found_count = 0
  error_count = 0
  
  puts "\nUpdating SAF files..."
  saf_files.each do |filepath|
    code = extract_saf_code_from_filename(filepath)
    
    if master_safs.key?(code)
      print "  Updating #{code} (#{filepath})... "
      
      if update_saf_file(filepath, master_safs[code])
        puts "✓"
        updated_count += 1
      else
        puts "✗"
        error_count += 1
      end
    else
      puts "  Warning: No master requirement found for #{code} (#{filepath})"
      not_found_count += 1
    end
  end
  
  puts "\n" + "="*60
  puts "Summary:"
  puts "  Successfully updated: #{updated_count}"
  puts "  Not found in master:  #{not_found_count}"
  puts "  Errors:               #{error_count}"
  puts "="*60
  
  if not_found_count > 0
    puts "\nNote: Files not found in master are likely deprecated SAFs"
  end
end

main if __FILE__ == $PROGRAM_NAME
