# frozen_string_literal: true

require 'shopify_cli'

module ShopifyCli
  module Commands
    class Serve < ShopifyCli::Command
      include ShopifyCli::Helpers::OS
      prerequisite_task :ensure_env
      options do |parser, flags|
        parser.on('--host=HOST') do |h|
          flags[:host] = h.gsub('"', '')
        end
      end

      def call(*)
        project = Project.current
        url = options.flags[:host] || Tasks::Tunnel.call(@ctx)
        update_env(url)
        ShopifyCli::Tasks::UpdateWhitelistURL.call(@ctx, url: url)
        if mac? && project.env.shop
          @ctx.puts("{{*}} Press {{yellow: Control-T}} to open this project in your browser")
          on_siginfo do
            open = Open.new(@ctx)
            open.call
          end
        end
        CLI::UI::Frame.open('Running server...') do
          @ctx.system(project.app_type.serve_command(@ctx))
        end
      end

      def self.help
        <<~HELP
          Start a local development server for your project, as well as a public ngrok tunnel to your localhost.
            Usage: {{command:#{ShopifyCli::TOOL_NAME} serve}}
        HELP
      end

      def self.extended_help
        <<~HELP
          {{bold:Options:}}
            {{cyan:--host=HOST}}: Must be HTTPS url. Bypass running tunnel and use custom host.
        HELP
      end

      def update_env(url)
        Project.current.env.update(@ctx, :host, url)
      end

      def on_siginfo
        fork do
          begin
            r, w = IO.pipe
            @signal = false
            trap('SIGINFO') do
              @signal = true
              w.write(0)
            end
            while r.read(1)
              next unless @signal
              @signal = false
              yield
            end
          rescue Interrupt
            exit(0)
          end
        end
      end
    end
  end
end
