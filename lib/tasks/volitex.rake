namespace :volitex do
  desc "Create a new account with an admin user and all default features enabled"
  task :create_account, [:account_name, :email, :password] => :environment do |_t, args|
    account_name = args[:account_name] || "New Account"
    email = args[:email]
    password = args[:password]

    if email.blank? || password.blank?
      puts "Usage: rails volitex:create_account[\"Account Name\",email@example.com,yourpassword]"
      next
    end

    account = Account.create!(name: account_name)

    user = User.create!(
      name: account_name,
      email: email,
      password: password,
      password_confirmation: password
    )
    user.confirm

    AccountUser.create!(account: account, user: user, role: :administrator)

    features = YAML.load_file(Rails.root.join('config/features.yml'))
    features.each do |f|
      account.enable_features(f['name']) if f['enabled']
    end
    account.save!

    puts "✅ Account '#{account_name}' created (ID: #{account.id})"
    puts "✅ Admin user: #{email}"
    puts "✅ Features enabled: #{account.feature_flags}"
  end
end
