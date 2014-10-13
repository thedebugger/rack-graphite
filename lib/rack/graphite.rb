require 'statsd'

module Rack
  class Graphite
    PREFIX = 'requests'
    ID_REGEXP = %r{/\d+(/|$)} # Handle /123/ or /123
    ID_REPLACEMENT = '/id\1'.freeze
    GUID_REGEXP = %r{/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(/|$)} # Handle /GUID/ or /GUID
    GUID_REPLACEMENT = '/guid\1'.freeze

    def initialize(app, options={})
      @app = app
      @prefix = options[:prefix] || PREFIX
    end

    def call(env)
      path = env['PATH_INFO'] || '/'
      method = env['REQUEST_METHOD'] || 'GET'
      metric = path_to_graphite(method, path)

      result = nil
      Statsd.instance.timing(metric) do
        result = @app.call(env)
      end
      return result
    end

    def path_to_graphite(method, path)
      method = method.downcase
      if (path.nil?) || (path == '/') || (path.empty?)
        "#{@prefix}.#{method}.root"
      else
        # Replace ' ' => '_', '.' => '-'
        path = path.tr(' .', '_-')
        path.gsub!(ID_REGEXP, ID_REPLACEMENT)
        path.gsub!(GUID_REGEXP, GUID_REPLACEMENT)
        path.tr!('/', '.')

        "#{@prefix}.#{method}#{path}"
      end
    end
  end
end
