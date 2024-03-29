require 'stomp'

module MCollective
    module Connector
        # Handles sending and receiving messages over the Stomp protocol
        class Stomp<Base
            attr_reader :connection

            def initialize
                @config = Config.instance

                @log = Log.instance
            end

            # Connects to the Stomp middleware
            def connect
                begin
                    host = nil
                    port = nil
                    user = nil
                    password = nil

                    if ENV.include?("STOMP_SERVER") 
                        host = ENV["STOMP_SERVER"]
                    else
                        raise("No STOMP_SERVER environment or plugin.stomp.host configuration option given") unless @config.pluginconf.include?("stomp.host")
                        host = @config.pluginconf["stomp.host"]
                    end

                    if ENV.include?("STOMP_PORT") 
                        port = ENV["STOMP_PORT"]
                    else
                        @config.pluginconf.include?("stomp.port") ? port = @config.pluginconf["stomp.port"].to_i : port = 6163
                    end

                    if ENV.include?("STOMP_USER") 
                        user = ENV["STOMP_USER"]
                    else
                        user = @config.pluginconf["stomp.user"] if @config.pluginconf.include?("stomp.user") 
                    end

                    if ENV.include?("STOMP_PASSWORD") 
                        password = ENV["STOMP_PASSWORD"]
                    else
                        password = @config.pluginconf["stomp.password"] if @config.pluginconf.include?("stomp.password")
                    end


                    @log.debug("Connecting to #{host}:#{port}")
                    @connection = ::Stomp::Connection.new(user, password, host, port, true)
                rescue Exception => e
                    raise("Could not connect to Stomp Server '#{host}:#{port}' #{e}")
                end
            end

            # Receives a message from the Stomp connection
            def receive
                @log.debug("Waiting for a message from Stomp")
                msg = @connection.receive

                # STOMP puts the payload in the body variable, pass that
                # into the payload of MCollective::Request and discard all the 
                # other headers etc that stomp provides
                Request.new(msg.body)
            end

            # Sends a message to the Stomp connection
            def send(target, msg)
                @log.debug("Sending a message to Stomp target '#{target}'")
                @connection.send(target, msg)
            end

            # Subscribe to a topic or queue
            def subscribe(source)
                @log.debug("Subscribing to #{source}")
                @connection.subscribe(source)
            end

            # Subscribe to a topic or queue
            def unsubscribe(source)
                @log.debug("Unsubscribing from #{source}")
                @connection.unsubscribe(source)
            end

            # Disconnects from the Stomp connection
            def disconnect
                @log.debug("Disconnecting from Stomp")
                @connection.disconnect
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
