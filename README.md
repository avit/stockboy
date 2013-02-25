# Stockboy

Stockboy receives data from various sources and different formats, and puts it on the shelves you tell it to. Stockboy has a job DSL that defines:

1. Where to get data
2. How to read it
3. What to select from it
4. How to transform it

The result is a dataset that is normalized and ready for persistence by the application.

## Installation & Dependencies

`gem install stockboy`

Currently only ruby 1.9 is supported. Waiting on roo for spreadsheet dependency in ruby 2.0, or we may make it an optional load.

## Usage

Given an example job template such as:

    # silly_weather.rb

    provider :ftp do
      host "weather.example.com"
      username "hippydippy"
      password "123456"
      file_name "weather-*.csv"
      file_newer Weather.last_run
      file_pick :first
    end

    reader :csv do
      headers true
      encoding "ISO-8859-1"
    end

    attributes do
      measured_at from: 'Time', as: [:time]
      location_id from: 'Locn', as: [:location_lookup]
      temperature from: 'Temp', as: [:from_fahrenheit]
      humidity    from: 'RelH', as: [:to_i.to_proc]
      pressure    from: 'mmHg', as: { |r| r.pressure.to_f / 760 }
      windspeed   from: 'Knot', as: { |r| r.windspeed.to_f * 1.85 }
    end

    filter :no_data do |raw,_|
      true if raw.temperature == "-99.99"
    end

    filter :updated do |_,output|
      true if output.measured_at > Weather.last_run
    end

The job will retrieve the data and return candidate records. Either the raw or translated attributes can be read from these:

    job = Job.define("silly_weather")

    records = job.records            # => Hash
    other   = job.unfiltered_records # => Array

    records[:updated].to_hash
    # => {measured_at: #<Time ...>, location_id: 123, temperature: 4, ...}

    records[:updated].raw_hash
    # => {measured_at: "31/10/1999"}

Yielding results to a block is also supported:

    job.process do |records, unfiltered|
      records[:updated].each do |r|
        Weather.record(r.attributes)
      end

      records[:no_data].each do |r|
        log.warn "Station #{r.attributes[:location_id]} is down"
      end

      unfiltered.each do |r|
        log.info "Skipping: #{r.raw_hash}"
      end
    end

### Configuration

Specify template load paths for defining jobs. (`config/stockboy_jobs` is included when loaded in a Rails app; else it must be defined.)

    Stockboy.configuration do |config|
      config.template_load_paths = %w[config/stockboy_jobs]
    end

Stockboy includes some standard providers (:ftp, :soap) and readers (:csv, :xml), but you can register your own for fetching or parsing data from different sources. (Contributions welcome.)

Register named readers for parsing data:

    Stockboy::Readers.register :m3u, PlaylistReader

Register named providers for receiving data:

    Stockboy::Providers.register :gopher, GopherProvider

Translations can also be registered for your own data formats:

    Stockboy::Translations.register :product_code, ProductCodeTranslator
