# frozen_string_literal: true
require "net/http"
require "pathname"

module ThemeCheck
  class RemoteAssetFile
    include HttpHelpers

    class << self
      def cache
        @cache ||= {}
      end

      def from_src(src)
        key = uri(src).to_s
        return if key.empty?

        cache[key] = RemoteAssetFile.new(src) unless cache.key?(key)
        cache[key]
      end

      def visit_src(src)
        asset = from_src(src)
        asset && asset.ok ? yield(asset) : false
      end

      def uri(src)
        URI.parse(src.sub(%r{^//}, "https://"))
      rescue URI::InvalidURIError
        nil
      end
    end

    attr_reader :uri

    def initialize(src)
      @uri = RemoteAssetFile.uri(src)
      fetch!
    end

    def code
      @response.code
    end

    def ok
      @success
    end

    def content
      return unless ok
      decompress_http_response(@response)
    end

    def gzipped_content
      return unless ok
      @response.body
    end

    def gzipped_size
      return unless ok
      @gzipped_size ||= @response.body.bytesize
    end

    private

    def fetch!
      @response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: ssl?) do |http|
        req = Net::HTTP::Get.new(uri)
        req['Accept-Encoding'] = 'gzip, deflate'
        http.request(req)
      end
      @success = @response.is_a?(Net::HTTPSuccess)
    rescue OpenSSL::SSL::SSLError, Zlib::StreamError, *NET_HTTP_EXCEPTIONS
      @success = false
    end

    def ssl?
      uri.scheme == 'https' || url.scheme.nil?
    end
  end
end
