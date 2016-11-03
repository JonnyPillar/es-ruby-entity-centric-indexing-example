require 'elasticsearch'
require 'zip'
require 'csv'

module Import
  class ReviewData
    class << self
      CSV_FILE_LOCATION = '/Users/Fatsoma/Documents/Personal/es-ruby-entity-centric-indexing-example/lib/Import/anonreviews.csv.zip'.freeze
      REVIEW_INDEX = 'reviews'.freeze

      def run
        reset_review_index
        process_csv_file
      end

      private

      def process_csv_file
        actions = []

        Zip::ZipFile.foreach(CSV_FILE_LOCATION) do |entry|
          num_lines = 0
          istream = entry.get_input_stream
          data = istream.read
          csv_rows = CSV.parse(data, col_sep: ',', headers: true)

          csv_rows.map do |row|
            num_lines += 1
            unless num_lines == 1
              actions.push(parse_action(row))

              if actions.length >= 5000
                process_actions(actions)
                actions.slice!(0..(actions.length - 1))
              end
            end
          end

          puts "Number of lines processed #{num_lines}"
        end

        process_actions(actions)
      end

      def process_actions(actions)
        return if actions.empty?

        begin
          client.bulk body: actions
        rescue
          puts 'ERRRROOORRRR'
        end
      end

      def reset_review_index
        client.indices.delete(index: REVIEW_INDEX, ignore: [400, 404])
        client.indices.create(index: REVIEW_INDEX, body: index_settings)
      end

      def parse_action(row)
        {
          index: {
            "_index": REVIEW_INDEX,
            "_type": 'review',
            "data": parse_row(row)
          }
        }
      end

      def parse_row(row)
        {
          'reviewerId': row[0],
          'vendorId': row[1],
          'rating': row[2].to_i,
          'date': row[3]
        }
      end

      def client
        @client ||= Elasticsearch::Client.new(log: true)
      end

      def index_settings
        {
          "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 0
          },
          "mappings": {
            "review": {
              "properties": {
                "reviewerId": {
                  "type": 'string',
                  "index": 'not_analyzed'
                },
                "vendorId": {
                  "type": 'string',
                  "index": 'not_analyzed'
                },
                "date": {
                  "type": 'date',
                  "format": 'yyyy-MM-dd HH:mm'
                },
                "rating": {
                  "type": 'integer'
                }
              }
            }
          }
        }
      end
    end
  end
end
