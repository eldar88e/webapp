class ProxyController < ApplicationController
  EMAIL_CLEANER_URL = 'https://cleaner.dadata.ru/api/v1/clean/email'.freeze
  HEADER            = {
    'Content-Type' => 'application/json',
    'Accept' => 'application/json',
    'Authorization' => "Token #{Setting.fetch_value(:dadata_token)}",
    'X-Secret' => Setting.fetch_value(:dadata_secret_key)
  }.freeze

  def clean_email
    uri          = URI(EMAIL_CLEANER_URL)
    http         = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request      = Net::HTTP::Post.new(uri, HEADER)
    request.body = [params[:email]].to_json
    response     = http.request(request)

    render json: response&.body
  end
end
