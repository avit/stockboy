require 'spec_helper'
require 'stockboy/providers/imap'

module Stockboy
  describe Providers::IMAP do
    subject(:imap) { Stockboy::Providers::IMAP.new }

    it "should assign parameters" do
      imap.host = "mail.localhost.test"
      imap.username = "uuu"
      imap.password = "ppp"
      imap.mailbox = "INBOX/Data"
      imap.subject = %r{New Records 20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1])}
      imap.since = Date.new(2012,12,1)
      imap.attachment = %r{data-[0-9]+\.csv}

      imap.host.should == "mail.localhost.test"
      imap.username.should == "uuu"
      imap.password.should == "ppp"
      imap.mailbox.should == "INBOX/Data"
      imap.subject.should == %r{New Records 20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1])}
      imap.attachment.should == %r{data-[0-9]+\.csv}
      imap.since.should == Date.new(2012,12,1)
    end

    describe "deprecated options", pending: "implement deprecated_alias" do
      it "promotes since instead of newer_than" do
        imap = Providers::IMAP.new{ |f| f.newer_than Date.new(2012,12,1) }
        imap.since.should == Date.new(2012,12,1)
      end
    end

    describe ".new" do
      it "has no errors" do
        imap.errors.messages.should be_empty
      end

      it "accepts block initialization" do
        imap = Providers::IMAP.new{ |f| f.host 'mail.test2.local' }
        imap.host.should == 'mail.test2.local'
      end
    end

    describe "#data" do

      context "with no messages found" do
        it "should be nil" do
          imap.stub!(:fetch_imap_message_keys).and_return []
          imap.data.should be_nil
        end
      end

    end

  end
end
