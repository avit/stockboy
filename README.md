# Stockboy

Stockboy helps you receive and unpack data onto your shelves. You might consider using it to synchronize data exported from external sources, or migrating your own data from legacy systems. (TL;DR, Stockboy is a Ruby [DSL][dsl] for doing [ETL][etl].)

Stockboy was originally developed at [Guestfolio][gf] to help synchronize data from many external systems that export periodic reports in various ways. Each report might vary in:

* Where the data resides: whether a SOAP service, sent to an email mailbox, an FTP server, or simply a file.
* How it's formatted: whether CSV, Excel, XML, JSON, or some other obscure format.
* What fields are included, and how they are named.
* What format the fields are in, e.g. date formats, or whether names are "first, last"
* Selecting and reporting which records are incomplete, or to be added, updated or deleted

The goal of Stockboy is to provide a DSL for keeping these concerns organized and external to your application, letting your app standardize on handling one common interface for the many different sources.


## Usage

Following your defined job template (see below), a Stockboy job will process incoming data. Stockboy leaves it up to your application to decide what to do with it.

    job = Job.define("my_template")

    job.process
    records = job.records            # => Hash of filtered records sorted by filter key.
    other   = job.unfiltered_records # => Array of records not matched by any filter
    all     = job.all_records        # => Array

Yielding results to a block is also supported:

    job.process do |records, unfiltered|
      records[:updated].each  { |r| MyApp::Reservation.create(r.attributes) }
      records[:no_data].each  { |r| log.warn "No data for #{r.id}" }
      unfiltered_records.each { |r| log.info "Skipping: #{r.raw_hash}" }
    end

### Records

Each record exposes both the mapped output value and the source values according to your defined mapping. Typically the mapped fields should correspond to the attributes on your application models. These can be accessed as methods, or converted to a hash.

    record.input["RawEmailField"]                # => "ARTHUR@EXAMPLE.COM"
    record.output.email or record.output[:email] # => "arthur@example.com"

    record.to_hash
    record.attributes
    # => {check_in: #<Time ...>, location_id: 123, first_name: "Arthur", ...}

    record.to_model(MyApp::Reservation) or MyApp::Reservation.new(record.attributes)
    # => #<MyApp::Reservation ...>



## Job Template DSL

