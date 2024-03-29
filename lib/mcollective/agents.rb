module MCollective
    # A collection of agents, loads them, reloads them and dispatches messages to them.
    # It uses the PluginManager to store, load and manage instances of plugins.
    class Agents
        def initialize
            @config = Config.instance
            raise ("Configuration has not been loaded, can't load agents") unless @config.configured

            @log = Log.instance
            @@agents = {}

            loadagents
        end

        # Loads all agents from disk
        def loadagents
            @log.debug("Reloading all agents from disk")

            # We're loading all agents so just nuke all the old agents and unsubscribe
            connector = PluginManager["connector_plugin"]
            @@agents.each_key do |agent|
                connector.unsubscribe(Util.make_target(agent, :command))
            end

            @@agents = {}

            agentdir = "#{@config.libdir}/mcollective/agent"
            raise("Cannot find agents directory") unless File.directory?(agentdir)

            Dir.new(agentdir).grep(/\.rb$/).each do |agent|
                agentname = File.basename(agent, ".rb")
                loadagent(agentname)
            end
        end

        # Loads a specified agent from disk if available
        def loadagent(agentname)
            agentfile = "#{@config.libdir}/mcollective/agent/#{agentname}.rb"
            classname = "MCollective::Agent::#{agentname.capitalize}"

            return false unless File.exist?(agentfile)

            PluginManager.delete("#{agentname}_agent") 
            PluginManager.loadclass(classname)
            PluginManager << {:type => "#{agentname}_agent", :class => classname}

            PluginManager["connector_plugin"].subscribe(Util.make_target(agentname, :command)) unless @@agents.include?(agentname)

            @@agents[agentname] = {:file => agentfile}
            true
        end

        # Determines if we have an agent with a certain name
        def include?(agentname)
            PluginManager.include?("#{agentname}_agent")
        end

        # Sends a message to a specific agent
        def send(agentname, msg, connection)
            raise("No such agent") unless include?(agentname)

            PluginManager["#{agentname}_agent"].handlemsg(msg, connection)
        end

        # Returns the help for an agent after first trying to get
        # rid of some indentation infront
        def help(agentname)
            raise("No such agent") unless include?(agentname)

            body = PluginManager["#{agentname}_agent"].help.split("\n")

            if body.first =~ /^(\s+)\S/
                indent = $1

                body = body.map {|b| b.gsub(/^#{indent}/, "")}
            end

            body.join("\n")
        end

        # Determine the max amount of time a specific agent should be running
        def timeout(agentname)
            raise("No such agent") unless include?(agentname)

            PluginManager["#{agentname}_agent"].timeout
        end

        # Dispatches a message to an agent, accepts a block that will get run if there are
        # any replies to process from the agent
        def dispatch(msg, target, connection)
            @log.debug("Dispatching a message to agent #{target}")

            Thread.new do
                begin
                    Timeout::timeout(timeout(target)) do
                        replies = send(target, msg, connection)

                        # Agents can decide if they wish to reply or not,
                        # returning nil will mean nothing goes back to the
                        # requestor
                        unless replies == nil
                            yield(replies)
                        end
                    end
                rescue Timeout::Error => e
                    @log.warn("Timeout while handling message for #{target}")
                rescue Exception => e
                    @log.error("Execution of #{target} failed: #{e}")
                end
            end
        end

        # Get a list of agents that we have
        def self.agentlist
            @@agents.keys
        end
    end
end

# vi:tabstop=4:expandtab:ai
