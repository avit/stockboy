require 'stockboy/providers/imap'

module Stockboy::Providers

  # Helper for building standard IMAP options passed to [::Net::IMAP#search]
  #
  class IMAP::SearchOptions

    # Corresponds to %v mode in +DateTime#strftime+
    VMS_DATE = /\A\d{2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\d{2}\z/i

    OPTION_FORMATS = {
      'BEFORE'     => :date_format,
      'ON'         => :date_format,
      'SINCE'      => :date_format,
      'SENTBEFORE' => :date_format,
      'SENTON'     => :date_format,
      'SENTSINCE'  => :date_format,
      'FLAGGED'    => :boolean_format,
      'UNFLAGGED'  => :boolean_format,
      'SEEN'       => :boolean_format,
      'UNSEEN'     => :boolean_format,
      'ANSWERED'   => :boolean_format,
      'UNANSWERED' => :boolean_format,
      'DELETED'    => :boolean_format,
      'UNDELETED'  => :boolean_format,
      'DRAFT'      => :boolean_format,
      'UNDRAFT'    => :boolean_format,
      'NEW'        => :boolean_format,
      'RECENT'     => :boolean_format,
      'OLD'        => :boolean_format
    }

    # Read options from a hash
    #
    # @param [Hash] options
    #
    def initialize(options={})
      @options = options.each_with_object(Hash.new) do |(k,v), h|
        h[imap_key(k)] = v
      end
    end

    # Return a hash with merged and normalized key strings
    #
    # @example
    #   opt = Stockboy::Providers::IMAP::SearchOptions.new(since: Date.new(2012, 12, 21))
    #   opt.to_hash #=> {"SINCE" => #<Date 2012, 12, 21>}
    #
    def to_hash
      @options
    end

    # Return an array of IMAP search keys
    #
    # @example
    #   opt = Stockboy::Providers::IMAP::SearchOptions.new(since: Date.new(2012, 12, 21))
    #   opt.to_imap #=> ["SINCE", "21-DEC-12"]
    #
    def to_imap
      @options.reduce([]) do |a, pair|
        a.concat imap_pair(pair)
      end
    end

    # Convert a rubyish key to IMAP string key format
    #
    # @param [String, Symbol] key
    # @return [String]
    #
    def imap_key(key)
      key.to_s.upcase.gsub(/[^A-Z]/,'').freeze
    end

    # Format a key-value pair for IMAP, according to the correct type
    #
    # @param [Array] pair
    # @return [Array] pair
    #
    def imap_pair(pair)
      if format = OPTION_FORMATS[pair[0]]
        send(format, pair)
      else
        pair
      end
    end

    # Format a key-value pair for IMAP date keys (e.g. SINCE, ON, BEFORE)
    #
    # @param [Array] pair
    # @return [Array] pair
    #
    def date_format(pair)
      pair[1] = case value = pair[1]
      when Date, Time, DateTime
        value.strftime('%v')
      when Numeric
        Time.at(value).strftime('%v')
      when String
        value =~ VMS_DATE ? value : Date.parse(value).strftime('%v')
      end
      pair
    end

    # Format a key-value pair for setting true/false on IMAP keys (e.g. DELETED)
    #
    # @param [Array] pair
    # @return [Array] pair
    #
    def boolean_format(pair)
      return [] unless pair[1] == true || pair[1] == false

      if pair[1]
        [pair[0]]
      else
        ['NOT', pair[0]]
      end
    end

  end
end