Stockboy job templates are defined in Ruby but are simple and abstract enough to be considered more _configuration_ than _code_. They should reside in the [template load path](#stockboy-configuration). Once defined, job templates can be loaded at runtime, and they can be updated separately without needing to restart a long-running process, e.g. Rails or Sidekiq.

Writing a job template requires you to declare three parts:


### 1. How to get it: the provider

    provider :ftp do
      host       "example.com"
      username   "mystore"
      password   "123456"
      file_name  "dailyreport-*.csv"
      file_pick  :first
    end

The provider block describes the connection parameters for finding and fetching data, which is returned as a raw string blob. It can handle some complexity to determine which file to pick from an email attachment or FTP directory, for example.

See: [File][file], [FTP][ftp], [HTTP][http], [IMAP][imap], [SOAP][soap]

[file]: lib/stockboy/providers/file.rb
[ftp]:  lib/stockboy/providers/ftp.rb
[http]: lib/stockboy/providers/http.rb
[imap]: lib/stockboy/providers/imap.rb
[soap]: lib/stockboy/providers/soap.rb


### 2. How to parse it: the reader

    reader :csv do
      headers true
      col_sep "|"
      encoding "Windows-1252"
    end

The reader block describes how to turn the raw string from the provider into a list of fields. At this point we might not have suitable data for import yet, but we can start to work with it.

See: [CSV][csv], [Fixed-Width][fix], [Spreadsheet][xls], [XML][xml]

[csv]: lib/stockboy/readers/csv.rb
[fix]: lib/stockboy/readers/fixed_width.rb
[xls]: lib/stockboy/readers/spreadsheet.rb
[xml]: lib/stockboy/readers/xml.rb


### 3. How to collect it: the attributes

    attributes do
      email       from: 'RawEmailAddress'
      first_name  as: proc{ |r| r['Full-Name'].split(' ').first }
      last_name   as: proc{ |r| r['Full-Name'].split(' ').last }
      birthdate   as: [:time]
      score       as: [:integer, :default_zero]
    end

The attributes block is the main part of the template definition. This describes which fields to extract from the data, and how to represent each value in the record. The desired output attributes are defined by their own name plus two options:

#### :from
When the field name from the source hash doesn't match the desired attribute name, this option should be used to name the correct hash key to read from the source field.

#### :as
By default, attributes are returned as the original raw string data values, but translators can be applied to change the input to any format. Acceptable options include a symbol for a registered translator or any Proc or object responding to `call(source_record)`. These are applied

When using your own proc or callable object, it will be called with the "source record" as input which responds to either:

* Methods representing the mapped attribute names: `{ |r| r.email.downcase }`
* Hash-like indexes for raw input field names: `{ |r| r['RawEmailAddress'].downcase }`

Since the entire record context is passed, you can combine multiple input fields into one attribute. You can also define two attributes that extract different data from the same field.

Translations are applied in order when given as an array. Since translators are designed to handle invalid data, they will catch exceptions and return a `nil` so it's a good idea to have default values at the end of the chain.

#### Built-in translators: 

* [`:boolean`][bool]
  Common true/false strings to `True` or `False` (e.g. '1'/'0' or 't'/'f')
* [`:date`][date]
  ISO-8601 or recognized strings to `Date` (e.g. "2012-12-21" or "Dec 12, 2012")
* [`:decimal`][deci] 
  Numeric strings to `BigDecimal` (e.g. prices)
* [`:default_empty_string`][dest]
  Returns `""` for blank values
* [`:default_nil`][dest]
  Returns `nil` for blank values
* [`:default_zero`][dzer]
  Returns `0` for blank values
* [`:integer`][intg]
  Numeric strings to `Fixnum` integers
* [`:quoted_string`][quot]
  Strings received with surrounding quote characters (`'` or `"`) will have quotes trimmed
* [`:string`][stri]
  Clean strings with leading/trailing whitespace trimmed
* [`:time`][time]
  Time strings to `Time` or `ActiveSupport::TimeWithZone` if loaded
* [`:uk_date`][ukda]
  Date strings from UK format to `Date` (e.g. "DD/MM/YY")
* [`:us_date`][usda]
  Date strings from US format to `Date` (e.g. "MM/DD/YY")

[bool]: lib/stockboy/translators/boolean.rb
[date]: lib/stockboy/translators/date.rb
[deci]: lib/stockboy/translators/decimal.rb
[dest]: lib/stockboy/translators/default_empty_string.rb
[dnil]: lib/stockboy/translators/default_nil.rb
[dzer]: lib/stockboy/translators/default_zero.rb
[intg]: lib/stockboy/translators/integer.rb
[quot]: lib/stockboy/translators/quoted_string.rb
[stri]: lib/stockboy/translators/string.rb
[time]: lib/stockboy/translators/time.rb
[ukda]: lib/stockboy/translators/uk_date.rb
[usda]: lib/stockboy/translators/us_date.rb


### 4. How to select it: filters

Filters are optional, but they are helpful for sorting the data into your workflow, e.g. you may decide to partition records for different handling based on a status field.

    filter(:invalid_email) do |input, _|
      not(input.email.include?('@') or input['EmailAddress'] == '')
    end
    
    filter(:missing_code) do |_, output|
      output.product_code.nil?
    end
    
Filters are applied in the order that they are defined. Any filter that returns `true` when traversing a record will capture it. Records that fall through all the filters without matching anything are considered "unfiltered".

    job.process
    job.records[:update]   #=> Array
    job.unfiltered_records #=> Array
    job.all_records #=> Array

Filters can be applied to records either pre- or post-translation. Usually you just need to look at the raw input parameters, but it's also possible to get the ouput parameter values from the second block parameter:

    filter(:example) do |input, output|
      input["RawEmailAddress"] =~ /gmail/ or
      output.status == :example
    end


## Installation & Dependencies

`gem install stockboy`

Supported on Ruby 1.9+.

<a name="stockboy-configuration"></a>
## Configuration

Specify template load paths for defining jobs. (`config/stockboy_jobs/` is included when loaded in a Rails app; else it must be defined.)

    Stockboy.configuration do |config|
      config.template_load_paths = %w[config/stockboy_jobs]
    end

Beyond the standard providers (`:ftp`, `:soap`, etc.) and readers (`:csv`, `:xml`), you can register your own for fetching or parsing data from different sources. (Contributions welcome.)

Register named readers for parsing data:

    Stockboy::Readers.register :m3u, PlaylistReader

Register named providers for receiving data:

    Stockboy::Providers.register :gopher, GopherProvider

Translations can also be registered for your own data formats:

    Stockboy::Translations.register :product_code, ProductCodeTranslator

[gf]:  http://guestfolio.com/
[etl]: https://en.wikipedia.org/wiki/Extract,_transform,_load 
[dsl]: https://en.wikipedia.org/wiki/Domain-specific_language
