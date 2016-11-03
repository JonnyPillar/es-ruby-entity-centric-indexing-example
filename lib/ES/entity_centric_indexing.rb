require 'elasticsearch'
require 'json'

module ES
  class EntityCentricIndexing
    def initialize(args)
      @entityIdField = args.entityIdField
      @eventIndexName = args.eventIndexName
      @eventDocType = args.eventDocType
      @eventsPerScrollPage = args.eventsPerScrollPage
      @maxTimeToProcessScrollPage = args.maxTimeToProcessScrollPage
      @preserve_order = true;
      @event_query_file = args.eventQueryFile
      @update_script_file = args.updateScriptFile
      @script_mode = args.updateScriptFile
    end

    def generate_actions
      last_entity_id = ''
      events = []
      numDocsProcessed = 0

      ES::Scan.scan(
        client,
        index: @eventIndexName,
        doc_type: eventDocType,
        query: events_query,
        size: eventsPerScrollPage,
        scroll: maxTimeToProcessScrollPage,
        preserve_order: preserve_order
      ) do
        thisEntityId = doc["_source"][@entityIdField]

        if thisEntityId != last_entity_id
          if events != nil
            get_action(events, last_entity)
          end
          events = []
          last_entity_id = thisEntityId
        end
        events.push(doc["_source"])
        numDocsProcessed += 1
      end
      puts "Processed", numDocsProcessed, "docs"
    end

    def get_action(events, last_entity_id)
      {
        _op_type: 'update',
        _id: last_entity_id,
        scripted_upsert: true,
        # In elasticsearch >=2.0
        script: {
          file: @update_script_file,
          params: {
            scriptMode: @script_mode,
            events: events
          }
        },
        # In elasticsearch <2.0
        # "script": args.update_script_file,
        # "params": {
        #     "scriptMode": args.scriptMode,
        #     "events":list(events)
        # },
        upsert: {
          # Use a blank document because script does all the initialization
        }
      }
    end

    private

    def client
      @client ||= Elasticsearch::Client.new(log: true)
    end

    def events_query
      @events_query ||= json.load(open(@event_query_file))
    end
  end
end
