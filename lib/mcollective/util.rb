module MCollective
    # Some basic utility helper methods useful to clients, agents, runner etc.
    class Util
        # Finds out if this MCollective has an agent by the name passed
        def self.has_agent?(agent)
            agent = Regexp.new(agent.gsub("\/", "")) if agent.match("^/")

            if agent.is_a?(Regexp)
                if Agents.agentlist.grep(agent).size > 0
                    return true
                else
                    return false
                end
            else
                return Agents.agentlist.include?(agent)
            end

            false
        end

        # Checks if this node has a puppet class by parsing the 
        # puppet classes.txt
        def self.has_puppet_class?(klass)
            klass = Regexp.new(klass.gsub("\/", "")) if klass.match("^/")

            File.readlines("/var/lib/puppet/classes.txt").each do |k|
                if klass.is_a?(Regexp)
                    return true if k.chomp.match(klass)
                else
                    return true if k.chomp == klass
                end
            end

            false
        end

        # Gets the value of a specific fact, mostly just a duplicate of MCollective::Facts.get_fact
        # bt it kind of goes with the other classes here
        def self.get_fact(fact)
            Facts.get_fact(fact)
        end

        # Compares fact == value, mostly just a duplicate of MCollective::Facts.get_fact
        # bt it kind of goes with the other classes here
        def self.has_fact?(fact, value)
            Facts.has_fact?(fact, value)
        end

        # Constructs the full target name based on topicprefix and topicsep config options
        def self.make_target(agent, type)
            config = Config.instance

            raise("Uknown target type #{type}") unless type == :command || type == :reply

            [config.topicprefix, agent, type].join(config.topicsep)
        end
    end
end

# vi:tabstop=4:expandtab:ai
