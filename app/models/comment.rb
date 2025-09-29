class Comment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :body, presence: true

  after_create_commit :notify

  private

  def notify
    msg = "#{user.full_name} добавил(а) комментарий к задаче «#{task.title}»"
    notify_user(task.assignee, msg)
    notify_user(task.user, msg)
  end

  def notify_user(recipient, msg)
    recipient.messages.create(text: msg, is_incoming: false) if user.id != recipient.id
  end
end
