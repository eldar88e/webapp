require 'rails_helper'

RSpec.describe ReportService do
  let(:user) { create(:user, tg_id: 123) }
  let(:product) { create(:product) }
  let!(:bank_card) { create(:bank_card) }
  let(:order) { create(:order, user: user, total_amount: 100) }

  before do
    allow(TelegramService).to receive(:call).and_return(42)
    allow(TelegramMsgDelService).to receive(:remove)
    # allow(AbandonedOrderReminderJob).to receive(:perform_async)
    allow(SendReviewRequestJob).to receive(:perform_later)
  end

  describe '.on_unpaid' do
    it 'sends notifications and schedules reminder' do
      described_class.on_unpaid(order)
      message = user.messages.last

      expect(message.text).to include("🎉 Ваш заказ №#{order.id}")
      expect(message.is_incoming).to be(false)
      expect(message.data.dig('markup', 'markup')).to eq('i_paid')
    end
  end

  describe '.on_paid' do
    it 'sends notifications to admin and client' do
      described_class.on_paid(order)

      expect(TelegramService).to have_received(:call).with(
        a_string_including("Надо проверить оплату по заказу №#{order.id}"),
        nil,
        markup: 'approve_payment'
      )

      expect(TelegramService).to have_received(:call)
                                   .with(I18n.t('tg_msg.paid_client'), user.tg_id, markup: 'new_order')
    end
  end

  describe '.on_processing' do
    it 'sends courier notifications' do
      described_class.on_processing(order)

      expect(TelegramService).to have_received(:call).with(
        a_string_including("👀 Нужно отправить заказ №#{order.id}"),
        :courier,
        markup: 'submit_tracking'
      )

      expect(TelegramService).to have_received(:call).with(
        a_string_including("❤️ Благодарим вас за покупку!\n\n🚚 Заказ №#{order.id}"),
        user.tg_id,
        markup: 'new_order'
      )
    end
  end

  describe '.on_shipped' do
    let!(:order_item) { create(:order_item, order: order, product: product) }

    it 'sends tracking info and schedules reviews' do
      order.update!(tracking_number: 'TRACK123')
      described_class.on_shipped(order)

      expect(TelegramService).to have_received(:call).with(
        a_string_including("✅ Готово! Трек-номер отправлен клиенту.\n\nТрек-номер: TRACK123\n\nЗаказ №#{order.id}"),
        :courier, markup: nil
      )

      expect(TelegramService).to have_received(:call).with(
        a_string_including("✅ Заказ №#{order.id}\n\n📦 Посылка отправлена!\n\nВаш трек-номер: TRACK123"),
        user.tg_id, markup: 'new_order'
      )
    end
  end

  describe '.on_cancelled' do
    it 'sends cancellation notices' do
      described_class.on_cancelled(order)

      expect(TelegramService).to have_received(:call).with(
        "❌ Заказ №#{order.id} был отменен!", nil, markup: nil
      )

      expect(TelegramService).to have_received(:call).with(
        a_string_including("❌ Ваш заказ №#{order.id} отменён."), user.tg_id, markup: 'new_order'
      )
    end
  end

  describe '.on_refunded' do
    it 'sends refund notification' do
      described_class.on_refunded(order)
      expect(TelegramService).to have_received(:call).with("Order №#{order.id} has been refunded")
    end
  end

  describe '.on_overdue' do
    it 'sends overdue reminder' do
      described_class.on_overdue(order)
      expect(TelegramService).to have_received(:call).with(
        I18n.t('tg_msg.unpaid.reminder.overdue', order: order.id), user.tg_id, markup: 'new_order'
      )
    end
  end

  describe 'private methods' do
    describe '.send_report' do
      it 'updates message id' do
        allow(TelegramService).to receive(:call).and_return(456)

        described_class.send(:send_report, order,
                             user_msg: 'test',
                             user_tg_id: user.tg_id
        )

        expect(order.reload.msg_id).to eq(456)
      end
    end

    describe '.schedule_review_requests' do
      let!(:order_item) { create(:order_item, order: order, product: product) }
      # let!(:review) { create(:review, user: user, product: product) }

      it 'skips products with existing reviews' do
        described_class.send(:schedule_review_requests, order, user)
        expect(SendReviewRequestJob).not_to have_received(:perform_later)
      end
    end
  end
end
