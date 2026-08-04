namespace :instagram do
  desc 'Fix Instagram contacts that have random Haikunator names instead of their username'
  task fix_contact_names: :environment do
    instagram_inboxes = Inbox.where(channel_type: 'Channel::Instagram')
    fixed_count = 0

    instagram_inboxes.find_each do |inbox|
      inbox.contacts.find_each do |contact|
        username = contact.additional_attributes&.dig('social_instagram_user_name')
        next if username.blank?

        # Check if the name looks like a Haikunator-generated name (e.g. "Morning-Log-337")
        next unless contact.name.match?(/\A[a-z]+-[a-z]+-\d+\z/i)

        contact.update!(name: username)
        fixed_count += 1
        puts "Fixed: #{contact.name} (was random, now @#{username})"
      end
    end

    puts "Done. Fixed #{fixed_count} contacts."
  end
end
