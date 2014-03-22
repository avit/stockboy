require 'spec_helper'
require 'stockboy/providers/imap/search_options'

module Stockboy::Providers
  describe IMAP::SearchOptions do

    describe "to_hash" do
      it "converts keys to uppercase" do
        options(subject: "Improbability")
          .to_hash.should == {"SUBJECT" => "Improbability"}
      end
    end


    describe "to_imap" do

      it "converts to a flat array of options" do
        options(subject: "Improbability", from: "me@example.com")
          .to_imap.should == ["SUBJECT", "Improbability", "FROM", "me@example.com"]
      end

      DATE_OPTIONS = { before:      "BEFORE",
                       on:          "ON",
                       since:       "SINCE",
                       sent_before: "SENTBEFORE",
                       sent_on:     "SENTON",
                       sent_since:  "SENTSINCE" }

      DATE_OPTIONS.each do |date_option_symbol, date_option_imap|
        it "converts #{date_option_imap.inspect} to IMAP date option" do
          options(date_option_symbol => TIME_FORMATS.first)
          .to_imap.should == [date_option_imap, "12-DEC-2012"]
        end
      end

      TIME_FORMATS = [ t = Time.new(2012, 12, 12),
                       t.to_i,
                       t.to_s ]

      TIME_FORMATS.each do |time|
        it "converts #{time.class} to IMAP date option" do
          options(since: time)
          .to_imap.should == ["SINCE", "12-DEC-2012"]
        end
      end

      BOOLEAN_OPTIONS = { seen:      "SEEN",
                          unseen:    "UNSEEN",
                          flagged:   "FLAGGED",
                          unflagged: "UNFLAGGED" }

      BOOLEAN_OPTIONS.each do |bool_option_symbol, bool_option_imap|
        it "converts #{bool_option_imap.inspect} to IMAP single value option" do
          options(bool_option_symbol => true).to_imap.should == [bool_option_imap]
          options(bool_option_symbol => false).to_imap.should == ["NOT", bool_option_imap]
          options(bool_option_symbol => nil).to_imap.should == []
        end
      end

    end

    def options(*args)
      described_class.new(*args)
    end

  end
end
