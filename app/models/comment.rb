class Comment < ApplicationRecord
  ADMIN_ID = 12

  belongs_to :task
  belongs_to :user

  validates :body, presence: true

  after_create_commit :notify

  private

  def notify
    msg = "#{user.full_name} добавил(а) комментарий к задаче «#{task.title}»"
    notify_user(task.assignee, msg)
    notify_writer(msg)
    notify_admin(msg)
  end

  def notify_writer(msg)
    notify_user(task.user, msg) if task.user.id != task.assignee.id
  end

  def notify_admin(msg)
    notify_user(User.find(ADMIN_ID), msg) if [task.assignee.id, task.user.id].exclude? ADMIN_ID
  end

  def notify_user(recipient, msg)
    recipient.messages.create(text: msg, is_incoming: false) if user.id != recipient.id
  end
end
