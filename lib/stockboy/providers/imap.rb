require 'stockboy/provider'
require 'net/imap'
require 'mail'

module Stockboy::Providers

  # Read data from a file attachment in IMAP email
  #
  # == Job template DSL
  #
  #   provider :imap do
  #     host "imap.example.com"
  #     username "arthur@example.com"
  #     password "424242"
  #     mailbox "INBOX"
  #     subject "Daily Report"
  #     since Date.today
  #     file_name /report-[0-9]+\.csv/
  #   end
  #
  class IMAP < Stockboy::Provider

    # Corresponds to %v mode in +DateTime#strftime+
    VMS_DATE = /\A\d{2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\d{2}\z/i

    # @!group Options

    # Host name or IP address for IMAP server connection
    #
    # @!attribute [rw] host
    # @return [String]
    # @example
    #   host "imap.example.com"
    #
    dsl_attr :host

    # User name for connection credentials
    #
    # @!attribute [rw] username
    # @return [String]
    # @example
    #   username "arthur@example.com"
    #
    dsl_attr :username

    # Password for connection credentials
    #
    # @!attribute [rw] password
    # @return [String]
    # @example
    #   password "424242"
    #
    dsl_attr :password

    # Where to look for email on the server (usually "INBOX")
    #
    # @!attribute [rw] mailbox
    # @return [String]
    # @example
    #   mailbox "INBOX"
    #
    dsl_attr :mailbox

    # Substring to find contained in matching email subject
    #
    # @!attribute [rw] subject
    # @return [String]
    # @example
    #   subject "Daily Report"
    #
    dsl_attr :subject

    # Email address of the sender
    #
    # @!attribute [rw] from
    # @return [String]
    # @example
    #   from "sender+12345@example.com"
    #
    dsl_attr :from

    # Minimum time sent for matching email
    #
    # @!attribute [rw] since
    # @return [String]
    # @example
    #   since Date.today
    #
    dsl_attr :since, alias: :newer_than

    # Key-value tokens for IMAP search options
    #
    # @!attribute [rw] search
    # @return [String]
    # @example
    #   search ['FLAGGED', 'BODY', 'Report attached']
    #
    dsl_attr :search

    # Name or pattern for matching attachment files. First matching attachment
    # is picked, or the first attachment if not specified.
    #
    # @!attribute [rw] attachment
    # @return [String, Regexp]
    # @example
    #   attachment "daily-report.csv"
    #   attachment /daily-report-[0-9]+.csv/
    #
    dsl_attr :attachment

    # Method for choosing which email message to process from potential
    # matches. Default is last by date sent.
    #
    # @!attribute [rw] pick
    # @return [Symbol, Proc]
    # @example
    #   pick :last
    #   pick :first
    #   pick ->(list) {
    #     list.max_by { |msgid| client.fetch(msgid, 'SENTON').to_i }
    #   }
    #
    dsl_attr :pick

    # @!endgroup

    # Library for connection, defaults to +Net::IMAP+
    #
    # @!attribute [rw] imap_client
    #
    def self.imap_client
      @imap_client ||= Net::IMAP
    end
    class << self
      attr_writer :imap_client
    end

    # Initialize a new IMAP reader
    #
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

    # Connection to the configured IMAP server
    #
    # @!attribute [r] client
    # @return [Net::IMAP]
    #
    def client
      @client ||= ::Net::IMAP.new(host).tap do |i|
        i.login(username, password)
        i.examine(mailbox)
      end
    end

    private

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
        return value if value =~ VMS_DATE
        Date.parse(value).strftime('%v')
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
