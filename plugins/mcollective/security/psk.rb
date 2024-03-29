module MCollective
    module Security
        # Impliments message authentication using digests and shared keys
        # 
        # You should configure a psk in the configuration file and all requests
        # will be validated for authenticity with this.
        #
        # Serialization uses Marshal, this is the default security module that is
        # supported out of the box.
        #
        # Validation is as default and is provided by MCollective::Security::Base
        class Psk < Base
            # Decodes a message by unserializing all the bits etc, it also validates
            # it as valid using the psk etc
            def decodemsg(msg)
                body = Marshal.load(msg.payload)
    
                if validrequest?(body)
                    body[:body] = Marshal.load(body[:body])
                    return body
                else
                    nil
                end
            end
            
            # Encodes a reply
            def encodereply(sender, target, msg, requestid, filter={})
                serialized  = Marshal.dump(msg)
                digest = makehash(serialized)
    
                @log.debug("Encoded a message with hash #{digest} for request #{requestid}")
    
                Marshal.dump({:senderid => @config.identity,
                              :requestid => requestid,
                              :senderagent => sender,
                              :msgtarget => target,
                              :msgtime => Time.now.to_i,
                              :hash => digest,
                              :body => serialized})
            end
    
            # Encodes a request msg
            def encoderequest(sender, target, msg, requestid, filter={})
                serialized = Marshal.dump(msg)
                digest = makehash(serialized)
    
                @log.debug("Encoding a request for '#{target}' with request id #{requestid}")
                Marshal.dump({:body => serialized,
                              :hash => digest,
                              :senderid => @config.identity,
                              :requestid => requestid,
                              :msgtarget => target,
                              :filter => filter,
                              :msgtime => Time.now.to_i})
            end
    
            # Checks the md5 hash in the request body against our psk, the request sent for validation 
            # should not have been deserialized already
            def validrequest?(req)
                digest = makehash(req[:body])
    
                if digest == req[:hash]
                    @stats[:validated] += 1
    
                    return true
                else
                    @stats[:unvalidated] += 1
    
                    raise("Received an invalid signature in message")
                end
            end
    
            private
            # Retrieves the value of plugin.psk and builds a hash with it and the passed body
            def makehash(body)
                if ENV.include?("MCOLLECTIVE_PSK")
                    psk = ENV["MCOLLECTIVE_PSK"]
                else
                    raise("No plugin.psk configuration option specified") unless @config.pluginconf.include?("psk")
                    psk = @config.pluginconf["psk"]
                end
    
                Digest::MD5.hexdigest(body.to_s + psk)
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
