# require 'pagy/extras/i18n'
# require 'pagy/extras/overflow'

# Pagy::DEFAULT[:overflow] = :last_page

Pagy::I18n.pathnames << Rails.root.join('config/locales/pagy')
Pagy.translate_with_the_slower_i18n_gem!
