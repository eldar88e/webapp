module Admin
  module PaymentTransactionsHelper
    STATUS_CLASSES = {
      'created' => 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
      'initialized' => 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
      'paid' => 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
      'checking' => 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300',
      'approved' => 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',

      'cancelled' => 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
      'failed' => 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300',
      'overdue' => 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300'
    }.freeze

    def payment_status_class(status)
      STATUS_CLASSES.fetch(status, 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300')
    end
  end
end
