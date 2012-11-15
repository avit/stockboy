require 'stockboy'

class Railtie < Rails::Railtie

  initializer "stockboy.configure_rails_initialization" do
    Stockboy.configure do |config|
      config.template_load_paths = [Rails.root.join('config/stockboy_jobs')]
    end

    if File.exists?(config_file = Rails.root.join("config", "stockboy.rb"))
      require config_file
    end
  end

end
