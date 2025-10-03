module Admin
  module TasksHelper
    STATUS_CLASSES = {
      'lowest' => 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
      'low' => 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
      'medium' => 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
      'high' => 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
    }.freeze

    def task_priority_class(status)
      STATUS_CLASSES.fetch(status, 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300')
    end
  end
end
