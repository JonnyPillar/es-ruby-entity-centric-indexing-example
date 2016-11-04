require 'elasticsearch'
require 'json'

module ES
  class EntityCentricIndexing
    def process_reviews
      reviews do |review_page|
        review_generator.process(review_page)
      end

      puts "Processed #{@review_generator.actions.length} Actions"
    end

    def generate_profiles
      ES::Profiles.bulk_upsert(actions)
    end

    private

    def actions
      @actions ||= review_generator.actions
    end

    def review_generator
      @review_generator = ES::ReviewActionGenerator.new
    end

    def reviews
      ES::Reviews.get(client) do |doc|
        yield doc
      end
    end

    def client
      @client ||= Elasticsearch::Client.new(log: true)
    end
  end
end
