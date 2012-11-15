module Stockboy
  module DSLAttributes

    # Define ambiguous attr reader/writers
    #
    # self.some_option "new value" # => "new_value"
    # self.some_option             # => "new value"
    #
    def dsl_attrs(*args)
      args.each do |attr|
        attr_accessor attr
        define_method attr do |*arg|
          instance_variable_set(:"@#{attr}", arg.first) unless arg.empty?
          instance_variable_get(:"@#{attr}")
        end
      end
    end

  end
end
