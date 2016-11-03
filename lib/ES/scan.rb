module ES
  class Scan
    def self.scan(client, args, &block)
      search = client.search index: args[:index], search_type: 'scan', scroll: '5m', size: args[:size]

      while search = client.scroll(scroll_id: search['_scroll_id'], scroll: '5m') and not search['hits']['hits'].empty? do
        yield r['hits']['hits']
      end
    end
  end
end
