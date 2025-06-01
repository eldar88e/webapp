require 'rails_helper'

RSpec.describe "Root", type: :system do
  fixtures :users, :products, :settings, :account_tiers

  before do
    driven_by(:selenium_headless)
    login_as users(:jack), scope: :user
    visit root_path
  end

  it "no started user" do
    expect(find('h1')).to have_content('Пожалуйста, подождите, идет авторизация')
    sleep 4
    expect(find('h1')).to have_content('Произошла ошибка')
  end

  it "no started user" do
    users(:jack).update!(started: true)
    expect(find('h1')).to have_content('Каталог')
  end
end