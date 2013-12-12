require 'stockboy/providers/imap'

module Stockboy::Providers
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

    def initialize(options={})
      @options = options.each_with_object(Hash.new) do |(k,v), h|
        h[imap_key(k)] = v
      end
    end

    def to_hash
      @options
    end

    def to_imap
      @options.reduce([]) do |a, pair|
        a.concat imap_pair(pair)
      end
    end

    def imap_key(k)
      k.to_s.upcase.gsub(/[^A-Z]/,'').freeze
    end

    def imap_pair(pair)
      if format = OPTION_FORMATS[pair[0]]
        send(format, pair)
      else
        pair
      end
    end

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
