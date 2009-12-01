#!/usr/bin/ruby

require 'mcollective'
require 'getoptlong'

opts = GetoptLong.new(
    [ '--config', '-c', GetoptLong::REQUIRED_ARGUMENT],
    [ '--pidfile', '-p', GetoptLong::REQUIRED_ARGUMENT]
)

configfile = "/etc/mcollective/server.cfg"
pid = ""

opts.each do |opt, arg|
    case opt
        when '--config'
            configfile = arg
        when '--pidfile'
            pid = arg
    end
end

config = MCollective::Config.instance

config.loadconfig(configfile) unless config.configured

log = MCollective::Log.instance

if config.daemonize
    log.debug("Starting in the background (#{config.daemonize})")
    MCollective::Runner.daemonize do
        if pid
            begin
                File.open(pid, 'w') {|f| f.write(Process.pid) }
            rescue Exception => e
            end
        end

        runner = MCollective::Runner.new(configfile)
    	runner.run
    end
else
    log.debug("Starting in the foreground")
    runner = MCollective::Runner.new(configfile)
    runner.run
end

# vi:tabstop=4:expandtab:ai
