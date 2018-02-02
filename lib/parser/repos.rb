require 'git'
require 'tinybucket'
require 'yaml'

def with_handler(&block)
  tries ||= 3
  yield
rescue *[Tinybucket::Error::ServiceError, Tinybucket::Error::NotFound] => e
  sleep 30
  retry unless (tries -= 1).zero?
  puts e.message
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

def parse_repos
  Tinybucket.configure do |config|
    config.oauth_token  = ENV['BITBUCKET_OAUTH_TOKEN']
    config.oauth_secret = ENV['BITBUCKET_OAUTH_SECRET']
  end
  bitbucket = Tinybucket.new
  table_result = []
  YAML.load_file(ENV['PROJECTS_CONF']).keys.sort.uniq.map { |i|
    url = Git::Utils.url_ssh_parse(i)
    bitbucket.repo(url.owner, url.slug)
  }.each do |repo|
    repo_result = []
    puts "Parse #{repo.repo_owner}/#{repo.repo_slug}..."
    list_branches(repo).each do |branch|
      next unless commit = head_branch(branch)
      next unless build = build_commit(commit)
      build_name = build.url[/\/job\/([-\w]+)/,1]
      repo_result.push({
        branch: branch.name,
        s3key:  "#{build_name}/#{commit.hash}.tar.gz",
      })
    end
    print_table("HEAD revisions: #{repo.repo_owner}/#{repo.repo_slug}", repo_result)
    table_result += repo_result
  end

  table_result.map { |i| i[:s3key] }
end
