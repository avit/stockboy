module Stockboy
  module DSL

    def self.included(base)
      base.extend ClassMethods
    end

    def initialize(instance)
      @instance = instance
    end

    module ClassMethods
      private
      # Define ambiguous attr reader/writers for dsl readability
      #
      # self.some_option = "new value" # => some_option = "new value"
      # self.some_option "new value"   # => some_option = "new value"
      # self.some_option               # => some_option
      #
      def dsl_attrs(*args)
        args = args.first if args.first.is_a? Array
        args.each do |attr|
          writer = :"#{attr}="
          define_method writer do |arg|
            @instance.public_send(writer, arg)
          end
          define_method attr do |*arg|
            if arg.empty?
              @instance.public_send(attr)
            else
              @instance.public_send(writer, arg.first)
            end
          end
        end
      end
    end

  end
end
