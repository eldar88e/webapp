require 'rails_helper'

RSpec.describe "Cart", type: :system do
  fixtures :users, :products, :settings, :account_tiers
  let(:product) { Product.find(3) }
  let(:product_two) { Product.find(4) }
  let(:user) { users(:customer) }

  before do
    driven_by(:selenium_headless) # selenium_chrome rack_test selenium_headless
    page.driver.browser.manage.window.resize_to(430, 932) # iphone 14 pro max
    login_as user

    cart = user.cart
    cart.cart_items.create!(product: product, quantity: 2)
    cart.cart_items.create!(product: product_two, quantity: 1)

    visit carts_path
  end

  describe 'when change quantity item' do
    it "without delivery" do
      cart_items = user.cart.cart_items
      find("#cart-item-#{cart_items.first.id} button:has(.minus-ico)", wait: 3).click
      sleep 0.1
      find("#cart-item-#{cart_items.second.id} button:has(.minus-ico)").click

      cart_items.reload
      count = cart_items.reduce(0) { |sum, i| i.quantity + sum }
      total_price = cart_items.sum { |i| i.product.price * i.quantity }.to_i

      expect(find('#cart-items-count')).to have_content(count)
      expect(find('#cart-total-price')).to have_content("#{total_price}₽")
      expect(find('#cart-delivery-price')).to have_content("#{settings(:delivery_price).value}₽")
      expect(find('#cart-final-price')).to have_content("#{total_price + settings(:delivery_price).value.to_i}₽")
    end

    it "with delivery" do
      cart_items = user.cart.cart_items
      find("#cart-item-#{cart_items.first.id} button:has(.plus-ico)", wait: 3).click
      sleep 0.1
      find("#cart-item-#{cart_items.second.id} button:has(.plus-ico)").click
      sleep 0.1
      find("#cart-item-#{cart_items.first.id} button:has(.minus-ico)").click

      cart_items.reload
      count = cart_items.reduce(0) { |sum, i| i.quantity + sum }
      total_price = cart_items.sum { |i| i.product.price * i.quantity }.to_i

      expect(find('#cart-items-count')).to have_content(count)
      expect(find('#cart-total-price')).to have_content("#{total_price}₽")
      expect(find('#cart-delivery-price')).to have_content('0₽')
      expect(find('#cart-final-price')).to have_content("#{total_price}₽")
    end
  end
end
