class FileDownloaderService
  class << self
    def call(url)
      uri      = URI.parse(url)
      tempfile = Tempfile.new(['file', File.extname(uri.path)], binmode: true)
      download(uri, tempfile)
      # tempfile.rewind
      tempfile
    end

    private

    def download(uri, tempfile)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri)

        http.request(request) do |response|
          raise "Download failed: #{response.code}" unless response.code.to_i == 200

          response.read_body do |chunk|
            tempfile.write(chunk)
          end
        end
      end
    end
  end
end
