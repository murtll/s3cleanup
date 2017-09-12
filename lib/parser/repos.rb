require 'git'
require 'tinybucket'
require 'yaml'

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
      commit = head_branch(branch)
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
