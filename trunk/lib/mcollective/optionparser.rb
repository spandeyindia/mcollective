module MCollective
    # A simple helper to build cli tools that supports a uniform command line 
    # layout.  
    class Optionparser
        # Creates a new instance of the parser, you can supply defaults and include named groups of options.
        #
        # Starts a parser that defaults to verbose and that includs the filter options:
        #
        #  oparser = MCollective::Optionparser.new({:verbose => true}, "filter") 
        #
        # Stats a parser in non verbose mode that does support discovery
        #  oparser = MCollective::Optionparser.new() 
        #
        def initialize(defaults = {}, include = "")
            @parser = OptionParser.new
            @include = include

            @options = {:disctimeout => 2,
                        :timeout     => 5,
                        :verbose     => false,
                        :filter      => {},
                        :config      => "/etc/mcollective/client.cfg"}

            @options.merge!(defaults)
        end

        # Parse the options returning the options, you can pass a block that adds additional options
        # to the Optionparser.
        #
        # The sample below starts a parser that also prompts for --arguments in addition to the defaults. 
        # It also sets the description and shows a usage message specific to this app.
        #
        #  options = oparser.parse{|parser, options|
        #       parser.define_head "Control the mcollective controller daemon"
        #       parser.banner = "Usage: sh-mcollective [options] command"
        #
        #       parser.on('--arg', '--argument ARGUMENT', 'Argument to pass to agent') do |v|
        #           options[:argument] = v
        #       end
        #  }
        def parse(&block)
            yield(@parser, @options) if block_given?

            add_common_options

            @include.each do |i|
                eval("add_#{i}_options")
            end

            @parser.parse!

            @options
        end

        # These options will be added if you pass 'filter' into the include list of the 
        # constructor.
        def add_filter_options
            @parser.separator ""
            @parser.separator "Host Filters"

            @parser.on('--wf', '--with-fact fact=val', 'Match hosts with a certain fact') do |f|
                @options[:filter]["fact"] = {:fact => $1, :value => $2} if f =~ /^(.+?)=(.+)/
            end

            @parser.on('--wc', '--with-class CLASS', 'Match hosts with a certain puppet class') do |f|
                @options[:filter]["puppet_class"] = f
            end

            @parser.on('--wa', '--with-agent AGENT', 'Match hosts with a certain agent') do |a|
                @options[:filter]["agent"] = a
            end

            @parser.on('--wi', '--with-identity IDENT', 'Match hosts with a certain configured identity') do |a|
                @options[:filter]["identity"] = a
            end
        end

        # These options will be added to all cli tools
        def add_common_options
            @parser.separator ""
            @parser.separator "Common Options"

            @parser.on('-c', '--config FILE', 'Load configuratuion from file rather than default') do |f|
                @options[:config] = f
            end

            @parser.on('--dt', '--discovery-timeout SECONDS', Integer, 'Timeout for doing discovery') do |t|
                @options[:disctimeout] = t
            end

            @parser.on('-t', '--timeout SECONDS', Integer, 'Timeout for calling remote agents') do |t|
                @options[:timeout] = t
            end

            @parser.on('-q', '--quiet', 'Do not be verbose') do |v|
                @options[:verbose] = false
            end

            @parser.on('-v', '--verbose', 'Be verbose') do |v|
                @options[:verbose] = v
            end

            @parser.on('-h', '--help', 'Display this screen') do
                puts @parser
                exit! 1
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
