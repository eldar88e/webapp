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
    describe '#remove_cart' do
      let!(:cart) { create(:cart, user: user) }

      it 'destroys user cart when status changes from unpaid to paid' do
        expect {
          order.update!(status: :paid)
        }.to change(Cart, :count).by(-1)
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
          binding.pry
          product.update!(stock_quantity: 1)
          order.update!(status: :paid)
          binding.pry
        end

        it 'raises error and sends notification' do
          expect { order.update!(status: :processing) }.to raise_error(StandardError, /Недостаток в остатках/)
          binding.pry
          expect(TelegramJob).to have_received(:perform_later)
        end
      end
    end


  end


end
