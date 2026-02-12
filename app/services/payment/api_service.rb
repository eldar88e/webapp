require 'faraday'

module Payment
  class ApiService
    API_DOMAIN = ENV.fetch('PAYMENT_API_DOMAIN')
    API_PATH   = '/api/method/merch/payin/'.freeze
    API_URL    = "#{API_DOMAIN}#{API_PATH}".freeze
    USER_TOKEN = ENV.fetch('PAYMENT_USER_TOKEN')
    LIMIT_INIT = 3

    INIT_ENDPOINT    = 'order_initialized/standart'.freeze
    PROCESS_ENDPOINT = 'order_process'.freeze
    CANCEL_ENDPOINT  = 'order_cancel'.freeze
    FILE_ENDPOINT    = 'order_check_down'.freeze
    CHECK_ENDPOINT   = 'order_get_status'.freeze

    class << self
      def order_initialized(transaction, try = 1)
        begin
          payload = {
            version: 3,
            amount: transaction.amount,
            id_pay_method: 1
          }
          result = fetch_response(transaction, payload, INIT_ENDPOINT)
          raise "Transaction: #{transaction.id} has error: #{result['message']}" if result['response'] == 'error'
        rescue StandardError => e
          if result['message'].downcase.include?('поменяйте сумму') && try <= LIMIT_INIT
            Rails.logger.error "Transaction #{transaction.id} failed to initialize. #{e.message}. Retrying..."
            try += 1
            sleep 1
            retry
          else
            msg = "Transaction #{transaction.id} failed to initialize after #{try} tries. Error: #{e.message}"
            TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(:admin_ids))
            raise e
          end
        end
        prepare_response(result)
      end

      def order_process(transaction)
        payload = {
          version: 1,
          object_token: transaction.object_token
        }
        fetch_response(transaction, payload, PROCESS_ENDPOINT)
      end

      def order_cancel(transaction)
        payload = {
          version: 1,
          object_token: transaction.object_token
        }
        fetch_response(transaction, payload, CANCEL_ENDPOINT)
      end

      def order_check_down(transaction, url)
        payload = {
          version: 2,
          object_token: transaction.object_token,
          url_file: url
        }
        fetch_response(transaction, payload, FILE_ENDPOINT)
      end

      def order_get_status(transaction)
        payload = {
          version: 1,
          object_token: transaction.object_token
        }
        fetch_response(transaction, payload, CHECK_ENDPOINT)
      end

      private

      def fetch_response(payment_amount, payload, endpoint)
        response = connection.post(endpoint) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.body = payload.merge(user_token: USER_TOKEN)
        end

        result = JSON.parse(response.body)
        return error_response(payment_amount, payload, response&.status, result) if result['response'] == 'error'

        log_transaction(payment_amount, payload, response&.status, result)
        result
      rescue StandardError => e
        error_response(payment_amount, payload, response&.status, result, e.full_message)
        { 'response' => 'error', 'message' => e.message }
      end

      def connection
        @connection ||= Faraday.new(url: API_URL) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
          f.response :logger if Rails.env.development?
        end
      end

      def log_transaction(payment_amount, payload, status, result, error = nil)
        ::ApiLog.create!(
          loggable: payment_amount,
          # action: action,
          http_method: 'POST',
          url: API_URL,
          request_headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
          request_body: payload,
          response_status: status,
          response_body: result,
          service_name: 'payment_gateway',
          # direction: 'outgoing',
          success: status == 200,
          error_message: error
        )
      end

      def prepare_response(result)
        {
          object_token: result['data']['data_requisite']['object_token'],
          fio: result['data']['data_requisite']['data_people'].values.join(' '),
          card_number: result['data']['data_requisite']['value'],
          bank_name: result['data']['data_requisite']['data_bank']['name'],
          amount_transfer: result['data']['data_requisite']['data_mathematics']['amount_transfer']
        }
      end

      def error_response(payment_amount, payload, status, result, error = nil)
        Rails.logger.error "Failed to fetch response: #{result['message']}"
        error ||= result['message']
        log_transaction(payment_amount, payload, status, result, { error: error })
        result
      end
    end
  end
end
