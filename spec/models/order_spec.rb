require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }
  let(:product) { create(:product, stock_quantity: 10) }
  let(:order) { create(:order, user: user, status: :unpaid) }
  let(:order_item) { create(:order_item, order: order, product: product, quantity: 2) }

  describe 'validations' do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:total_amount) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:order_items).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(
      initialized: 0,
      unpaid: 1,
      paid: 2,
      processing: 3,
      shipped: 4,
      cancelled: 5,
      overdue: 7,
      refunded: 8
    ) }
  end

  describe 'callbacks' do
    context 'when status is unpaid' do
      it 'sets created_at to current time' do
        order.status = 'unpaid'
        order.save
        expect(order.created_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when status is processing' do
      it 'sets paid_at to current time' do
        order.status = 'processing'
        order.save
        expect(order.paid_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when status is shipped' do
      it 'sets shipped_at to current time' do
        order.status = 'shipped'
        order.save
        expect(order.shipped_at).to be_within(1.second).of(Time.current)
      end
    end

    describe '#remove_cart' do
      let!(:cart) { create(:cart, user: user) }

      it 'destroys user cart when status changes from unpaid to paid' do
        expect { order.update!(status: :paid) }.to change(Cart, :count).by(-1)
      end
    end

    describe '#deduct_stock' do
      before do
        allow(TelegramService).to receive(:call).and_return(rand(1..10))
        allow(TelegramMsgDelService).to receive(:remove).and_return(true)
        order_item
      end

      it 'deducts stock quantity when status changes to processing' do
        order.update!(status: :paid)
        expect {
          order.update!(status: :processing)
          product.reload
        }.to change(product, :stock_quantity).by(-2)
      end

      context 'when insufficient stock' do
        before do
          product.update!(stock_quantity: 1)
          order.update!(status: :paid)
        end

        it 'raises error and sends notification' do
          allow(TelegramJob).to receive(:perform_later)
          expect { order.update!(status: :processing) }.to raise_error(StandardError, /Недостаток в остатках/)
          expect(TelegramJob).to have_received(:perform_later).with(msg: "Недостаток в остатках для продукта: #{product.name} в заказе #{order.id}")
        end
      end
    end

    describe '#restock_stock' do
      before do
        order_item
        product.update!(stock_quantity: 5)
        order.update!(status: :processing)
      end

      it 'restocks when order is cancelled' do
        expect {
          order.update!(status: :cancelled)
          product.reload
        }.to change(product, :stock_quantity).by(2)
      end
    end

    describe '#check_status_change' do
      it 'triggers ReportJob after commit' do
        allow(ReportJob).to receive(:perform_later)
        order.update!(status: :paid)
        expect(ReportJob).to have_received(:perform_later).with(order_id: order.id).once
      end
    end
  end

  describe '.revenue_by_date' do
    let!(:order1) { create(:order, user: user, status: :shipped, updated_at: 1.day.ago, total_amount: 100) }
    let!(:order2) { create(:order, user: user, status: :shipped, updated_at: Time.current, total_amount: 200) }

    it 'returns revenue grouped by day' do
      result = Order.revenue_by_date(2.days.ago, Time.current, 'DATE(updated_at)')
      expect(result.values.sum).to eq(300)
    end
  end

  describe '.count_order_with_status' do
    let(:user_two) { create(:user_two) }
    before do
      create_list(:order, 2, user: user_two, status: :paid)
      create(:order, user: user, status: :shipped)
    end

    it 'returns counts per status' do
      result, total = Order.count_order_with_status(1.month.ago, Time.current)
      expect(result[:paid]).to eq(2)
      expect(total).to eq(3)
    end
  end

  describe '#order_items_str' do
    let(:vitamin) { create(:product, name: 'Витамин С') }
    let!(:vitamin_item) { create(:order_item, order: order, product: vitamin) }

    it 'excludes delivery for courier' do
      expect(order.order_items_str(true)).not_to include('Доставка')
    end

    it 'includes prices for non-courier' do
      expect(order.order_items_str).to include('₽')
    end
  end

  describe 'ransackable' do
    it 'returns correct ransackable attributes' do
      expect(Order.ransackable_attributes).to match_array(%w[id status total_amount updated_at created_at])
    end

    it 'returns correct ransackable associations' do
      expect(Order.ransackable_associations).to match_array(%w[user])
    end
  end
end
