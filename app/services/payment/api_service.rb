require 'faraday'

module Payment
  class ApiService
    API_DOMAIN = ENV.fetch('PAYMENT_API_DOMAIN')
    API_PATH   = '/api/method/merch/payin/'.freeze
    API_URL    = "#{API_DOMAIN}#{API_PATH}".freeze
    USER_TOKEN = ENV.fetch('PAYMENT_USER_TOKEN')
    LIMIT_INIT = 5

    INIT_ENDPOINT    = 'order_initialized/standart'.freeze
    PROCESS_ENDPOINT = 'order_process'.freeze
    CANCEL_ENDPOINT  = 'order_cancel'.freeze
    FILE_ENDPOINT    = 'order_check_down'.freeze
    CHECK_ENDPOINT   = 'order_get_status'.freeze

    class << self
      def order_initialized(transaction, try = 1)
        payload = {
          version: 3,
          amount: transaction.amount,
          id_pay_method: 1
        }
        result = fetch_initialized(transaction, payload, try)
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
        response = connection_to(endpoint, payload)
        result   = JSON.parse(response.body)
        return error_response(payment_amount, payload, response&.status, result) if result['response'] == 'error'

        log_transaction(payment_amount, payload, response&.status, result)
        result
      rescue StandardError => e
        result = { 'response' => 'error', 'message' => e.message }
        error_response(payment_amount, payload, response&.status, result, e.full_message)
      end

      def connection
        Faraday.new(url: API_URL) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
          f.response :logger if Rails.env.development?
        end
      end

      def connection_to(endpoint, payload)
        connection.post(endpoint) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.body = payload.merge(user_token: USER_TOKEN)
        end
      end

      # rubocop:disable Metrics/MethodLength
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
      # rubocop:enable Metrics/MethodLength

      def prepare_response(result)
        return result if result['response'] == 'error'

        data_requisite = result['data']['data_requisite']
        {
          object_token: data_requisite['object_token'],
          fio: data_requisite['data_people'].values.join(' '),
          card_number: data_requisite['value'],
          bank_name: data_requisite['data_bank']['name'],
          amount_transfer: data_requisite['data_mathematics']['amount_transfer']
        }
      end

      def error_response(payment_amount, payload, status, result, error = nil)
        error ||= result['message']
        Rails.logger.error "Failed to fetch response: #{error}"
        log_transaction(payment_amount, payload, status, result, { error: error })
        result
      end

      def fetch_initialized(transaction, payload, try)
        result = fetch_response(transaction, payload, INIT_ENDPOINT)
        raise result['message'] if result['response'] == 'error'

        result
      rescue StandardError => e
        if result['message'].downcase.match?(/поменяйте сумму|нет подходящих реквизитов/) && try <= LIMIT_INIT
          error_log "Transaction #{transaction.id} failed to initialize. #{e.message}. Retrying...", e, :test_id
          try += 1
          sleep 3 * try
          retry
        else
          msg = "Transaction: #{transaction.id} for Order: #{transaction.order.id}"
          msg += " failed to initialize after #{try} tries. Error: #{e.message}"
          error_log msg, e
          result
        end
      end

      def error_log(msg, error, tg_id = :admin_ids)
        Rails.logger.error msg + "Full message: #{error.full_message}"
        TelegramJob.perform_later(msg: msg, id: Setting.fetch_value(tg_id))
      end
    end
  end
end
