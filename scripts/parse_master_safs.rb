#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'yaml'

# Script to parse the NHS Architecture SAF requirements from the master website
# and output them as a YAML file
#
# Usage:
#   ruby scripts/parse_master_safs.rb
#
# Output:
#   Creates master_safs.yml with all SAF codes and requirements from the master site
#
# The script:
#   1. Fetches the requirements page from the NHS Architecture website
#   2. Parses the HTML table structure to extract SAF codes and requirements
#   3. Cleans up HTML tags and entities
#   4. Outputs a YAML file with the structured data

URL = 'https://architecture.digital.nhs.uk/solution-architecture-framework/requirements'

def fetch_webpage(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    response.body
  else
    puts "Error fetching webpage: HTTP #{response.code}"
    exit 1
  end
end

def parse_safs(html_content)
  safs = []
  
  # The webpage uses HTML table structure with class "nhsuk-table__cell"
  # Pattern: <td class="nhsuk-table__cell">CODE</td>
  #          <td class="nhsuk-table__cell">REQUIREMENT</td>
  
  # Extract all table cells
  cells = html_content.scan(/<td[^>]*class="nhsuk-table__cell"[^>]*>(.*?)<\/td>/m)
  
  # Process pairs of cells (code, requirement)
  i = 0
  while i < cells.length - 1
    code_cell = cells[i][0].strip
    requirement_cell = cells[i + 1][0].strip
    
    # Check if this looks like a SAF code (1-2 letters followed by 2 digits)
    if code_cell.match?(/^[A-Z]{1,2}\d{2}$/)
      code = code_cell
      
      # Clean up the requirement text
      requirement = clean_html(requirement_cell)
      
      # Special handling for RU03 - capture the tables that follow
      if code == 'RU03'
        requirement = handle_ru03_tables(html_content, requirement)
      end
      
      # Skip if requirement is empty
      unless requirement.empty?
        safs << {
          'code' => code,
          'requirement' => requirement
        }
      end
      
      i += 2  # Move to next pair
    else
      i += 1  # Move to next cell
    end
  end
  
  safs.uniq { |s| s['code'] }
end

def handle_ru03_tables(html_content, base_requirement)
  # RU03 has two tables following it: one for capabilities and one for shared services
  # Extract the section after RU03
  ru03_section = html_content[/RU03.*?<h4>Shared Services<\/h4>.*?<\/table>/m]
  
  return base_requirement unless ru03_section
  
  result = base_requirement.dup
  
  # Extract first table (Capabilities)
  first_table = ru03_section[/<table[^>]*>.*?<\/table>/m]
  if first_table
    # Skip the header row and extract data rows
    rows = first_table.scan(/<tr[^>]*class="nhsuk-table__row"[^>]*>.*?<\/tr>/m)
    
    if rows.any?
      result += "\n\n**Capabilities:**\n\n"
      result += "| Capability | Reuse |\n"
      result += "|------------|-------|\n"
      
      rows.each do |row|
        cells = row.scan(/<td[^>]*class="nhsuk-table__cell"[^>]*>(.*?)<\/td>/m)
        if cells.length == 2
          capability = clean_html(cells[0][0])
          reuse = clean_html(cells[1][0])
          result += "| #{capability} | #{reuse} |\n"
        end
      end
    end
  end
  
  # Extract second table (Shared Services)
  shared_services_section = html_content[/<h4>Shared Services<\/h4>.*?<\/table>/m]
  if shared_services_section
    rows = shared_services_section.scan(/<tr[^>]*class="nhsuk-table__row"[^>]*>.*?<\/tr>/m)
    
    if rows.any?
      result += "\n**Shared Services:**\n\n"
      result += "| Capability | Reuse |\n"
      result += "|------------|-------|\n"
      
      rows.each do |row|
        cells = row.scan(/<td[^>]*class="nhsuk-table__cell"[^>]*>(.*?)<\/td>/m)
        if cells.length == 2
          capability = clean_html(cells[0][0])
          reuse = clean_html(cells[1][0])
          result += "| #{capability} | #{reuse} |\n"
        end
      end
    end
  end
  
  result
end

def clean_html(text)
  # Convert HTML to Markdown format, preserving formatting
  result = text.dup
  
  # Convert bold tags
  result.gsub!(/<strong[^>]*>(.*?)<\/strong>/m) { "**#{$1.strip}**" }
  result.gsub!(/<b[^>]*>(.*?)<\/b>/m) { "**#{$1.strip}**" }
  
  # Convert italic tags
  result.gsub!(/<em[^>]*>(.*?)<\/em>/m) { "*#{$1.strip}*" }
  result.gsub!(/<i[^>]*>(.*?)<\/i>/m) { "*#{$1.strip}*" }
  
  # Convert code tags
  result.gsub!(/<code[^>]*>(.*?)<\/code>/m) { "`#{$1.strip}`" }
  
  # Convert links - handle both relative and absolute URLs
  result.gsub!(/<a[^>]*href=["']([^"']+)["'][^>]*>(.*?)<\/a>/m) do
    url = $1
    text = $2.strip
    
    # Convert relative URLs to absolute URLs
    if url.start_with?('../', '/')
      # Remove leading ../ and convert to absolute URL
      clean_url = url.gsub(/^\.\.\//, '')
      clean_url = clean_url.sub(/^\//, '') if clean_url.start_with?('/')
      absolute_url = "https://architecture.digital.nhs.uk/#{clean_url}"
      "[#{text}](#{absolute_url})"
    else
      "[#{text}](#{url})"
    end
  end
  
  # Convert unordered list items to markdown bullets
  # First, extract list items with their content
  list_items = []
  result.gsub!(/<li[^>]*>(.*?)<\/li>/m) do
    item_content = $1.strip
    list_items << item_content
    "__LIST_ITEM_#{list_items.length - 1}__"
  end
  
  # Remove ul/ol tags
  result.gsub!(/<\/?ul[^>]*>/, '')
  result.gsub!(/<\/?ol[^>]*>/, '')
  
  # Convert paragraphs - add double newline for separation
  result.gsub!(/<p[^>]*>(.*?)<\/p>/m) { "\n\n#{$1.strip}" }
  
  # Convert line breaks
  result.gsub!(/<br\s*\/?>/i, "\n")
  
  # Remove any remaining HTML tags
  result.gsub!(/<[^>]+>/, '')
  
  # Restore list items as markdown bullets
  list_items.each_with_index do |item, index|
    result.gsub!("__LIST_ITEM_#{index}__", "\n- #{item}")
  end
  
  # Decode HTML entities
  result.gsub!(/&amp;/, '&')
  result.gsub!(/&lt;/, '<')
  result.gsub!(/&gt;/, '>')
  result.gsub!(/&quot;/, '"')
  result.gsub!(/&#39;/, "'")
  result.gsub!(/&nbsp;/, ' ')
  
  # Clean up excessive whitespace while preserving intentional line breaks
  result.gsub!(/[ \t]+/, ' ')      # Multiple spaces/tabs to single space
  result.gsub!(/\n[ \t]+/, "\n")   # Remove leading space on new lines
  result.gsub!(/[ \t]+\n/, "\n")   # Remove trailing space before newlines
  result.gsub!(/\n{3,}/, "\n\n")   # Max 2 consecutive newlines
  
  # Remove blank lines between consecutive bullet points
  # Keep replacing until no more blank lines exist between bullets
  while result.gsub!(/(\n- [^\n]+)\n\n(?=- )/, "\\1\n")
    # Continue iterating until all blank lines between bullets are removed
  end
  
  result.strip
end

def main
  puts "Fetching SAF requirements from #{URL}..."
  html_content = fetch_webpage(URL)
  
  puts "Parsing SAF requirements..."
  safs = parse_safs(html_content)
  
  if safs.empty?
    puts "Warning: No SAFs were parsed. The webpage format may have changed."
    exit 1
  end
  
  # Sort by code
  safs.sort_by! { |saf| saf['code'] }
  
  # Output to YAML file
  output_file = 'master_safs.yml'
  File.write(output_file, { 'safs' => safs }.to_yaml)
  
  puts "Successfully parsed #{safs.length} SAFs"
  puts "Output written to: #{output_file}"
  
  # Display summary
  puts "\nSAF Codes found:"
  safs.group_by { |s| s['code'][0..1] }.each do |prefix, group|
    puts "  #{prefix}: #{group.map { |s| s['code'] }.join(', ')}"
  end
end

main if __FILE__ == $PROGRAM_NAME
