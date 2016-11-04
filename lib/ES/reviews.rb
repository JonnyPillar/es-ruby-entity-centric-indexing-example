module ES
  class Reviews
    class << self
      REVIEW_INDEX = 'reviews'.freeze
      REVIEW_TYPE = 'review'.freeze
      REVIEWS_PER_PAGE = 5000
      MAX_TIME_TO_PROCESS_SCROLL_PAGE = '1m'.freeze
      PRESERVE_ORDER = true

      def get(client)
        ES::Scan.scan(
          client,
          index: REVIEW_INDEX,
          doc_type: REVIEW_TYPE,
          query: events_query,
          size: REVIEWS_PER_PAGE,
          scroll: MAX_TIME_TO_PROCESS_SCROLL_PAGE,
          preserve_order: PRESERVE_ORDER
        ) do |doc|
          yield doc
        end
      end

      private

      def events_query
        {
          "query": {
            "bool": {
              "mustNot": [
                {
                  "term": {
                    'rating': 0
                  }
                }
              ]
            }
          },
          "sort": [
            {
              "reviewerId": {
                "order": 'asc'
              }
            },
            {
              "date": {
                "order": 'asc'
              }
            }
          ]
        }
      end
    end
  end
end
