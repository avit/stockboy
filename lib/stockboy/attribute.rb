module Stockboy

  # Struct-like value object for holding mapping & translation details from
  # input data fields
  #
  class Attribute < Struct.new(:to, :from, :translators)
    def inspect
      "#<Stockboy::Attribute to=#{to.inspect}, from=#{from.inspect}, translators=#{translators}>"
    end
  end
end
