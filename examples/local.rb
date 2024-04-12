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

while !application.done?
    print '.'
    sleep 1
end

per_action = {}
application.generate_report.data.each do |entry|
    per_action[entry[:action]] ||= []
    per_action[entry[:action]] << entry
end

pp '-' * 88

pp per_action
