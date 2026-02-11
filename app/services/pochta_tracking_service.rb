# service = PochtaTrackingService.new
# events = service.track('#805_234_324')
#
# events.each do |event|
#   puts "#{event[:date]} — #{event[:operation]} (#{event[:attribute]}) — #{event[:address]}"
# end
#
# last = events.last
# puts "Current status: #{last[:operation]}"

require 'faraday'

class PochtaTrackingService
  ENDPOINT = 'https://tracking.russianpost.ru/rtm34'.freeze

  def initialize
    @login = ENV.fetch('POCHTA_TRACKING_LOGIN', nil)
    @password = ENV.fetch('POCHTA_TRACKING_PASSWORD', nil)
    @conn = Faraday.new(url: ENDPOINT) do |f|
      f.headers['Content-Type'] = 'application/soap+xml; charset=utf-8'
      f.response :logger if Rails.env.development?
    end
  end

  def track(barcode)
    response = @conn.post { |req| req.body = build_request(barcode) }

    parse_response(response.body)
  end

  private

  def build_request(barcode)
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
                     xmlns:oper="http://russianpost.org/operationhistory"
                     xmlns:data="http://russianpost.org/operationhistory/data"
                     xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <oper:getOperationHistory>
            <data:getOperationHistoryRequest>
              <data:Barcode>#{barcode}</data:Barcode>
              <data:MessageType>0</data:MessageType>
              <data:Language>RUS</data:Language>
            </data:getOperationHistoryRequest>
            <data:AuthorizationHeader soapenv:mustUnderstand="1">
              <data:login>#{@login}</data:login>
              <data:password>#{@password}</data:password>
            </data:AuthorizationHeader>
          </oper:getOperationHistory>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def parse_response(body)
    doc = Nokogiri::XML(body)
    doc.remove_namespaces!

    doc.xpath('//historyRecord').map do |record|
      {
        operation: record.at('OperType/Name')&.text,
        attribute: record.at('OperAttr/Name')&.text,
        date: record.at('DateOper')&.text,
        index: record.at('DestinationAddress/Index')&.text,
        address: record.at('DestinationAddress/Description')&.text,
        weight: record.at('Mass')&.text&.to_i
      }
    end
  end
end
