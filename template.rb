# rm -rf app; rails new app --webpack=vue -d=mysql -m template.rb
def source_paths
  Array(super) +
    [File.expand_path(File.dirname(__FILE__))]
end

# file
copy_file "Dockerfile"
copy_file "docker-compose.yml"
remove_file ".gitignore"
copy_file ".gitignore"

# bin
run('cp ../bin/server bin')

# config
inside 'config' do
  remove_file 'database.yml'
  create_file 'database.yml' do <<-EOF
default: &default
  adapter: mysql2
  encoding: utf8mb4
  charset: utf8mb4
  collation: utf8mb4_general_ci
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV['RAILS_DATABASE_URL'] %>

development:
  <<: *default
  database: #{app_name}_development

test:
  <<: *default
  database: #{app_name}_test

staging:
  <<: *default
  database: #{app_name}_staging

production:
  <<: *default
  database: #{app_name}_production

EOF
  end
end
initializer 'faker.rb', <<-CODE
  Faker::Config.locale = :ja
CODE
environment '  config.webpacker.check_yarn_integrity = false', env: 'development'

# gem
#gem "foreman"
gem "faker"
gem 'jquery-rails'
gem 'materialize-sass'
gem 'material_icons'
gem 'mysql2'

gem_group :development, :test do
  gem "rspec-rails"
end

after_bundle do
  # seeds
  run("rm db/seeds.rb")
  file 'db/seeds.rb', <<-CODE
  require 'faker'

  Product.destroy_all
  10.times { p Product.create!(name: Faker::Pokemon.name, price: rand(100) + 1000, content: Faker::Lorem.sentence ) }
  CODE

  # app
  run("docker-compose build")
  #run("docker-compose run web bundle install")
  run("docker-compose run web bundle exec rails g scaffold products name:string price:integer content:text")
  run("docker-compose run web bundle exec rake db:drop db:create db:migrate db:seed")
  run('mkdir app/controllers/api')
  run('cp app/controllers/products_controller.rb app/controllers/api')
  insert_into_file 'config/routes.rb', after: "# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html\n" do <<-RUBY
    namespace :api, format: :json do
      resources :products, only: [:index, :create, :update]
    end
  RUBY
  end
  gsub_file 'app/controllers/application_controller.rb', /protect_from_forgery/, '# protect_from_forgery'

  # git
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"
end
