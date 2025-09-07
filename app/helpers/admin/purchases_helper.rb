module Admin
  module PurchasesHelper
    STATUS_CLASSES = {
      'initialized' => 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
      'sent_to_supplier' => 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
      'shipped' => 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300',
      'stocked' => 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
      'cancelled' => 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
    }.freeze

    def purchase_status_style(status)
      start = STATUS_CLASSES.fetch(status, 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300')
      "#{start} text-xs font-medium me-2 px-2.5 py-0.5 rounded"
    end
  end
end
