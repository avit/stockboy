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
        provider.errors.messages.should be_empty
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

      context "with no messages found" do
        it "should be nil" do
          allow(provider).to receive(:fetch_imap_message_keys).and_return []
          provider.data.should be_nil
        end
      end

    end

    describe "#delete_data" do
      let(:imap) { double(:imap) }

      it "should raise an error when called blindly" do
        expect { provider.delete_data }.to raise_error Stockboy::OutOfSequence
      end

      it "should call delete on the matching message" do
        allow(provider).to receive(:client).and_yield(imap)
        allow(provider).to receive(:search) { [5] }

        provider.matching_message

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
        provider.errors[:response].should include "IMAP connection error"
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
