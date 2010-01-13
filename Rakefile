# Rakefile to build a project using HUDSON

require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/clean'
require 'find'

PROJ_DOC_TITLE = "The Marionette Collective"
PROJ_VERSION = "0.4.2"
PROJ_RELEASE = "1"
PROJ_NAME = "mcollective"
PROJ_RPM_NAMES = [PROJ_NAME]
PROJ_FILES = ["#{PROJ_NAME}.spec", "#{PROJ_NAME}.init", "mcollectived.rb", "COPYING"]
PROJ_SUBDIRS = ["etc", "lib", "plugins", "ext"]
PROJ_FILES.concat(Dir.glob("mc-*"))

Find.find("etc", "lib", "plugins", "ext") do |f|
    if FileTest.directory?(f) and f =~ /\.svn/
        Find.prune
    else
        PROJ_FILES << f
    end
end

ENV["RPM_VERSION"] ? CURRENT_VERSION = ENV["RPM_VERSION"] : CURRENT_VERSION = PROJ_VERSION
ENV["BUILD_NUMBER"] ? CURRENT_RELEASE = ENV["BUILD_NUMBER"] : CURRENT_RELEASE = PROJ_RELEASE

CLEAN.include("build")

def announce(msg='')
    STDERR.puts "================"
    STDERR.puts msg
    STDERR.puts "================"
end

def init
    FileUtils.mkdir("build") unless File.exist?("build")
end

desc "Build documentation, tar balls and rpms"
task :default => [:clean, :doc, :package, :rpm, :tag] 

# task for building docs
rd = Rake::RDocTask.new(:doc) { |rdoc|
    announce "Building documentation for #{CURRENT_VERSION}"

    rdoc.rdoc_dir = 'doc'
    rdoc.template = 'html'
    rdoc.title    = "#{PROJ_DOC_TITLE} version #{CURRENT_VERSION}"
    rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'MCollective'
}

Rake::PackageTask.new(PROJ_NAME, CURRENT_VERSION) do |p|
    announce "Building tar file for #{CURRENT_VERSION}"

    # A bit hacky, we only build docs dynamically 
    # so we have to add them to the PROJ_FILES list
    # here before building the tar
    Find.find("doc") do |f|
        PROJ_FILES << f
    end

    p.need_tar = true
    p.package_files = PROJ_FILES
    p.package_dir = "build"
end

desc "Tag the release in SVN"
task :tag => [:rpm] do
    ENV["TAGS_URL"] ? TAGS_URL = ENV["TAGS_URL"] : TAGS_URL = `/usr/bin/svn info|/bin/awk '/Repository Root/ {print $3}'`.chomp + "/tags"

    raise("Need to specify a SVN url for tags using the TAGS_URL environment variable") unless TAGS_URL

    announce "Tagging the release for version #{CURRENT_VERSION}-#{CURRENT_RELEASE}"
    system %{svn copy -m 'Hudson adding release tag #{CURRENT_VERSION}-#{CURRENT_RELEASE}' ../#{PROJ_NAME}/ #{TAGS_URL}/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}}
end

desc "Creates a RPM"
task :rpm => [:clean, :doc, :package] do
    announce("Building RPM for #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}")

    sourcedir = `rpm --eval '%_sourcedir'`.chomp
    specsdir = `rpm --eval '%_specdir'`.chomp
    srpmsdir = `rpm --eval '%_srcrpmdir'`.chomp
    rpmdir = `rpm --eval '%_rpmdir'`.chomp
    lsbdistrel = `lsb_release -r -s | cut -d . -f1`.chomp
    lsbdistro = `lsb_release -i -s`.chomp

    case lsbdistro
        when 'CentOS'
            rpmdist = ".el#{lsbdistrel}"
        else
            rpmdist = ""
    end

    system %{cp build/#{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{sourcedir}}
    system %{cp #{PROJ_NAME}.spec #{specsdir}}

    system %{cd #{specsdir} && rpmbuild -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist #{rpmdist}' -ba #{PROJ_NAME}.spec}

    system %{cp #{srpmsdir}/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}#{rpmdist}.src.rpm build/}

    system %{cp #{rpmdir}/*/#{PROJ_NAME}*-#{CURRENT_VERSION}-#{CURRENT_RELEASE}#{rpmdist}.*.rpm build/}
end

desc "Create the .debs"
task :deb => [:clean, :doc, :package] do
    announce("Building debian packages")

    File.open("ext/debian/changelog", "w") do |f|
        f.puts("mcollective (#{CURRENT_VERSION}-#{CURRENT_RELEASE}) unstable; urgency=low")
        f.puts
        f.puts("  * Automated release for #{CURRENT_VERSION}-#{CURRENT_RELEASE} by rake deb")
        f.puts
        f.puts("    See http://code.google.com/p/mcollective/wiki/ReleaseNotes for full details")
        f.puts
        f.puts(" -- The Marionette Collective <mcollective-dev@googlegroups.com>  #{Time.new.strftime('%a, %d %b %Y %H:%M:%S %z')}")
    end

    FileUtils.mkdir_p("build/deb")
    Dir.chdir("build/deb") do
        system %{tar -xzf ../#{PROJ_NAME}-#{CURRENT_VERSION}.tgz}
        system %{cp ../#{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{PROJ_NAME}_#{CURRENT_VERSION}.orig.tar.gz}

        Dir.chdir("#{PROJ_NAME}-#{CURRENT_VERSION}") do
            system %{cp -R ext/debian .}
            system %{cp -R ext/Makefile .}
            system %{debuild -i -us -uc -b}
        end

        system %{cp *.deb ..}
    end

end

# vi:tabstop=4:expandtab:ai
