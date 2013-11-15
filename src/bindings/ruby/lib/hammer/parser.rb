module Hammer
  class Parser

    # Don't create new instances with Hammer::Parser.new,
    # use the constructor methods instead (i.e. Hammer::Parser.int64 etc.)
    def initialize
    end

    def parse(data)
      raise RuntimeError, '@h_parser is nil' if @h_parser.nil?
      raise ArgumentError, 'expecting a String' unless data.is_a? String # TODO: Not needed, FFI checks that.
      result = Hammer::Internal.h_parse(@h_parser, data, data.length);
      # TODO: Do something with the data
      !result.null?
    end

    def self.token(string)
        h_parser = Hammer::Internal.h_token(string, string.length)

        parser = Hammer::Parser.new
        parser.instance_variable_set :@h_parser, h_parser
        return parser
    end

    def self.ch(char)
        # TODO: Really? Should probably accept Fixnum in appropriate range
        # Also, char.ord gives unexpected results if you pass e.g. Japanese characters: '今'.ord == 20170; Hammer::Parser::Ch.new('今').parse(202.chr) == true
        # Not really unexpected though, since 20170 & 255 == 202.
        # But probably it's better to use Ch for Fixnum in 0..255 only, and only Token for strings.
        raise ArgumentError, 'expecting a one-character String' unless char.is_a?(String) && char.length == 1
        h_parser = Hammer::Internal.h_ch(char.ord)

        parser = Hammer::Parser.new
        parser.instance_variable_set :@h_parser, h_parser
        return parser
    end

    def self.sequence(*parsers)
        args = parsers.flat_map { |p| [:pointer, p.h_parser] }
        h_parser = Hammer::Internal.h_sequence(*args, :pointer, nil)
        sub_parsers = parsers # store them so they don't get garbage-collected (probably not needed, though)
        # TODO: Use (managed?) FFI struct instead of void pointers

        parser = Hammer::Parser.new
        parser.instance_variable_set :@h_parser, h_parser
        parser.instance_variable_set :@sub_parsers, sub_parsers
        return parser
    end

    def self.choice(*parsers)
        args = parsers.flat_map { |p| [:pointer, p.h_parser] }
        h_parser = Hammer::Internal.h_choice(*args, :pointer, nil)
        sub_parsers = parsers # store them so they don't get garbage-collected (probably not needed, though)
        # TODO: Use (managed?) FFI struct instead of void pointers

        parser = Hammer::Parser.new
        parser.instance_variable_set :@h_parser, h_parser
        parser.instance_variable_set :@sub_parsers, sub_parsers
        return parser
    end

    # Defines a parser constructor with the given name.
    # Options:
    #   hammer_function: name of the hammer function to call (default: 'h_'+name)
    def self.define_parser(name, options = {})
      hammer_function = options[:hammer_function] || ('h_' + name.to_s)

      # Define a new class method
      define_singleton_method name do |*parsers|
        #args = parsers.map { |p| p.instance_variable_get :@h_parser }
        h_parser = Hammer::Internal.send hammer_function, *parsers.map(&:h_parser)

        parser = Hammer::Parser.new
        parser.instance_variable_set :@h_parser, h_parser
        return parser
      end
    end
    private_class_method :define_parser

    define_parser :int64
    define_parser :int32
    define_parser :int16
    define_parser :int8
    define_parser :uint64
    define_parser :uint32
    define_parser :uint16
    define_parser :uint8
    define_parser :whitespace
    define_parser :left
    define_parser :right
    define_parser :middle
    define_parser :end
    define_parser :nothing
    define_parser :butnot
    define_parser :difference
    define_parser :xor
    define_parser :many
    define_parser :many1

    attr_reader :h_parser
  end
end
