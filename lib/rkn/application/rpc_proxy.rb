class RPCProxy

    def generate_session_snapshot
        scan.generate_session_snapshot
    end

    def progress( options = {}, &block )
        options = options.my_symbolize_keys

        without = options[:without] || {}
        without_entries = Set.new( without[:entries] || [] )

        block.call progress_handler( options ).
          merge( entries: RKN::Application.entries.reject { |k, _| without_entries.include? k } )
    end

    # @param    [Integer]   from_index
    #   Get sitemap entries after this index.
    #
    # @return   [Hash<String=>Integer>]
    def sitemap( from_index = 0 )
        scan.sitemap from_index
    end

    # @param    [Integer]   index
    #   Sets the starting line for the range of errors to return.
    #
    # @return   [Array<String>]
    def errors( index = 0 )
        scan.errors( index )
    end

    private

    def progress_handler( options = {} )
        with    = Cuboid::RPC::Server::Instance.parse_progress_opts( options, :with )
        without = Cuboid::RPC::Server::Instance.parse_progress_opts( options, :without )

        options = {
          statistics: !without.include?( :statistics )
        }

        if with.include?( :errors )
            options[:errors] = with[:errors]
        end

        if with.include?( :sitemap )
            options[:sitemap] = with[:sitemap]
        end

        scan_progress( options )
    end

    # Provides aggregated progress data.
    #
    # @param    [Hash]  opts
    #   Options about what data to include:
    # @option opts [Bool] :slaves   (true)
    #   Slave statistics.
    # @option opts [Bool] :issues   (true)
    #   Issue summaries.
    # @option opts [Bool] :statistics   (true)
    #   Master/merged statistics.
    # @option opts [Bool, Integer] :errors   (false)
    #   Logged errors. If an integer is provided it will return errors past that
    #   index.
    # @option opts [Bool, Integer] :sitemap   (false)
    #   Scan sitemap. If an integer is provided it will return entries past that
    #   index.
    # @option opts [Bool] :as_hash  (false)
    #   If set to `true`, will convert issues to hashes before returning them.
    #
    # @return    [Hash]
    #   Progress data.
    def scan_progress( opts = {} )
        include_statistics = opts[:statistics].nil? ? true : opts[:statistics]
        include_sitemap    = opts.include?( :sitemap ) ?
                               (opts[:sitemap] || 0) : false
        include_errors     = opts.include?( :errors ) ?
                               (opts[:errors] || 0) : false

        data = {
          status:  scan.status,
          running: scan.running?,
          seed:    SCNR::Engine::Utilities.random_seed,
        }

        if include_statistics
            data[:statistics] = scan.statistics
        end

        if include_sitemap
            data[:sitemap] = sitemap( include_sitemap )
        end

        if include_errors
            data[:errors] =
              errors( include_errors.is_a?( Integer ) ? include_errors : 0 )
        end

        data.merge( messages: scan.status_messages )
    end

    def scan
        SCNR::Application.api.scan
    end

end
