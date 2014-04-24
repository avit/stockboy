# Stockboy

[![Gem Version](https://badge.fury.io/rb/stockboy.png)][gem]
[![Dependency Status](https://gemnasium.com/avit/stockboy.png)][gemnasium]
[![Build Status](https://travis-ci.org/avit/stockboy.png)][travis]
[![Code Climate](https://codeclimate.com/github/avit/stockboy.png)][climate]

Stockboy helps you receive and unpack data onto your shelves. It provides a DSL
for configuring data processing pipelines. You might consider using it to
synchronize data exported from external sources, as part of an [ETL][etl]
workflow, or migrating your own data from legacy systems. 

Full documentation available at [rdoc.info/gems/stockboy][rdoc]

## Goals

Stockboy was originally developed at [Guestfolio][gf] to help synchronize data
from many external systems that export periodic reports in various incompatible
ways. Each data source might vary orthogonally on:

* __Where the data resides:__
  whether a SOAP service, sent to an IMAP mailbox, an FTP server, or simply a
  local file.
* __How the data is formatted:__ 
  whether CSV, Excel, XML, JSON, or some other obscure format.
* __How the records are structured:__ 
  what fields are included, and how they are named.
* __What format the fields are:__ 
  such as different date formats (DMY vs. MDY), whether names are "first,
  last", or what do do with missing values.
* __Which records to process:__ 
  selecting whether records are incomplete, or valid and needing to be added,
  updated or deleted.

The goal of Stockboy is to provide a clean, but flexible DSL for declaring
these configurations and keeping them external to your application, letting
your app standardize on handling one common interface for the many different
sources.


## Usage

Following your defined job template (see below), a Stockboy job will process
incoming data into abstract "records". Stockboy leaves it up to your
application to decide what to do with them.

    job = Job.define("my_template")

    job.process
    records = job.records            #=> Hash of records sorted by filter key
    other   = job.unfiltered_records #=> Array of records unmatched by a filter
    all     = job.all_records        #=> Array

Yielding processed results to a block is also supported:

    job.process do |records, unfiltered|
      records[:updated].each  { |r| YourModel.create(r.attributes) }
      records[:no_data].each  { |r| log.warn "No data for #{r.id}" }
      unfiltered_records.each { |r| log.info "Skipping: #{r.raw_hash}" }
    end

### Records

Each record exposes both the source values and the mapped output values
according to your defined mapping. Typically the mapped fields should
correspond to the actual attributes on your application models. These can be
accessed as individual methods, or by converting the record to a hash.

    record.input["RawEmailField"] # => "ARTHUR@EXAMPLE.COM"
    record.output.email           # => "arthur@example.com"

    record.to_hash or record.attributes
    #=> {check_in: #<Time ...>, location_id: 123, first_name: "Arthur", ...}

    record.to_model(YourModel) or YourModel.new(record.attributes)
    #=> #<YourModel ...>


## Job Template DSL

Stockboy job templates are defined in Ruby but are simple and abstract enough
to be considered more _configuration_ than _code_. They should reside in the
[template load path](#stockboy-configuration) for easy loading. Once defined,
job templates are parsed and loaded at runtime, so they can be added or updated
separately without needing to restart a long-running process, e.g. Rails or
Sidekiq.

Writing a job template requires you to declare three parts:

### Example

    # config/stockboy_jobs/my_template.rb

    provider :ftp do
      host       "example.com"
      username   "mystore"
      password   "123456"
      file_name  "dailyreport-*.csv"
      file_pick  :first
    end

    repeat do |inputs, provider|
      0.upto 12 do |m|
        provider.file_dir = "reports/#{Date.today << 12-m}"
        inputs << provider
      end
    end

    attributes do
      email       from: 'RawEmailAddress'
      first_name  as: proc{ |r| r['Full-Name'].split(' ').first }
      last_name   as: proc{ |r| r['Full-Name'].split(' ').last }
      birthdate   as: [:time]
      score       as: [:integer, :default_zero]
    end

    filter(:invalid_email) do |input, _|
      not(input.email.include?('@') or input['EmailAddress'] == '')
    end
    
    filter(:missing_code) do |_, output|
      output.product_code.nil?
    end

Looking at the parts of this template:

### 1. Get it with a provider

The provider block describes the connection parameters for finding and fetching
data, which is returned as a raw string blob. It can handle some complexity to
determine which file to pick from an email attachment or FTP directory, for
example.

#### Fetching paginated data

If the provider requires multiple queries to fetch all the data (e.g. http
`?page=1` query params or a list of files), you can use an optional repeat
block to specify how to iterate over the data source, and when to stop.
Although it's possible to process each page as an individual job, the repeat
option is useful when you need to have all the data in hand before making
downstream processing decisions such as purging records that are not in the
data set.

    repeat do |inputs, http_provider|
      loop do
        inputs << http_provider
        break if http_provider.data.split("\n").size < 100
        http_provider.query["page"] += 1 
      end
    end

For each iteration, increment the provider settings and push it onto the list
of inputs. (This uses an Enumerator to yield each iteration's data before
processing the next one, so it should be memory-efficient for long series of
data sets.)

See: [File][file], [FTP][ftp], [HTTP][http], [IMAP][imap], [SOAP][soap]

[file]: lib/stockboy/providers/file.rb
[ftp]:  lib/stockboy/providers/ftp.rb
[http]: lib/stockboy/providers/http.rb
[imap]: lib/stockboy/providers/imap.rb
[soap]: lib/stockboy/providers/soap.rb


### 2. Parse it with a reader

The reader block describes how to turn the raw string from the provider into
sets of fields. This extracts the raw data tokens, which we can then map to our
application's domain.

See: [CSV][csv], [Fixed-Width][fix], [Spreadsheet][xls], [XML][xml]

[csv]: lib/stockboy/readers/csv.rb
[fix]: lib/stockboy/readers/fixed_width.rb
[xls]: lib/stockboy/readers/spreadsheet.rb
[xml]: lib/stockboy/readers/xml.rb


### 3. Collect it into attributes

The attributes block is the main part of the template definition. This
describes which fields to extract from the parsed data, and how to represent
each value in the output record. The output attributes are defined by calling
the attribute's name plus two options:

#### from:
When the field name from the source doesn't match the desired attribute name,
this option should be used to name the correct field to read from the source
record.

#### as:
By default, attributes are returned as the original raw string data value, but
translators can be applied to change the input to any format. Acceptable
options include a symbol for a built-in translator (e.g. `:date`) or any Proc
or callable object responding to `call(source_record)`.

Translator blocks can access record fields as either:

| Indexes for raw input fields      | Methods for final attribute names |
| :-------------------------------: | :-------------------------------: |
| `->(r){ r['RawEmail'].downcase }` | `->(r){ r.email.downcase }`       |

Since the entire record context is passed, you can combine multiple input
fields into one attribute (e.g. combining date plus time). You can also define
two attributes that extract different data from the same field, e.g. splitting
a full name field into first and last.

Translations are applied in order when given as an array. Since translators are
designed to handle invalid data, they will catch exceptions and return a `nil`
so it's a good idea to have default values at the end of the chain.

#### Built-in attribute translators: 

* [`:boolean`][bool]
  Common true/false strings to `True` or `False` (e.g. '1'/'0' or 't'/'f')
* [`:date`][date]
  ISO-8601 or common strings to `Date` (e.g. "2012-12-21" or "Dec 12, 2012")
* [`:uk_date`][ukda]
  Date strings from UK format to `Date` (e.g. "DD/MM/YY")
* [`:us_date`][usda]
  Date strings from US format to `Date` (e.g. "MM/DD/YY")
* [`:decimal`][deci] 
  Numeric strings to `BigDecimal` (e.g. prices)
* [`:integer`][intg]
  Numeric strings to `Fixnum` integers
* [`:string`][stri]
  Clean strings with leading/trailing whitespace trimmed
* [`:or_empty`][dest]
  Returns `""` for blank values
* [`:or_nil`][dest]
  Returns `nil` for blank values
* [`:or_zero`][dzer]
  Returns `0` for blank values

Attributes can be defined in a block as described, or added
individually as `attribute :name`.

[bool]: lib/stockboy/translators/boolean.rb
[date]: lib/stockboy/translators/date.rb
[deci]: lib/stockboy/translators/decimal.rb
[dest]: lib/stockboy/translators/default_empty_string.rb
[dnil]: lib/stockboy/translators/default_nil.rb
[dzer]: lib/stockboy/translators/default_zero.rb
[intg]: lib/stockboy/translators/integer.rb
[stri]: lib/stockboy/translators/string.rb
[time]: lib/stockboy/translators/time.rb
[ukda]: lib/stockboy/translators/uk_date.rb
[usda]: lib/stockboy/translators/us_date.rb


### 4. Funnel it with filters

Filters are optional, but they are very helpful for funneling the data into
your workflow. For example, you may need to partition records for different
handling based on a status field.
    
Filters are applied in the order that they are declared. The first filter that
returns `true` when traversing a record will capture it. Records that fall
through all the filters without matching anything are considered "unfiltered".

    job.process
    job.records[:update]   #=> Array
    job.unfiltered_records #=> Array
    job.all_records        #=> Array

Filters can inspect records either pre- or post-translation. Often you just
need to look at the raw input parameters, but it's also possible to get the
output values from the second block parameter:

    filter(:example) do |input, output|
      input["RawEmailAddress"] =~ /gmail/ or output.bounce_count > 1
    end

### 5. Trigger it with actions

Also optional, triggers let you define an action in the job template context
that can be called from your application. This lets you separate your app
interface from the implementation details of each data source.

A typical use case might be to clean up stale data after a successful import:

    on :cleanup do |job, timestamp|
      next unless job.processed?
      job.provider.client do |ftp|
        ftp.put(StringIO.new(timestamp.to_s), "LAST_RUN")
      end
      job.provider.delete_data # deletes the last matching file used
    end

The action blocks receive the job instance, and any additional arguments when
called via `job.trigger(:cleanup, Time.now)` or simply `job.cleanup(Time.now)`.

---

## Installation 

Add `gem 'stockboy'` to your Gemfile and run `bundle install`. 

Supported on Ruby 1.9+.


<a name="stockboy-configuration"></a>
## Configuration

When loaded under a Rails app, Stockboy will look for `config/stockboy.rb` for
self-configuration if it's present.

### Template Load Paths

Template load paths are intended for storing your defined job templates for
different data sources. (`config/stockboy_jobs/` is the default when loaded in
a Rails app; else it must be defined.)

    Stockboy.configuration do |config|
      config.template_load_paths = ['config/job_imports', 'config/log_imports']
    end

### Register Custom Providers / Readers

Beyond the standard providers (`:ftp`, `:soap`, etc.) and readers (`:csv`,
`:xml`), you can register your own for fetching or parsing data from different
sources. (Contributions welcome.)

    Stockboy::Readers.register :m3u, PlaylistReader
    Stockboy::Providers.register :gopher, GopherProvider
    Stockboy::Translations.register :product_code, YourProductCodeTranslator

See the [Reader][reader], [Provider][provider], and [Translator][translator]
for details on implementing your own custom classes.

[provider]:   lib/stockboy/provider.rb
[reader]:     lib/stockboy/reader.rb
[translator]: lib/stockboy/translator.rb

## Development

Contributions and pull requests are welcome.

    bundle install
    bundle exec rake # runs tests

[gf]:  http://guestfolio.com/
[etl]: https://en.wikipedia.org/wiki/Extract,_transform,_load 
[dsl]: https://en.wikipedia.org/wiki/Domain-specific_language
[travis]: https://travis-ci.org/avit/stockboy
[gemnasium]: https://gemnasium.com/avit/stockboy
[climate]: https://codeclimate.com/github/avit/stockboy
[rdoc]: http://rdoc.info/gems/stockboy/frames
[gem]: http://rubygems.org/gems/stockboy
