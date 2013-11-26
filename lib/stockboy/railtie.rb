require 'stockboy'

# When loaded in a Rails project, Stockboy will assume the following defaults:
#
# == Configuration file
#
# If a file under +config/stockboy.rb+ exists, it will be loaded for setting up
# the app-specific configuration options, like paths or registering custom
# readers, filters, or providers.
#
# == Default template load paths
#
# +config/stockboy_jobs+ Will be set up as the default template load path.
# This can be changed in the config file.
#
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
