module Admin
  class PurchasesController < Admin::ApplicationController
    before_action :set_purchase, only: %i[edit update destroy]
    before_action :set_products, only: %i[new edit]

    FIRST_PURCHASE_ID = 1

    def index
      purchases         = Purchase.includes(purchase_items: :product).order(:created_at)
      purchases         = purchases.where.not(id: FIRST_PURCHASE_ID) if params[:page].nil? || params[:page] == '1'
      @q_purchases      = purchases.ransack(params[:q])
      @pagy, @purchases = pagy(@q_purchases.result)
    end

    def show
      @purchase = Purchase.find(params[:id])
      render turbo_stream: [
        turbo_stream.update(:modal_title, "Закупка №#{@purchase.id}"),
        turbo_stream.update(:modal_body, partial: '/admin/purchases/show')
      ]
    end

    def new
      @purchase = Purchase.new
      @purchase.purchase_items.build
      # @purchase.build_expense
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить закупку'),
        turbo_stream.update(:modal_body, partial: '/admin/purchases/form', locals: { method: :post })
      ]
    end

    def edit
      @purchase.purchase_items.build if @purchase.purchase_items.empty?
      # @purchase.build_expense if @purchase.expense.blank?
      render turbo_stream: [
        turbo_stream.update(:modal_title, "Редактировать закупку №#{@purchase.id}"),
        turbo_stream.update(:modal_body, partial: '/admin/purchases/form', locals: { method: :patch })
      ]
    end

    def create
      @purchase = Purchase.new(purchase_params)

      if @purchase.save
        redirect_to admin_purchases_path, notice: t('.create')
      else
        error_notice @purchase.errors.full_messages
      end
    end

    def update
      if @purchase.update(purchase_params)
        redirect_to admin_purchases_path, notice: t('.update')
      else
        error_notice @purchase.errors.full_messages
      end
    end

    def destroy
      @purchase.destroy!
      redirect_to admin_purchases_path, status: :see_other, notice: t('.destroy')
    end

    private

    def set_purchase
      @purchase = Purchase.find(params[:id])
    end

    def purchase_params
      # params.expect(purchase: [
      #                 :notes, :status, :send_to_supplier,
      #                 { purchase_items_attributes: %i[id product_id quantity unit_cost _destroy],
      #                   expenses_attributes: %i[id amount description _destroy] }
      #               ])

      # rubocop:disable Rails/StrongParametersExpect
      params.require(:purchase).permit(
        :notes,
        :status,
        :send_to_supplier,
        purchase_items_attributes: %i[id product_id quantity unit_cost _destroy],
        expenses_attributes: %i[id amount description _destroy]
      )
      # rubocop:enable Rails/StrongParametersExpect
    end

    def set_products
      @products = Product.available.where.not(ancestry: nil)
    end
  end
end
