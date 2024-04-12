# frozen_string_literal: true

require 'scnr/application'

module RKN
class Application < ::Cuboid::Application
    require_relative 'application/rpc_proxy'

    provision_cores  2
    provision_memory 2 * 1024 * 1024 * 1024
    provision_disk   4 * 1024 * 1024 * 1024

    validate_options_with :validate_options

    handler_for :pause,   :do_pause
    handler_for :resume,  :do_resume
    handler_for :abort,   :do_abort

    instance_service_for :scan,  RPCProxy

    serialize_with Marshal

    attr_reader :entries

    def initialize(*)
        super

        @api  = SCNR::Application::API.new
        @entries = {}

        setup_hooks
        load_sink_trace_force_check
    end

    def run
        @api.scan.run
        report @entries.values.flatten
    end

    def validate_options( options )
        options = options.dup
        @api.scan.options.set options
        true
    rescue SCNR::Engine::Options::Error
        false
    end

    def errors
        @errors
    end

    def do_pause
        @api.scan.pause!
    end

    def do_resume
        @api.scan.resume!
    end

    def do_abort
        @api.scan.abort!
        report @entries.values.flatten
    end

    private

    def setup_hooks
        SCNR::Engine::Element::Capabilities::WithSinks::Sinks::Tracers::Fuzz.on_sinks do |seed, mutation, resource|
            @entries[mutation.coverage_and_trace_hash] = prepare_entry( seed, mutation, resource )
        end

        SCNR::Engine::Element::Capabilities::WithSinks::Sinks::Tracers::Differential.on_sinks do |seed, mutation|
            @entries[mutation.coverage_and_trace_hash] = prepare_entry( seed, mutation )
        end

        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks::Tracers::Fuzz.on_sinks do |seed, mutation, resource|
            @entries[mutation.coverage_and_trace_hash] = prepare_entry( seed, mutation, resource )
        end
    end
    
    def load_sink_trace_force_check
        SCNR::Engine::Element::Capabilities::WithSinks::Sinks.add_to_max_cost Float::INFINITY
        SCNR::Engine::Element::Capabilities::WithSinks::Sinks.enable_all

        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.add_to_max_cost Float::INFINITY
        SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.enable_all

        check = Class.new( SCNR::Engine::Check::Base )
        check.shortname = 'sink_trace_force'

        check.define_method :run, &proc {}
        check.define_singleton_method :info, &proc {{
          elements: SCNR::Engine::Check::Auditor::ELEMENTS_WITH_INPUTS,
          sink:     { areas: SCNR::Engine::Element::Capabilities::WithSinks::Sinks.enabled.to_a }
        }}

        SCNR::Engine::Framework.unsafe.checks[check.shortname] = check

        check = Class.new( SCNR::Engine::Check::Base )
        check.shortname = 'sink_trace_force_dom'

        check.define_method :run, &proc {}
        check.define_singleton_method :info, &proc {{
          elements: SCNR::Engine::Check::Auditor::DOM_ELEMENTS_WITH_INPUTS,
          sink:     { areas: SCNR::Engine::Element::DOM::Capabilities::WithSinks::Sinks.enabled.to_a }
        }}

        SCNR::Engine::Framework.unsafe.checks[check.shortname] = check
    end

    def prepare_entry( seed, mutation, resource = nil )
        entry = {
          seed:      seed,
          mutation:  prepare_mutation( mutation ),
          sinks:     prepare_sinks( mutation ),
          action:    mutation.action
        }

        case resource
            when SCNR::Engine::Page
                entry[:page]      = prepare_page( resource )
                entry[:platforms] = resource.platforms.to_a

            when SCNR::Engine::HTTP::Response
                entry[:response]  = resource.to_h
                entry[:platforms] = resource.to_page.platforms.to_a

            else
                entry[:platforms] = SCNR::Engine::Platform::Manager[mutation.action].to_a
        end

        entry[:platforms] = entry[:platforms].map(&:to_s)

        entry
    end

    def prepare_mutation( mutation )
        mutation.dup.tap { |m| m.auditor = nil }.to_h.merge( page: prepare_page( mutation.page ) )
    end

    def prepare_page( page )
        h = page.to_h

        [:links, :forms, :cookies, :headers, :xmls, :jsons, :link_templates, :ui_inputs, :ui_forms, :cookie_jar, :cache,
         :document, :parser, :paths, :metadata, :has_javascript, :element_audit_whitelist].each do |k|
            h.delete k
        end

        h
    end

    def prepare_sinks( mutation )
        sinks = {}
        mutation.sinks.per_input.each do |input, s|
            sinks[input] = s.map(&:to_s)
        end
        sinks
    end

end
end
