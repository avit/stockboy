require 'spec_helper'
require 'stockboy/filters/missing_email'

describe Stockboy::Filters::MissingEmail do
  subject(:filter) { described_class.new(:e) }
  it 'allows email addresses' do
    record = OpenStruct.new(e: 'me@example.com')
    filter.call(record, record).should be_false
  end

  it 'catches empty strings' do
    record = OpenStruct.new(e: '')
    filter.call(record, record).should be_true
  end

  it 'catches hyphen placeholders' do
    record = OpenStruct.new(e: '-')
    filter.call(record, record).should be_true
  end

  it 'uses translated output value' do
    input = OpenStruct.new(e: '', other: 'me@example.com')
    output = OpenStruct.new(e: input.other)
    filter.call(input, output).should be_false
  end
end
