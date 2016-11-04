module ES
  class Scan
    def self.scan(client, args, &block)
      search = client.search(
        index: args[:index],
        # doc_type: args[:doc_type],
        body: args[:query],
        search_type: 'scan',
        scroll: '5m',
        size: args[:size],
        # preserve_order: args[:preserve_order]
      )

      while search = client.scroll(scroll_id: search['_scroll_id'], scroll: '5m') and not search['hits']['hits'].empty? do
        yield search['hits']['hits']
      end
    end
  end
end
