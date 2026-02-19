class BotUser
  include ActiveModel::API

  def first_name = 'Бот'
  def photo_url = ViteRuby.instance.manifest.path_for('images/admin/logo_s.jpg')

  def self.instance
    @instance ||= new.freeze
  end
end
