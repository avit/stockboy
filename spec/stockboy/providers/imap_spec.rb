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

      provider.host.should == "mail.localhost.test"
      provider.username.should == "uuu"
      provider.password.should == "ppp"
      provider.mailbox.should == "INBOX/Data"
      provider.subject.should == %r{New Records 20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1])}
      provider.attachment.should == %r{data-[0-9]+\.csv}
      provider.since.should == Date.new(2012,12,1)
    end

    describe "deprecated options", pending: "implement deprecated_alias" do
      it "promotes since instead of newer_than" do
        provider = Providers::IMAP.new{ |f| f.newer_than Date.new(2012,12,1) }
        provider.since.should == Date.new(2012,12,1)
      end
    end

    describe ".new" do
      it "has no errors" do
        provider.errors.messages.should be_empty
      end

      it "accepts block initialization" do
        provider = Providers::IMAP.new{ |f| f.host 'mail.test2.local' }
        provider.host.should == 'mail.test2.local'
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

  end
end
