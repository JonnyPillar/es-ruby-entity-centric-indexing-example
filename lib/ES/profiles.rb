module ES
  class Profiles
    class << self
      PROFILE_INDEX = 'profiles'.freeze
      PROFILE_TYPE = 'profile'.freeze
      BULK_UPLOAD_BATCH_SIZE = 5000

      def bulk_upsert(actions)
        puts 'Starting Profile Upload'

        actions.each_slice(BULK_UPLOAD_BATCH_SIZE) do |batch|
          client.bulk body: batch, index: PROFILE_INDEX, type: PROFILE_TYPE
          puts "Uploaded #{BULK_UPLOAD_BATCH_SIZE}"
        end

        puts 'Completed Uploading ProfileS'
      end
    end
  end
end
