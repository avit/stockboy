module Stockboy

  # Struct-like value object for holding mapping & translation details from
  # input data fields
  #
  class Attribute < Struct.new(:to, :from, :translators, :ignore_condition)
    def inspect
      "#<Stockboy::Attribute to=#{to.inspect}, from=#{from.inspect}%s%s>" % [
        (", translators=#{translators}" if translators),
        (", ignore=#{ignore_condition.inspect}" if ignore_condition)
      ]
    end
  end
end
