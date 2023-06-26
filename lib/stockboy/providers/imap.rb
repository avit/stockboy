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
    require_relative 'imap/search_options'

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
      @open_client  = nil
    end

    # Direct access to the configured +Net::IMAP+ connection
    #
    # @example
    #   provider.client do |imap|
    #     imap.search("FLAGGED")
    #   end
    #
    def client
      raise(ArgumentError, "no block given") unless block_given?
      first_connection = @open_client.nil?
      if first_connection
        @open_client = ::Net::IMAP.new(host)
        @open_client.starttls
        @open_client.login(username, password)
        @open_client.examine(mailbox)
      end
      yield @open_client
    rescue ::Net::IMAP::Error
      errors << "IMAP connection error"
    ensure
      if first_connection && @open_client
        @open_client.disconnect
        @open_client = nil
      end
    end

    # Purge the email from the mailbox corresponding to the [#message_key]
    #
    # This can only be called after selecting the message_key to confirm the
    # selected item, or after fetching the data.
    #
    def delete_data
      picked_message_key? or raise Stockboy::OutOfSequence,
        "must confirm #message_key or calling #data"

      client do |imap|
        logger.info "Deleting message #{inspect_message_key}"
        imap.uid_store(message_key, "+FLAGS", [:Deleted])
        imap.expunge
      end
    end

    # IMAP message id for the email that contains the selected data to process
    #
    def message_key
      return @message_key if @message_key
      message_ids = find_messages(default_search_options)
      @message_key = pick_from(message_ids) unless message_ids.empty?
    end

    # Clear received data and allow for selecting a new item from the server
    #
    def clear
      super
      @message_key = nil
      @data_time = nil
      @data_size = nil
    end

    # Search the selected mailbox for matching messages
    #
    # By default, the configured options are used,
    # @param [Hash, Array, String] options
    #   Override default configured search options
    #
    # @example
    #   provider.find_messages(subject: "Daily Report", before: Date.today)
    #   provider.find_messages(["SUBJECT", "Daily Report", "BEFORE", "21-DEC-12"])
    #   provider.find_messages("FLAGGED BEFORE 21-DEC-12")
    #
    def find_messages(options=nil)
      client { |imap| imap.sort(['DATE'], search_keys(options), 'UTF-8') }
    end

    # Normalize a hash of search options into an array of IMAP search keys
    #
    # @param [Hash] options If none are given, the configured options are used
    # @return [Array]
    #
    def search_keys(options=nil)
      case options
      when Array, String then options
      else SearchOptions.new(options || default_search_options).to_imap
      end
    end

    def default_search_options
      {subject: subject, from: from, since: since}.reject { |k,v| v.nil? }
    end

    private

    def fetch_data
      client do |imap|
        open_message(message_key) do |mail|
          open_attachment(mail) do |part|
            logger.debug "Getting file from #{inspect_message_key}"
            @data = part
            @data_time = normalize_imap_datetime(mail.date)
            logger.debug "Got file from #{inspect_message_key}"
          end
        end
      end
      !@data.nil?
    end

    def open_message(id)
      return unless id
      client do |imap|
        imap_message = imap.fetch(id, 'RFC822').first or return
        mail = ::Mail.new(imap_message.attr['RFC822'])
        yield mail if block_given?
        mail
      end
    end

    def open_attachment(mail)
      file = mail.attachments.detect { |part| validate_attachment(part) }
      validate_file(file) if file or return
      yield file.decoded if valid?
      file
    end

    def validate
      errors << "host must be specified" if host.blank?
      errors << "username must be specified" if username.blank?
      errors << "password must be specified" if password.blank?
      errors.empty?
    end

    def picked_message_key?
      !!@message_key
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

    # If activesupport is loaded, it mucks with DateTime#to_time to return
    # self when it has a utc_offset. Handle both to always return a Time.utc.
    #
    def normalize_imap_datetime(datetime)
      datetime.respond_to?(:getutc) ?
        datetime.getutc.to_time : datetime.to_time.utc
    end

    def validate_file(data_file)
      return errors << "No matching attachments" unless data_file
      validate_file_smaller(data_file)
      validate_file_larger(data_file)
    end

    def validate_file_smaller(data_file)
      read_data_size(data_file)
      if file_smaller && data_size > file_smaller
        errors << "File size larger than #{file_smaller}"
      end
    end

    def validate_file_larger(data_file)
      read_data_size(data_file)
      if file_larger && data_size < file_larger
        errors << "File size smaller than #{file_larger}"
      end
    end

    def read_data_size(data_file)
      @data_size ||= data_file.body.raw_source.bytesize
    end

    def inspect_message_key
      "#{username}:#{host} message_uid #{message_key}"
    end
  end

end
