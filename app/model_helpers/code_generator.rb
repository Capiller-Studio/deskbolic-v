# frozen_string_literal: true

class CodeGenerator < Module
  BASE           = 10
  DEFAULT_LENGTH = 9

  attr_accessor :prefix, :referral, :length, :letters

  def initialize(options = {})
    self.prefix     = options.fetch(:prefix)
    self.referral   = options.fetch(:referral)
    self.length     = options.fetch(:length, DEFAULT_LENGTH)
    self.letters    = options.fetch(:letters, true)
  end

  def included(host)
    generator_instance = self

    host.class_eval do
      before_validation do |instance|
        instance.identifier ||= generate_code(host, :identifier)

        instance.referral_code ||= generate_code(host, :referral_code) if generator_instance.referral 
      end

      define_singleton_method(:code_generator) { generator_instance }

      def generate_code(host, attribute)
        host.code_generator.generate_code(host, attribute)
      end
    end
  end

  def generate_code(host, attribute)
    current_length = length

    loop do
      candidate = new_candidate(current_length)
      return candidate unless host.exists?(attribute => candidate)

      # If over half of all possible options are taken add another digit.
      current_length += 1 if host.count > Rational(BASE**current_length, 2)
    end
  end

  def new_candidate(length)
    characters = letters ? 36 : 10
    @prefix + SecureRandom.random_number(characters**length).to_s(characters).rjust(length, "0").upcase
  end
end
