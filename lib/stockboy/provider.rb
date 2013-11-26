require 'logger'
require 'active_model/errors'
require 'active_model/naming'
require 'stockboy/dsl'

module Stockboy #:nodoc:

  # Provider objects handle the connection and capture of data from remote
  # sources. Stockboy::Providers::Provider is an abstract class for
  # implementing different providers.
  #
  # == Interface
  #
  # A provider object must implement the following methods:
  #
  # [validate]  Verify the parameters required for connection
  # [fetch_data] Populate @data from source
  #
  class Provider
    extend ActiveModel::Naming # Required by ActiveModel::Errors

    def self.logger
      Logger.new(STDERR)
    end

    attr_reader :logger

    # See ActiveModel::Errors
    attr_reader :errors

    attr_reader :data_time

    def inspect
    "#<#{self.class}:#{self.object_id} data_size=#{@data_size or 'nil'} errors=#{@errors.full_messages}>"
    end

    # Initialize should be called by subclasses to set up dependencies
    def initialize(opts={}, &block)
      @logger = opts.delete(:logger) || self.class.logger
      clear
      # TODO: register callback for success?
      # TODO: register callback for failures
    end

    # Return provided data as an array of key-value hashes
    def data
      return @data if @data
      fetch_data if validate_config?
      @data
    end

    # Reset received data
    def clear
      @data = nil
      @data_time = nil
      @data_size = nil
      @errors = ActiveModel::Errors.new(self)
      true
    end
    alias :reset :clear

    # Reload provided data
    def reload
      clear
      fetch_data if validate_config?
      @data
    end

    ## Returns true if valid
    def valid?
      validate
    end

    private

    # Abstract method to be implemented by subclasses
    #
    def fetch_data
      raise NoMethodError, "#{self.class}#fetch_data needs implementation"
    end

    # Abstract method to be implemented by subclasses
    #
    # Use errors.add(:attribute, "Message") provided by ActiveModel
    # for validating required provider parameters before attempting
    # to make connections and retrieve data.
    #
    def validate
      raise NoMethodError, "#{self.class}#fetch_data needs implementation"
    end

    def validate_config?
      unless validation = valid?
        logger.error do
          "Invalid #{self.class} provider configuration: #{errors.full_messages}"
        end
      end
      validation
    end

    # :nodoc:
    # Required by ActiveModel::Errors
    def read_attribute_for_validation(attr) # :nodoc:
      send(attr)
    end

    # :nodoc:
    # Required by ActiveModel::Errors
    def self.human_attribute_name(attr, options = {}) # :nodoc:
      attr
    end

    # :nodoc:
    # Required by ActiveModel::Errors
    def self.lookup_ancestors # :nodoc:
      [self]
    end

    # When picking files from a list you can supply :first or :last to the
    # provider's pick option or else a block that can reduce to a single
    # value, like:
    #
    #     proc do |best_match, current_match|
    #       current_match.better_than?(best_match) ?
    #           current_match : best_match
    #     end
    #
    def pick_from(list, &block)
      case @pick
      when Symbol
        list.public_send @pick
      when Proc
        list.reduce &@pick
      end
    end

  end
end
