require 'elasticsearch'
require 'json'

module Elastic
  class EntityCentricIndexing
    def process_reviews
      reviews do |review_page|
        review_generator.process(review_page)
      end

      puts "Processed #{@review_generator.actions.length} Actions"
    end

    def generate_profiles
      Elastic::Indices::Profiles.bulk_upsert(client, actions)
    end

    def actions
      review_generator.actions
    end

    private

    def review_generator
      @review_generator ||= Elastic::ReviewActionGenerator.new
    end

    def reviews
      Elastic::Indices::Reviews.get(client) do |doc|
        yield doc
      end
    end

    def client
      @client ||= Elasticsearch::Client.new(log: true)
    end
  end
end
