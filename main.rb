#!/usr/local/bin/ruby -w
require "nokogiri"

class Bamboo2Jenkins
  VERSION = '0.1'

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    @lockfile = ""
  end

  def run
    # Do we have the Project Name parameter?
    unless @arguments.size == 1
      showusage
      puts "\nERROR: Please specify a Bamboo File to Migrate!"
      Process.exit
    end

    bamboo_file = @arguments[0]
    current_directory = Dir.pwd
    output_dir = current_directory + "/" + "output"
    Dir::mkdir(output_dir) unless FileTest::directory?(output_dir)

    doc = Nokogiri::XML(open(bamboo_file))

    doc.xpath("//bamboo/projects/project").each do |project|
      # Create Project folder in output directory
      
      project.xpath("builds/build").each do |build|
        # Output Build File.
        build_name = build.xpath("buildName").text
        key = build.xpath("key").text
        definition = Nokogiri::XML( build.xpath("definition/xml").text)
        svn_url = definition.xpath("configuration/repository/svn/repositoryUrl").text # remote
        goals = definition.xpath("configuration/builder/mvn2/goal").text # remote

        #artifact = build_name #artifactID
        #group = "" #groupID
        build_frequency = "" # spec

        case
          when build_name.include?("CON")
            build_frequency = "*/5 * * * *"
          when build_name.include?("DAILY")
            build_frequency = "@daily"
          when build_name.include?("REL")
            build_frequency = ""
        end
        
        project_folder = output_dir  + "/" +  key
        # project.xpath("name").text
        unless FileTest::directory?(project_folder)
          Dir::mkdir(project_folder)
        end
        
        build_filename = project_folder + "/" + "config.xml"

        # File is overwritten if it exists
        File.open(build_filename, 'w') do |f|
          f.puts "<?xml version='1.0' encoding='UTF-8'?>"
          f.puts "<maven2-moduleset>"
          f.puts "<actions/>"
          f.puts "<description>#{build_name}</description>"
          f.puts "<keepDependencies>false</keepDependencies>"
          f.puts "<properties/>"
          f.puts "<scm class=\"hudson.scm.SubversionSCM\">"
          f.puts "<locations>"
          f.puts "<hudson.scm.SubversionSCM_-ModuleLocation>"
          f.puts "<remote>#{svn_url}</remote>"
          f.puts "<local>.</local>"
          f.puts "</hudson.scm.SubversionSCM_-ModuleLocation>"
          f.puts "</locations>"
          f.puts "<useUpdate>true</useUpdate>"
          f.puts "<doRevert>false</doRevert>"
          f.puts "<excludedRegions></excludedRegions>"
          f.puts "<includedRegions></includedRegions>"
          f.puts "<excludedUsers></excludedUsers>"
          f.puts "<excludedRevprop></excludedRevprop>"
          f.puts "<excludedCommitMessages></excludedCommitMessages>"
          f.puts "</scm>"
          f.puts "<canRoam>true</canRoam>"
          f.puts "<disabled>false</disabled>"
          f.puts "<blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>"
          f.puts "<triggers class=\"vector\">"
          f.puts "<hudson.triggers.SCMTrigger>"
          f.puts "<spec>#{build_frequency}</spec>"
          f.puts "</hudson.triggers.SCMTrigger>"
          f.puts "</triggers>"
          f.puts "<concurrentBuild>false</concurrentBuild>"
          f.puts "<rootModule>"
          f.puts "<groupId></groupId>"
          f.puts "<artifactId></artifactId>"
          f.puts "</rootModule>"
          f.puts "<goals>#{goals}</goals>"
          f.puts "<aggregatorStyleBuild>true</aggregatorStyleBuild>"
          f.puts "<incrementalBuild>false</incrementalBuild>"
          f.puts "<usePrivateRepository>false</usePrivateRepository>"
          f.puts "<ignoreUpstremChanges>false</ignoreUpstremChanges>"
          f.puts "<archivingDisabled>false</archivingDisabled>"
          f.puts "<reporters/>"
          f.puts "<publishers/>"
          f.puts "<buildWrappers/>"
          f.puts "</maven2-moduleset>"
        end
      end
    end
  end

  def showusage
    puts "Bamboo2Jenkins"
    puts "============"
    puts "This script is used to migrate Bamboo Job files (administrationConfiguration.xml) to Jenkins."
    puts
    puts "USAGE: main.rb bambooJobFile"
    puts
  end
end

# Create and run the application
app = Bamboo2Jenkins.new(ARGV, STDIN)
app.run


