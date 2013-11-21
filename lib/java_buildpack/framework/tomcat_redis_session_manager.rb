# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
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

require 'java_buildpack/framework'
require 'java_buildpack/versioned_dependency_component'

module JavaBuildpack::Framework

  class TomcatRedisSessionManager < JavaBuildpack::BaseComponent

    def initialize(context)
      super('Tomcat Redis Session Manager', context)

      if supports?
        @session_manager_version, @session_manager_uri = JavaBuildpack::Repository::ConfiguredItem.find_item(@component_name, @configuration)
        @jedis_version, @jedis_uri = JavaBuildpack::Repository::ConfiguredItem.find_item(@component_name, @configuration[KEY_JEDIS])
        @commons_pool_version, @commons_pool_uri = JavaBuildpack::Repository::ConfiguredItem.find_item(@component_name, @configuration[KEY_COMMONS_POOL])
      else
        @session_manager_version, @session_manager_uri = nil, nil
        @jedis_version, @jedis_uri = nil, nil
        @commons_pool_version, @commons_pool_uri = nil, nil
      end
    end

    def detect
      @session_manager_version &&
          @jedis_version &&
          @commons_pool_version ?
          [session_manager_id(@session_manager_version),
           jedis_id(@jedis_version),
           commons_pool_id(@commons_pool_version)] : nil
    end

    def compile
      FileUtils.mkdir_p(container_libs_directory)
      download_jar(@session_manager_version, @session_manager_uri, session_manager_jar_name, container_libs_directory)
      download_jar(@jedis_version, @jedis_uri, jedis_jar_name, container_libs_directory, "JEDIS")
      download_jar(@commons_pool_version, @commons_pool_uri, commons_pool_jar_name, container_libs_directory, "Commons Pool")
    end

    def release
    end

    protected

    def session_manager_id(version)
      "#{@parsable_component_name}=#{version}"
    end

    def jedis_id(version)
      "jedis=#{version}"
    end

    def commons_pool_id(version)
      "commons-pool=#{version}"
    end

    def supports?
      @application.child(WEB_INF_DIRECTORY).exist?
    end

    private

    KEY_JEDIS = 'jedis'.freeze

    KEY_COMMONS_POOL = 'commons_pool'.freeze

    WEB_INF_DIRECTORY = 'WEB-INF'.freeze

    def session_manager_jar_name
      "tomcat-redis-session-manager-#{@session_manager_version}.jar"
    end

    def jedis_jar_name
      "jedis-#{@jedis_version}.jar"
    end

    def commons_pool_jar_name
      "commons-pool2-#{@commons_pool_version}.jar"
    end

    def container_libs_directory
      if @container_lib_directory.nil?
        @application.component_directory 'container-libs'
      else
        @container_lib_directory
      end
    end

  end

end