require 'aws-sdk'
require 'parser/pinnings'
require 'parser/repos'
require 'terminal-table'

def with_handler(&block)
  tries ||= 3
  yield
rescue *[Tinybucket::Error::ServiceError, Tinybucket::Error::NotFound] => e
  sleep 30
  retry unless (tries -= 1).zero?
  abort e.message
end

def list_branches(repo)
  with_handler { repo.branches.collect }
end

def head_branch(branch)
  with_handler { branch.commits.take(1).first }
end

def build_commit(commit)
  with_handler { commit.build_statuses.collect.sort_by(&:updated_on).last }
end

def print_table(title = "", data)
  puts Terminal::Table.new(
    title:    title,
    headings: data.map(&:keys).uniq.flatten,
    rows:     data.map(&:values)
  )
end
