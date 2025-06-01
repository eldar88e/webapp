module Api
  module V1
    class ProductsController < Api::V1::BaseController
      def index
        @products = Product.all
        render json: @products
      end
    end
  end
end
