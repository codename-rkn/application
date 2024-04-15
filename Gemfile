# frozen_string_literal: true

source "https://rubygems.org"

if File.exist? '../../scnr/license-client'
    gem 'scnr-license-client', path: '../../scnr/license-client'
end

if File.exist? '../../scnr/application'
    gem 'scnr-application', path: '../../scnr/application'
end

if File.exist? '../scnr/engine'
    gem 'scnr-engine', path: '../../scnr/engine'
end

# Specify your gem's dependencies in application.gemspec
gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
