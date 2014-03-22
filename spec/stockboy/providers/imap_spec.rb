require 'spec_helper'
require 'stockboy/providers/imap'

module Stockboy
  describe Providers::IMAP do
    subject(:provider) { Stockboy::Providers::IMAP.new }

    it "should assign parameters" do
      provider.host = "mail.localhost.test"
      provider.username = "uuu"
      provider.password = "ppp"
      provider.mailbox = "INBOX/Data"
      provider.subject = %r{New Records 20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1])}
      provider.since = Date.new(2012,12,1)
      provider.attachment = %r{data-[0-9]+\.csv}
      provider.file_smaller = 1024**3
      provider.file_larger = 1024

      provider.host.should == "mail.localhost.test"
      provider.username.should == "uuu"
      provider.password.should == "ppp"
      provider.mailbox.should == "INBOX/Data"
      provider.subject.should == %r{New Records 20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1])}
      provider.attachment.should == %r{data-[0-9]+\.csv}
      provider.since.should == Date.new(2012,12,1)
      provider.file_smaller.should == 1024**3
      provider.file_larger.should == 1024
    end

    it "aliases since to newer_than" do
      provider = Providers::IMAP.new{ |f| f.newer_than Date.new(2012,12,1) }
      provider.since.should == Date.new(2012,12,1)
    end

    it "aliases file_smaller to smaller_than" do
      provider = Providers::IMAP.new{ |f| f.smaller_than 1024**3 }
      provider.file_smaller.should == 1024**3
    end

    describe ".new" do
      it "has no errors" do
        provider.errors.should be_empty
      end

      it "accepts block initialization" do
        provider = Providers::IMAP.new do
          host 'mail.test2.local'
          attachment 'report.csv'
          file_smaller 1024**3
          file_larger 1024
        end
        provider.host.should == 'mail.test2.local'
        provider.attachment.should == 'report.csv'
        provider.file_smaller.should == 1024**3
        provider.file_larger.should == 1024
      end
    end

    describe "#data" do
      let(:imap) { double("Net::IMAP") }
      let(:provider) { described_class.new(host: 'h', username: 'u', password: 'p') }
      subject(:data) { provider.data }
      before { allow(provider).to receive(:client).and_yield imap }

      context "with no messages found" do
        before { mock_imap_search [] => [] }
        it { should be_nil }
      end

      context "with a found message" do
        let(:rfc_email) { File.read(fixture_path "email/csv_attachment.eml") }
        before { mock_imap_search [] => [1] and mock_imap_fetch 1 => rfc_email }
        it { should match "LAST_NAME,FIRST_NAME" }

        context "validating correct filename string" do
          before { provider.attachment = "daily_report.csv" }
          it { should match "LAST_NAME,FIRST_NAME" }
        end

        context "validating incorrect filename string" do
          before { provider.attachment = "wrong_report.csv" }
          it { should be_nil }
        end

        context "validating correct filename pattern" do
          before { provider.attachment = /^daily.*\.csv$/ }
          it { should match "LAST_NAME,FIRST_NAME" }
        end

        context "validating incorrect filename pattern" do
          before { provider.attachment = /^wrong.*\.csv$/ }
          it { should be_nil }
        end

        context "validating correct smaller size" do
          before { provider.smaller_than = 2048 }
          it { should match "LAST_NAME,FIRST_NAME" }
        end

        context "validating incorrect smaller size" do
          before { provider.smaller_than = 10 }
          it { should be_nil }
        end

        context "validating correct larger size" do
          before { provider.larger_than = 10 }
          it { should match "LAST_NAME,FIRST_NAME" }
        end

        context "validating correct larger size" do
          before { provider.larger_than = 2048 }
          it { should be_nil }
        end

      end

      context "with a found message since time" do
        let(:rfc_email) { File.read fixture_path('email/csv_attachment.eml') }
        before {
          provider.since = Time.new(2014, 1, 31)
          mock_imap_search ["SINCE", "31-JAN-2014"] => [1]
          mock_imap_fetch 1 => rfc_email
        }
        it { should match "LAST_NAME,FIRST_NAME" }

        context "without ActiveSupport" do
          before { allow_any_instance_of(DateTime).to receive(:respond_to?).with(:getutc) { false } }
          it { should match "LAST_NAME,FIRST_NAME" }
        end
      end

      def mock_imap_search(searches)
        searches.each do |search_keys, found_keys|
          sort_args = ['DATE'], search_keys, 'UTF-8'
          expect(imap).to receive(:sort).with(*sort_args).and_return found_keys
        end
      end

      def mock_imap_fetch(list)
        list.each do |key, email|
          expect(imap).to receive(:fetch).with(key, 'RFC822').and_return [
            double("Net::IMAP::FetchData", attr: {'RFC822' => email})
          ]
        end
      end
    end

    describe "#delete_data" do
      let(:imap) { double(:imap) }

      it "should raise an error when called blindly" do
        expect { provider.delete_data }.to raise_error Stockboy::OutOfSequence
      end

      it "should call delete on the message key" do
        allow(provider).to receive(:client).and_yield(imap)
        allow(provider).to receive(:search) { [5] }

        provider.message_key

        expect(imap).to receive(:uid_store).with(5, "+FLAGS", [:Deleted])
        expect(imap).to receive(:expunge)

        provider.delete_data
      end
    end

    describe "#client" do

      before do
        provider.host, provider.username, provider.password = "hhh", "uuu", "ppp"
        provider.mailbox = "UNBOX"
      end

      it "reuses open connections in nested contexts" do
        net_imap = expect_connection("hhh", "uuu", "ppp", "UNBOX")

        provider.client do |connection|
          expect(connection).to be net_imap
          provider.client do |i|
            expect(connection).to be net_imap
          end
        end
      end

      it "closes connections when catching exceptions" do
        net_imap = expect_connection("hhh", "uuu", "ppp", "UNBOX")
        provider.client { |i| raise Net::IMAP::Error }
        provider.errors.first.should match /IMAP connection error/
      end

    end

    describe "#search_keys" do
      it "uses configured options by default" do
        provider.since = Date.new(2012, 12, 21)
        provider.subject = "Earth"
        provider.from = "me@example.com"

        provider.search_keys.should == [
          "SUBJECT", "Earth",
          "FROM", "me@example.com",
          "SINCE", "21-Dec-2012"
        ]
      end

      it "replaces defaults with given options" do
        provider.since = Date.new(2012, 12, 21)
        provider.subject = "Earth"
        provider.search_keys(subject: "Improbability").should == ["SUBJECT", "Improbability"]
      end

      it "returns the same array given" do
        provider.search_keys(["SINCE", "21-DEC-12"]).should == ["SINCE", "21-DEC-12"]
      end
    end

    describe "#default_search_options" do
      it "includes configured SUBJECT option" do
        provider.subject = "Life"
        provider.default_search_options.should == {subject: "Life"}
      end

      it "includes configured SINCE option" do
        provider.since = Date.today
        provider.default_search_options.should == {since: Date.today}
      end

      it "includes configured FROM option" do
        provider.from = "me@example.com"
        provider.default_search_options.should == {from: "me@example.com"}
      end
    end

    def expect_connection(host, user, pass, mailbox)
      net_imap = double("IMAP")
      expect(Net::IMAP).to receive(:new).with(host) { net_imap }
      expect(net_imap).to receive(:login).with(user, pass)
      expect(net_imap).to receive(:examine).with(mailbox)
      expect(net_imap).to receive(:disconnect)
      net_imap
    end

  end
end
