require 'stockboy/configuration'
require 'stockboy/reader'
require 'json'

module Stockboy::Readers

  # Parse data from JSON into hashes
  #
  class JSON < Stockboy::Reader

    def parse(data)
      ::JSON.parse(data)
    end

  end
end
