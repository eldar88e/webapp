module Admin
  module OrdersHelper
    STATUS_CLASSES = {
      'unpaid' => 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
      'paid' => 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
      'processing' => 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
      'shipped' => 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
      'cancelled' => 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
      'refunded' => 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300',
      'overdue' => 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300'
    }.freeze

    def order_status_class(status)
      STATUS_CLASSES.fetch(status, 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300')
    end
  end
end
