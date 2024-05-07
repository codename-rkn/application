# frozen_string_literal: true

source "https://rubygems.org"

if File.exist? '../../ecsypno/license-client'
    gem 'ecsypno-license-client', path: '../../ecsypno/license-client'
else
    gem 'ecsypno-license-client'
end

if File.exist? '../../scnr/application'
    gem 'scnr-application', path: '../../scnr/application'
end

if File.exist? '../scnr/engine'
    gem 'scnr-engine', path: '../../scnr/engine'
end

if File.exist? '../rkn'
    gem 'rkn', path: '../rkn'
end

# Specify your gem's dependencies in rkn-application.gemspec
gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
