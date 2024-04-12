#!/usr/bin/env ruby
require_relative '../lib/rkn/application'

application = RKN::Application
application.options = {
    url:    'https://ginandjuice.shop/',
    # url:    'http://testhtml5.vulnweb.com/',
    audit:  {
      elements: [:links, :forms, :cookies, :headers, :jsons, :xmls, :ui_inputs, :ui_forms]
    }
}

Thread.new do
    application.run
end

while application.status != :done
    pp '-' * 88
    pp application.progress.dup

    sleep 1
end
