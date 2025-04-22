module Admin
  class MailingsController < Admin::ApplicationController
    MARKUP = 'to_catalog'.freeze

    before_action :form_mailing, only: :create

    def index
      @mailings = Mailing.order(send_at: :desc).includes(:user)
    end

    def new
      @mailing = Mailing.new(target: nil)
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Запустить рассылку'),
        turbo_stream.update(:modal_body, partial: '/admin/mailings/new')
      ]
    end

    def create
      if @mailing.save
        redirect_to admin_mailings_path, notice: t('mailing_success')
      else
        error_notice(@mailing.errors.full_messages, :unprocessable_entity)
      end
    end

    private

    def form_mailing
      @mailing      = current_user.mailings.new(mailing_params)
      @mailing.data = AttachmentService.call(params[:mailing][:attachment])
      form_markup
    end

    def form_markup
      @mailing.data[:markup] = { markup: MARKUP } if params[:mailing][:to_catalog] == '1'
      return if params[:mailing][:markup_buttons].blank?

      @mailing.data[:markup] || {}
      markup_keys = %i[url text]
      form_custom_markups(markup_keys)
    end

    def form_custom_markups(markup_keys)
      params[:mailing][:markup_buttons].each do |button|
        type = button[:url].start_with?('http') ? 'ext' : nil
        markup_keys.each { |key| form_markup_key(key, type) }
      end
    end

    def form_markup_key(key, type)
      field = ['markup', type, key].compact.join('_').to_sym
      @mailing.data[:markup][field] ||= []
      @mailing.data[:markup][field] << button[key]
    end

    def mailing_params
      params.require(:mailing).permit(:target, :message, :send_at) # TODO: добавить  :scheduled_at
    end
  end
end
