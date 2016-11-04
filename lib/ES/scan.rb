module ES
  class Scan
    class << self
      SCAN_SEARCH_TYPE = 'scan'.freeze
      MAX_TIME_TO_PROCESS_SCROLL_PAGE = '5m'.freeze

      def scan(client, args)
        search = client.search(
          index: args[:index],
          body: args[:query],
          search_type: SCAN_SEARCH_TYPE,
          scroll: MAX_TIME_TO_PROCESS_SCROLL_PAGE,
          size: args[:size]
        )

        while search = client.scroll(scroll_id: search['_scroll_id'], scroll: MAX_TIME_TO_PROCESS_SCROLL_PAGE) and not search['hits']['hits'].empty? do
          yield search['hits']['hits']
        end
      end
    end
  end
end
