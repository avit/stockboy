require 'stockboy/provider'
require 'net/imap'
require 'mail'

module Stockboy::Providers
  class IMAP < Stockboy::Provider

    OPTIONS = [:host,
               :username,
               :password,
               :mailbox,
               :subject,
               :from,
               :since,
               :search,
               :attachment,
               :pick]
    attr_accessor *OPTIONS
    alias :newer_than :since
    alias :newer_than= :since=

    class DSL
      include Stockboy::DSL
      dsl_attrs *OPTIONS
      alias :newer_than :since
      alias :newer_than= :since=
    end

    class << self
      def imap_client
        @imap_client ||= Net::IMAP
      end
      attr_writer :imap_client
    end

    def initialize(opts={}, &block)
      super(opts, &block)
      @host         = opts[:host]
      @username     = opts[:username]
      @password     = opts[:password]
      @mailbox      = opts[:mailbox]
      @subject      = opts[:subject]
      @from         = opts[:from]
      @since        = opts[:since]
      @search       = opts[:search]
      @attachment   = opts[:attachment]
      @pick         = opts[:pick] || :last
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def validate
      errors.add_on_blank [:host, :username, :password]
      errors.empty?
    end

    def fetch_data
      unless (imap_message_keys = fetch_imap_message_keys).empty?
        mail = ::Mail.new(client.fetch(pick_from(imap_message_keys),'RFC822')[0].attr['RFC822'])
        if part = mail.attachments.detect { |part| validate_attachment(part) }
          @data = part.decoded
          @data_time = normalize_imap_datetime(mail.date)
        end
      end
      !@data.nil?
    rescue ::Net::IMAP::Error => e
      errors.add :response, "IMAP connection error"
    ensure
      client.disconnect
      @client = nil
    end

    def fetch_imap_message_keys
      client.sort(['DATE'], search_keys, 'UTF-8')
    end

    def validate_attachment(part)
      case attachment
      when String
        part.filename == attachment
      when Regexp
        part.filename =~ attachment
      else
        true
      end
    end

    def search_keys
      keys = []
      keys += ['SUBJECT', subject]  if subject
      keys += ['FROM', from]        if from
      keys += ['SINCE', date_format(since)] if since
      keys += search if search
      keys
    end

    def date_format(value)
      case value
      when Date, Time, DateTime
        value.strftime('%v')
      when Numeric
        Time.at(value).strftime('%v')
      when String
        return value if value =~ /\A\d{2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\d{2}\z/i
        Date.parse(value).strftime('%v')
      end
    end

    def client
      @client ||= ::Net::IMAP.new(host).tap do |i|
        i.login(username, password)
        i.examine(mailbox)
      end
    end

    # If activesupport is loaded, it mucks with DateTime#to_time to return
    # self when it has a utc_offset. Handle both to always return a Time.utc.
    #
    def normalize_imap_datetime(datetime)
      datetime.respond_to?(:getutc) ?
        datetime.getutc.to_time : datetime.to_time.utc
    end
  end
end
