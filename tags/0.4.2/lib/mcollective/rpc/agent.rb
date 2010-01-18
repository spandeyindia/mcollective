module MCollective
    module RPC
        # A wrapper around the traditional agent, it takes care of a lot of the tedious setup
        # you would do for each agent allowing you to just create methods following a naming 
        # standard leaving the heavy lifting up to this clas.
        #
        # See http://code.google.com/p/mcollective/wiki/SimpleRPCAgents
        #
        # It only really makes sense to use this with a Simple RPC client on the other end, basic
        # usage would be:
        #
        #    module MCollective
        #       module Agent
        #          class Helloworld<RPC::Agent
        #              def echo_action
        #                  validate :msg, String
        #                  
        #                  reply.data = request[:msg]              
        #              end
        #          end
        #       end
        #    end
        #
        # We also currently have the validation code in here, this will be moved to plugins soon.
        class Agent
            attr_accessor :meta, :reply, :request
            attr_reader :logger, :config, :timeout

            def initialize
                @timeout = 10
                @logger = Log.instance
                @config = Config.instance

                @meta = {:license => "Unknown",
                         :author => "Unknown",
                         :version => "Unknown",
                         :url => "Unknown"}

                startup_hook
            end
                
            def handlemsg(msg, connection)
                @request = RPC.request(msg)
                @reply = RPC.reply

                begin
                    before_processing_hook(msg, connection)

                    if respond_to?("#{@request.action}_action")
                        send("#{@request.action}_action")
                    else
                        raise UnknownRPCAction, "Unknown action: #{@request.action}"
                    end
                rescue UnknownRPCAction => e
                    @reply.fail e.to_s, 2

                rescue MissingRPCData => e
                    @reply.fail e.to_s, 3

                rescue InvalidRPCData => e
                    @reply.fail e.to_s, 4

                rescue UnknownRPCError => e
                    @reply.fail e.to_s, 5

                end

                after_processing_hook

                @reply.to_hash
            end

            def help
                "Unconfigure MCollective::RPC::Agent"
            end

            private
            # Validates a data member, if validation is a regex then it will try to match it
            # else it supports testing object types only:
            #
            # validate :msg, String
            # validate :msg, /^[\w\s]+$/
            #
            # It will raise appropriate exceptions that the RPC system understand
            #
            # TODO: this should be plugins, 1 per validatin method so users can add their own
            #       at the moment i have it here just to proof the point really
            def validate(key, validation)
                raise MissingRPCData, "please supply a #{key}" unless @request.include?(key)

                begin
                    if validation.is_a?(Regexp)
                        raise InvalidRPCData, "#{key} should match #{regex}" unless @request[key].match(validation)

                    elsif validation.is_a?(Symbol)
                        case validation
                            when :shellsafe
                                raise InvalidRPCData, "#{key} should be a String" unless @request[key].is_a?(String)
                                raise InvalidRPCData, "#{key} should not have > in it" if @request[key].match(/>/) 
                                raise InvalidRPCData, "#{key} should not have < in it" if @request[key].match(/</) 
                                raise InvalidRPCData, "#{key} should not have \` in it" if @request[key].match(/\`/) 
                                raise InvalidRPCData, "#{key} should not have | in it" if @request[key].match(/\|/) 


                            when :ipv6address
                                begin
                                    require 'ipaddr'
                                    ip = IPAddr.new(@request[key])
                                    raise InvalidRPCData, "#{key} should be an ipv6 address" unless ip.ipv6?
                                rescue
                                    raise InvalidRPCData, "#{key} should be an ipv6 address"
                                end

                            when :ipv4address
                                begin
                                    require 'ipaddr'
                                    ip = IPAddr.new(@request[key])
                                    raise InvalidRPCData, "#{key} should be an ipv4 address" unless ip.ipv4?
                                rescue
                                    raise InvalidRPCData, "#{key} should be an ipv4 address"
                                end

                        end
                    else
                        raise InvalidRPCData, "#{key} should be a #{validation}" unless  @request.data[key].is_a?(validation)
                    end
                rescue Exception => e
                    raise UnknownRPCError, "Failed to validate #{key}: #{e}"
                end
            end

            # Called at the end of the RPC::Agent standard initialize method
            # use this to adjust meta parameters, timeouts and any setup you 
            # need to do.
            #
            # This will not be called right when the daemon starts up, we use
            # lazy loading and initialization so it will only be called the first
            # time a request for this agent arrives.
            def startup_hook
            end

            # Called just after a message was received from the middleware before
            # it gets passed to the handlers.  @request and @reply will already be
            # set, the msg passed is the message as received from the normal
            # mcollective runner and the connection is the actual connector.
            def before_processing_hook(msg, connection)
            end

            # Called at the end of processing just before the response gets sent
            # to the middleware.
            #
            # This gets run outside of the main exception handling block of the agent
            # so you should handle any exceptions you could raise yourself.  The reason 
            # it is outside of the block is so you'll have access to even status codes
            # set by the exception handlers.  If you do raise an exception it will just
            # be passed onto the runner and processing will fail.
            def after_processing_hook
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai