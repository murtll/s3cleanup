require 'elasticsearch'

def parse_pinnings
  table_result = []
  es = Elasticsearch::Client.new(host: ENV.fetch('ELK_URL', 'http://localhost:9200'))
  document = es.search index: 'capistrano', scroll: '1h'
  while result = es.scroll(scroll_id: document['_scroll_id'], scroll: '5m') and not result['hits']['hits'].empty? do
    result['hits']['hits'].each do |document|
      next unless (depl = document['_source']['apps_v2'])
      stage_result = []
      depl.each do |project, roles|
        roles.each do |role, params|
          unless params['s3key'].nil?
            stage_result.push({
              role:    role,
              project: project,
              s3key:   params['s3key'],
            })
          end
        end
      end
      print_table("Pinning revisions: #{document['_source']['stage']}", stage_result)
      table_result += stage_result
    end
  end
  table_result.map { |i| i[:s3key] }
end

