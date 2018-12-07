require 'bundler'
Bundler.require(:default, :test)
require './main.rb'
require 'yaml'

YAML.load_file('.env').each do |key, var|
  ENV[key] = var
end

task :default => [:package]

task :test do |t|
  context = YAML.load_file('test/context')
  lambda = LambdaFunctions::Handler.new()

  Dir.glob('test/*.yml') do |file|
    event = YAML.load_file(file)
    LambdaFunctions::Handler.process(context: context, event: event)
  end
end


task :package do |t|
  Bundler.with_clean_env do
    # sh "bundle install --path vendor/bundle --without test development"
    sh "bundle install --path vendor/bundle"
  end

  Dir.mkdir 'pkg' rescue nil
  %x(zip -rv pkg/lambda-cloudwatch-slack-#{Time.now().to_i}.zip main.rb Gemfile* vendor)
end