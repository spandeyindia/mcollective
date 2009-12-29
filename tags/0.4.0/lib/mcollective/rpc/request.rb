module MCollective
    module RPC 
        # Simple class to manage compliant requests for MCollective::RPC agents
        class Request
            attr_accessor :time, :action, :data, :sender, :agent

            def initialize(msg)
                @time = msg[:msgtime]
                @action = msg[:body][:action]
                @data = msg[:body][:data]
                @sender = msg[:senderid]
                @agent = msg[:body][:agent]
            end

            # If data is a hash, quick helper to get access to it's include? method
            # else returns false
            def include?(key)
                return false unless @data.is_a?(Hash)
                return @data.include?(key)
            end

            # If data is a hash, gives easy access to its members, else returns nil
            def [](key)
                return nil unless @data.is_a?(Hash)
                return @data[key]
            end

            def to_hash
                return {:agent => @agent,
                        :action => @action,
                        :data => @data}
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
