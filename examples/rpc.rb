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

sinks_seen = []
while instance.running?
    pp '-' * 88

    progress = instance.scan.progress(
      with:    [:errors],
      without: { sinks: sinks_seen }
    )
    progress['sinks'].keys.each { |k| sinks_seen << k }

    pp progress

    sleep 1
end
puts
pp report = instance.generate_report.data
pp report.finish_datetime - report.start_datetime
