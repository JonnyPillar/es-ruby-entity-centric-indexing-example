module Elastic
  class ReviewActionGenerator
    REVIEW_UPDATE_SCRIPT_NAME = 'ReviewerProfileUpdater'.freeze
    REVIEW_UPDATE_SCRIPT_MODE = 'fullBuild'.freeze
    PROFILE_INDEX = 'profiles'.freeze
    PROFILE_TYPE = 'profile'.freeze

    def initialize
      @current_reviewer_id = ''
      @reviewer_events = []
      @num_docs_processed = 0
    end

    def process(reviews)
      reviews.map do |review|
        review_data = review['_source']
        reviewer_id = review_data['reviewerId']

        unless reviewer_id == @current_reviewer_id
          push_reviewer_action

          @reviewer_events = []
          @current_reviewer_id = reviewer_id
        end

        @reviewer_events.push(review_data)
        @num_docs_processed += 1
      end

      puts "Processed #{@num_docs_processed} docs"
    end

    def actions
      @actions ||= []
    end

    private

    def push_reviewer_action
      actions.push(reviewer_upsert_action) unless @reviewer_events.nil?
    end

    def reviewer_upsert_action
      {
        update: {
          _index: PROFILE_INDEX,
          _type: PROFILE_TYPE,
          _id: @current_reviewer_id,
          data: {
            script: {
              file: REVIEW_UPDATE_SCRIPT_NAME,
              params: {
                scriptMode: REVIEW_UPDATE_SCRIPT_MODE,
                events: @reviewer_events
              }
            },
            scripted_upsert: true,
            upsert: {}
          }
        }
      }
    end
  end
end
