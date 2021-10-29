require 'aws-sdk'
require 'pinnings'
require 'terminal-table'

def print_table(title = "", data)
  puts Terminal::Table.new(
    title:    title,
    headings: data.map(&:keys).uniq.flatten,
    rows:     data.map(&:values)
  )
end
