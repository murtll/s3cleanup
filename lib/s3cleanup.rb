require 'aws-sdk'
require 'parser/pinnings'
require 'parser/repos'
require 'terminal-table'

def print_table(title = "", data)
  puts Terminal::Table.new(
    title:    title,
    headings: data.map(&:keys).uniq.flatten,
    rows:     data.map(&:values)
  )
end
