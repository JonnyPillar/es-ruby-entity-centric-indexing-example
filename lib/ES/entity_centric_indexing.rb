require 'elasticsearch'
require 'json'

module ES
  class EntityCentricIndexing
    def initialize(args)
      @entityIdField = '_id'
      @eventIndexName = 'reviews'
      @eventDocType = 'review'
      @eventsPerScrollPage = 5000
      @maxTimeToProcessScrollPage = '1m'
      @preserve_order = true;
      # @event_query_file = args.eventQueryFile
      @update_script_file = 'ReviewerProfileUpdater'
      @script_mode = "fullBuild"

      # @entityIdField = args.entityIdField
      # @eventIndexName = args.eventIndexName
      # @eventDocType = args.eventDocType
      # @eventsPerScrollPage = args.eventsPerScrollPage
      # @maxTimeToProcessScrollPage = args.maxTimeToProcessScrollPage
      # @preserve_order = true;
      # @event_query_file = args.eventQueryFile
      # @update_script_file = args.updateScriptFile
      # @script_mode = args.updateScriptFile
    end

    def generate_actions
      last_reviewer_id = ''
      events = []
      actions = []
      numDocsProcessed = 0

      ES::Scan.scan(
        client,
        index: @eventIndexName,
        doc_type: @eventDocType,
        query: events_query,
        size: @eventsPerScrollPage,
        scroll: @maxTimeToProcessScrollPage,
        preserve_order: @preserve_order
      ) do |doc|
        doc.map do |item|
          reviewerId = item['_source']['reviewerId']
          if reviewerId != last_reviewer_id
            if events != nil
              actions.push(get_action(events, last_reviewer_id))
            end
            events = []
            last_reviewer_id = reviewerId
          end

          events.push(item["_source"])
          numDocsProcessed += 1
          puts "Processed #{numDocsProcessed} docs"
        end

      end
      puts "Complete Processing #{numDocsProcessed} docs"

      actions.each_slice(5000) do |batch|
        client.bulk body: batch, index: 'profiles', type: 'profile'
        puts "Completed another bulk batch"
      end
    end

    def get_action(events, last_reviewer_id)
      {
        update: {
          _index: 'profiles',
          _type: 'profile',
          _id: last_reviewer_id,
          data: {
            script: {
              # _id: last_reviewer_id,
              file: @update_script_file,
              params: {
                scriptMode: @script_mode,
                events: events
              }
            },
            scripted_upsert: true,
            upsert: {}
          }
        }
      }

      # {
      #   script: {
      #     # _id: last_reviewer_id,
      #     id: @update_script_file,
      #     params: {
      #       scriptMode: @script_mode,
      #       events: events
      #     }
      #   },
      #   scripted_upsert: true,
      #   upsert: {
      #     # Use a blank document because script does all the initialization
      #   }
      # }
    end

    private

    def client
      @client ||= Elasticsearch::Client.new(log: true)
    end

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
