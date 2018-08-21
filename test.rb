require 'elasticsearch'
require 'awesome_print'

es = Elasticsearch::Client.new(
  host: 'http://127.0.0.1:9200',
  log:  false
)
document = es.search index: 'capistrano', scroll: '1h'

stages = {}

while result = es.scroll(scroll_id: document['_scroll_id'], scroll: '5m') and not result['hits']['hits'].empty? do
  result['hits']['hits'].each do |doc|
    stages[doc['_id']] = doc
  end
end

File.open('stages_dump.json','w') do |f|
  f.write(stages.to_json)
end

stages.each do |id, data|
  if id == 'test'
    puts "index: #{data['_index']}, type: #{data['_type']}, id: #{data['_id']}"
    es.delete index: data['_index'], type: data['_type'], id: data['_id']
  end
end

###

def with_handler(&block)
  begin
    yield
  rescue Faraday::ConnectionFailed => e
    puts "Faraday::ConnectionFailed: #{e.message}"
  rescue Faraday::TimeoutError => e
    puts "Faraday::TimeoutError: #{e.message}"
  rescue Net::ReadTimeout => e
    puts "Net::ReadTimeout: #{e.message}"
  end
end

def create_document
  with_handler do
    @es.create(
      index: 'capistrano',
      type:  'versions',
      id:    'test',
      body:  { '@timestamp': Time.now.utc.iso8601, test: 'test' }
    )
  end
end

def update_document
  with_handler do
    @es.update(
      index: 'capistrano',
      type:  'versions',
      id:    'test',
      body:  {doc: { '@timestamp': Time.now.utc.iso8601, test: 'test' }}
    )
  end
end

def store
  update_document
rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
  puts e.inspect
  create_document
end

store()
