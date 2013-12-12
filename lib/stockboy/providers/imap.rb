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
    dsl_attr :attachment, alias: :file_name

    # @macro file_size_options
    dsl_attr :file_smaller, alias: :smaller_than
    dsl_attr :file_larger,  alias: :larger_than

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
      @file_smaller = opts[:file_smaller]
      @file_larger  = opts[:file_larger]
      @pick         = opts[:pick] || :last
      DSL.new(self).instance_eval(&block) if block_given?
    end

    def client
      raise(ArgumentError, "no block given") unless block_given?
      first_connection = @open_client.nil?
      if first_connection
        @open_client = ::Net::IMAP.new(host)
        @open_client.login(username, password)
        @open_client.examine(mailbox)
      end
      yield @open_client
    rescue ::Net::IMAP::Error => e
      errors.add :response, "IMAP connection error"
    ensure
      if first_connection
        @open_client.disconnect
        @open_client = nil
      end
    end

    def delete_data
      raise Stockboy::OutOfSequence, "must confirm #matching_message or calling #data" unless picked_matching_message?

      logger.info "Deleting message #{username}:#{host} message_uid: #{matching_message}"
      client do |imap|
        imap.uid_store(matching_message, "+FLAGS", [:Deleted])
        imap.expunge
      end
    end

    def matching_message
      return @matching_message if @matching_message
      keys = fetch_imap_message_keys
      @matching_message = pick_from(keys) unless keys.empty?
    end

    def clear
      super
      @matching_message = nil
      @data_time = nil
      @data_size = nil
    end

    private

    def fetch_data
      client do |imap|
        return false unless matching_message
        mail = ::Mail.new(imap.fetch(matching_message, 'RFC822')[0].attr['RFC822'])
        if part = mail.attachments.detect { |part| validate_attachment(part) }
          validate_file(part.decoded)
          if valid?
            logger.info "Getting file from #{username}:#{host} message_uid #{matching_message}"
            @data = part.decoded
            @data_time = normalize_imap_datetime(mail.date)
            logger.info "Got file from #{username}:#{host} message_uid #{matching_message}"
          end
        end
      end
      !@data.nil?
    end

    def validate
      errors.add_on_blank [:host, :username, :password]
      errors.empty?
    end

    def fetch_imap_message_keys
      client { |imap| imap.sort(['DATE'], search_keys, 'UTF-8') }
    end

    def picked_matching_message?
      !!@matching_message
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
      keys.concat ['SUBJECT', subject]  if subject
      keys.concat ['FROM', from]        if from
      keys.concat ['SINCE', date_format(since)] if since
      keys.concat search if search
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

    def validate_file(data_file)
      return errors.add :response, "No matching attachments" unless data_file
      validate_file_smaller(data_file)
      validate_file_larger(data_file)
    end

    def validate_file_smaller(data_file)
      @data_size ||= data_file.bytesize
      if file_smaller && @data_size > file_smaller
        errors.add :response, "File size larger than #{file_smaller}"
      end
    end

    def validate_file_larger(data_file)
      @data_size ||= data_file.bytesize
      if file_larger && @data_size < file_larger
        errors.add :response, "File size smaller than #{file_larger}"
      end
    end
  end

end
