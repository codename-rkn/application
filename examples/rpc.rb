#!/usr/bin/env ruby
require_relative '../lib/rkn/application'

agent    = RKN::Application.spawn( :agent, daemonize: true, stdout: '/dev/null', stderr: '/dev/null' )
at_exit { Cuboid::Processes::Manager.kill agent.pid }

instance = RKN::Application.connect( agent.spawn )
at_exit { instance.shutdown }

print 'Scanning.'
instance.run(
    url:    'https://ginandjuice.shop/',
    audit:  {
      elements: [:links, :forms, :cookies, :headers, :jsons, :xmls, :ui_inputs, :ui_forms]
    }
)

seen_entries = []
while instance.running?
    print '.'

    # progress = instance.scan.progress(
    #   with:    [:errors],
    #   without: { seen_entries: seen_entries }
    # )
    # progress['entries'].keys.each { |k| seen_entries << k }
    # pp progress

    sleep 1
end

entries = instance.generate_report.data['entries']

per_action = {}
entries.each do |entry|
    per_action[entry['action']] ||= []
    per_action[entry['action']] << entry
end

pp '-' * 88

pp per_action
