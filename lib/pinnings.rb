require 'elasticsearch'
require 'diplomat'

def parse_pinnings
  source = ENV.fetch('PINNINGS_SOURCE', 'consul')
  case source
  when 'consul'
    parse_pinnings_consul
  when 'es'
    parse_pinnings_es
  end
end

def parse_pinnings_consul
  table_result = []

  Diplomat.configure do |config|
    config.url = ENV.fetch('CONSUL_URL', 'http://localhost:8500')
  end

  stages = Diplomat::Kv.get('/', keys: true)

  stages.each do |stage|
    result = JSON.parse(Diplomat::Kv.get(stage))
    result['apps_v2'].each do |project, config|
      config.each do |role, params|
        unless params['s3key'].nil?
          table_result.push(params['s3key'])
        end
      end
    end
  end
  table_result
end

def parse_pinnings_es
  table_result = []
  es           = Elasticsearch::Client.new(
    host: ENV.fetch('ELK_URL', 'http://localhost:9200')
  )
  result = es.search index: 'capistrano', scroll: '1h'

  while result['hits']['hits'].size.positive?
    result = begin
      result = es.scroll(scroll_id: result['_scroll_id'], scroll: '5m')
    rescue Faraday::ConnectionFailed
      abort 'error: Elasticsearch scroll failed'
    end

    result['hits']['hits'].each do |doc|
      next unless (depl = doc['_source']['apps_v2'])
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
      print_table("Pinning revisions: #{doc['_source']['stage']}", stage_result)
      table_result += stage_result
    end
  end
  table_result.map { |i| i[:s3key] }
end
