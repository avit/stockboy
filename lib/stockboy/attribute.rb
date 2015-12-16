module Stockboy

  # Struct-like value object for holding mapping & translation details from
  # input data fields
  #
  class Attribute < Struct.new(:to, :from, :translators, :ignore_condition)
    def ignore?(context)
      if Symbol === ignore_condition
        context.public_send(to).public_send(ignore_condition)
      elsif ignore_condition.respond_to?(:call)
        ignore_condition.call(context)
      else
        !!(ignore_condition)
      end
    end

    def inspect
      "#<Stockboy::Attribute to=#{to.inspect}, from=#{from.inspect}%s%s>" % [
        (", translators=#{translators}" if translators),
        (", ignore=#{ignore_condition.inspect}" if ignore_condition)
      ]
    end
  end
end
