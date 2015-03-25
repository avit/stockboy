module Stockboy


  # @api private
  #
  class ConfiguratorBlock

    # Initialize a DSL context around an instance
    #
    def initialize(instance)
      @instance = instance
    end

  end

  # Mixin for defining DSL methods
  #
  module DSL

    # Define ambiguous attr reader/writers for DSL readability
    #
    # @example
    #   dsl.some_option = "new value" # => some_option = "new value"
    #   dsl.some_option "new value"   # => some_option = "new value"
    #   dsl.some_option               # => some_option
    #
    # @visibility private
    # @scope class
    #
    def dsl_attr(attr, options={})
      if options.fetch(:attr_accessor, true)
        attr_reader attr if options.fetch(:attr_reader, true)
        attr_writer attr if options.fetch(:attr_writer, true)
      end

      class_eval <<-___, __FILE__, __LINE__
      class DSL < Stockboy::ConfiguratorBlock
        def #{attr}(*arg)
          if arg.empty?
            @instance.#{attr}
          else
            if arg.is_a?(Array) && arg.size == 1
              @instance.#{attr} = arg.first
            else
              @instance.#{attr} = arg
            end
          end
        end
        def #{attr}=(arg)
          @instance.#{attr} = arg
        end
      end
      ___

      if attr_alias = options[:alias]
        alias_method attr_alias, attr
        alias_method :"#{attr_alias}=", :"#{attr}="

        class_eval <<-___, __FILE__, __LINE__
        class DSL < Stockboy::ConfiguratorBlock
          alias_method :#{attr_alias}, :#{attr}
          alias_method :#{attr_alias}=, :#{attr}=
        end
        ___
      end

      attr
    end

  end

end
