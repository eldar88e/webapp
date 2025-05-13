require 'rails_helper'

RSpec.describe "Cart", type: :system do
  fixtures :users, :products, :settings, :account_tiers
  let(:product) { Product.find(3) }
  let(:product_two) { Product.find(4) }

  before do
    driven_by(:selenium_headless) # selenium_chrome rack_test selenium_headless
    login_as users(:customer), scope: :user
    visit root_path
  end

  describe 'when buy products' do
    before do
      find("#cart-btn-#{product.id}").click_button
    end

    it "have one product in cart" do
      users(:customer).cart.cart_items.reload
      cart_item = users(:customer).cart.cart_items.find_by(product_id: product.id)
      total     = (product.price * cart_item.quantity).to_i

      within('#cart-summary') do
        expect(find('.cart-counter')).to have_content(cart_item.quantity)
        expect(page).to have_content("Корзина #{total} ₽")
        expect(page).to have_content('Перейти в корзину')
      end
    end

    it 'have two product in cart' do
      find("#cart-btn-#{product_two.id}").click_button
      within("#cart-btn-#{product.id}") do
        find('button:has(.buy-btn .plus-ico)').click
        sleep 0.1
        find('button:has(.buy-btn .plus-ico)').click
        sleep 0.1
        find('button:has(.buy-btn .plus-ico)').click
        sleep 0.1
        find('button:has(.buy-btn .minus-ico)').click
      end

      users(:customer).cart.cart_items.reload
      expect(users(:customer).cart.cart_items.size).to eq(2)

      total = users(:customer).cart.cart_items.sum { |i| i.product.price * i.quantity }.to_i
      count = users(:customer).cart.cart_items.sum { |i| i.quantity }

      within('#cart-summary') do
        expect(find('.cart-counter')).to have_content(count)
        expect(page).to have_content("Корзина #{total} ₽")
        expect(page).to have_content('Перейти в корзину')
      end

      cart_item = users(:customer).cart.cart_items.find_by(product_id: product.id)

      within("#cart-btn-#{product.id}") do
        expect(find('.count')).to have_content("#{cart_item.quantity} шт")
        expect(find('.total')).to have_content("#{(cart_item.quantity * product.price).to_i}₽")
      end
    end
  end

  it 'have two category' do
    within('.catalog-nav') do
      expect(find('a.active')).to have_content("#{product.parent.name}")
      expect(all('a').size).to eq(Product.find(Setting.fetch_value(:root_product_id)).children.size)
    end
  end
end
