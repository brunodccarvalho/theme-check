# frozen_string_literal: true
require "zlib"

module ThemeCheck
  module HttpHelpers
    def decompress_http_response(res)
      encoding = res.header['Content-Encoding']
      return res.body unless encoding

      case encoding
      when 'gzip' then decompress_gzip(res.body)
      when 'deflate' then Zlib::Inflate.inflate(res.body)
      when 'identity' then res.body
      end
    end

    def decompress_gzip(body)
      sio = StringIO.new(body)
      gz = Zlib::GzipReader.new(sio)
      decompressed = gz.read
      gz.close
      decompressed
    end
  end
end
