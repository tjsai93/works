# frozen_string_literal: true
require 'shopify_cli'

module ShopifyCli
  class SubCommand < Command
    class << self
      def call(args, command_name)
        cmd = new(@ctx)
        cmd.options = Options.new
        args = cmd.options.parse(@_options, args[1..-1] || [])
        cmd.call(args, command_name)
      end
    end
  end
end
