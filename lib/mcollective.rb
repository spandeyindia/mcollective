require 'rubygems'
require 'stomp'
require 'logger'
require 'timeout'
require 'digest/md5'
require 'optparse'
require 'singleton'
require 'socket'
require 'erb'

# == The Marionette Collective
#
# Framework to build and run Systems Administration agents running on a 
# publish/subscribe middleware system.  The system allows you to treat your
# network as the only true source of the state of your platform via discovery agents
# and allow you to run agents matching discovery criteria.
#
# For an overview of the idea behind this and what it enables please see:
#   http://www.devco.net/archives/2009/10/18/middleware_for_systems_administration.php
module MCollective
    # Exceptions for the RPC system
    class RPCError<StandardError;end
    class RPCAborted<RPCError;end
    class UnknownRPCAction<RPCError;end
    class MissingRPCData<RPCError;end
    class InvalidRPCData<RPCError;end
    class UnknownRPCError<RPCError;end
    class NotTargettedAtUs<RuntimeError;end

    autoload :Config, "mcollective/config"    
    autoload :Log, "mcollective/log"    
    autoload :Runner, "mcollective/runner"    
    autoload :Agents, "mcollective/agents"    
    autoload :Client, "mcollective/client"    
    autoload :Util, "mcollective/util"    
    autoload :Optionparser, "mcollective/optionparser"
    autoload :Connector, "mcollective/connector"
    autoload :Security, "mcollective/security"
    autoload :Facts, "mcollective/facts"
    autoload :Registration, "mcollective/registration"
    autoload :PluginManager, "mcollective/pluginmanager"
    autoload :RPC, "mcollective/rpc"
    autoload :Request, "mcollective/request"
end

# vi:tabstop=4:expandtab:ai
