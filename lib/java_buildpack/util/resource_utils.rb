# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/util'
require 'open3'
require 'erb'

module JavaBuildpack::Util

  # Utilities for dealing with buildpack resources
  class ResourceUtils

    # Copies the contents of the given subdirectory of the buildpack resources directory to the given target directory.
    #
    # @param [String] subdirectory the subdirectory of the resources directory
    # @param [String] target the target directory
    def self.copy_resources(subdirectory, target)
      Open3.popen3("cp -r #{File.join(get_resources(subdirectory), '*')} #{target}") do |stdin, stdout, stderr, wait_thr|
        if wait_thr.value != 0
          puts "STDOUT: #{stdout.gets}"
          puts "STDERR: #{stderr.gets}"

          fail
        end
      end
    end

    # Returns the path of the given subdirectory of the buildpack resources directory.
    #
    # @param [String] subdirectory the subdirectory of the resources directory
    # @return [String] the path of the subdirectory
    def self.get_resources(subdirectory)
      File.join(File.expand_path(RESOURCES, File.dirname(__FILE__)), subdirectory)
    end

    # Generates a resource based on a bound service and places in the desired directory.
    #
    # @param [String] template the name of the template file
    # @param [String] service the service data
    # @param [String] target_directory the target directory for writing the generated resource
    # @param [String] target_file the name of the file to write
    def self.generate_bound_resource_from_template(template, service, target_directory, target_file)
      template_file = File.open(File.join(get_resources('templates'), template), 'r').read
      erb = ERB.new(template_file)
      File.open(File.join(target_directory, target_file), 'w+') do |file|
        file.write(erb.result(binding))
      end
    end

    private

    RESOURCES = File.join('..', '..', '..', 'resources').freeze

    private_class_method :new
  end

end
