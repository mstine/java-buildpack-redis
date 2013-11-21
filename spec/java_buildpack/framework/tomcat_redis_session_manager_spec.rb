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

require 'spec_helper'
require 'java_buildpack/application'
require 'java_buildpack/framework/tomcat_redis_session_manager'

module JavaBuildpack::Framework

  describe TomcatRedisSessionManager do

    SESSION_MANAGER_VERSION = JavaBuildpack::Util::TokenizedVersion.new('1.2.0')

    SESSION_MANAGER_DETAILS = [SESSION_MANAGER_VERSION, 'test-session-manager-uri']

    JEDIS_VERSION = JavaBuildpack::Util::TokenizedVersion.new('2.1.0')

    JEDIS_DETAILS = [JEDIS_VERSION, 'test-jedis-uri']

    COMMONS_POOL_VERSION = JavaBuildpack::Util::TokenizedVersion.new('2.0.0')

    COMMONS_POOL_DETAILS = [COMMONS_POOL_VERSION, 'test-commons-pool-uri']

    let(:application_cache) { double('ApplicationCache') }

    before do
      #$stdout = StringIO.new
      #$stderr = StringIO.new
    end

    it 'should detect WEB-INF' do
      JavaBuildpack::Repository::ConfiguredItem.stub(:find_item)
        .and_return(SESSION_MANAGER_DETAILS,JEDIS_DETAILS,COMMONS_POOL_DETAILS)

      detected = TomcatRedisSessionManager.new(
          app_dir: 'spec/fixtures/container_tomcat',
          application: JavaBuildpack::Application.new('spec/fixtures/container_tomcat'),
          configuration: {}
      ).detect

      expect(detected).to include('tomcat-redis-session-manager=1.2.0')
      expect(detected).to include('jedis=2.1.0')
      expect(detected).to include('commons-pool=2.0.0')
    end

    it 'should not detect when WEB-INF is absent' do
      JavaBuildpack::Repository::ConfiguredItem.stub(:find_item)
      .and_return(SESSION_MANAGER_DETAILS,JEDIS_DETAILS,COMMONS_POOL_DETAILS)

      detected = TomcatRedisSessionManager.new(
          app_dir: 'spec/fixtures/container_main',
          application: JavaBuildpack::Application.new('spec/fixtures/container_main'),
          configuration: {}
      ).detect

      expect(detected).to be_nil
    end

    it 'should copy additional libraries to the lib directory' do
      Dir.mktmpdir do |root|
        lib_directory = File.join root, 'lib'
        Dir.mkdir lib_directory

        JavaBuildpack::Repository::ConfiguredItem.stub(:find_item)
        .and_return(SESSION_MANAGER_DETAILS,JEDIS_DETAILS,COMMONS_POOL_DETAILS)

        JavaBuildpack::Util::ApplicationCache.stub(:new).and_return(application_cache)
        application_cache.stub(:get).with('test-session-manager-uri').and_yield(File.open('spec/fixtures/stub-tomcat-redis-session-manager.jar'))
        application_cache.stub(:get).with('test-jedis-uri').and_yield(File.open('spec/fixtures/stub-jedis.jar'))
        application_cache.stub(:get).with('test-commons-pool-uri').and_yield(File.open('spec/fixtures/stub-commons-pool.jar'))

        TomcatRedisSessionManager.new(
          app_dir: 'spec/fixtures/container_tomcat',
          application: JavaBuildpack::Application.new('spec/fixtures/container_tomcat'),
          lib_directory: lib_directory,
          configuration: {}
        ).compile

        expect(File.exists? File.join(lib_directory, 'tomcat-redis-session-manager-1.2.0.jar')).to be_true
        expect(File.exists? File.join(lib_directory, 'jedis-2.1.0.jar')).to be_true
        expect(File.exists? File.join(lib_directory, 'commons-pool2-2.0.0.jar')).to be_true
      end


    end


  end

end

