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
require 'java_buildpack/framework/redis_session_manager'

module JavaBuildpack::Framework

  describe RedisSessionManager do

    VERSION = JavaBuildpack::Util::TokenizedVersion.new('0.0.1')

    DETAILS = [VERSION, 'test-uri']

    let(:application_cache) { double('ApplicationCache') }

    before do
      #$stdout = StringIO.new
      #$stderr = StringIO.new
    end

    it 'should detect WEB-INF' do
      JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)

      detected = RedisSessionManager.new(
          app_dir: 'spec/fixtures/container_tomcat',
          application: JavaBuildpack::Application.new('spec/fixtures/container_tomcat'),
          configuration: {}
      ).detect

      expect(detected).to include('redis-session-manager=0.0.1')
    end

    it 'should not detect when WEB-INF is absent' do
      JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)

      detected = RedisSessionManager.new(
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

        JavaBuildpack::Repository::ConfiguredItem.stub(:find_item).and_return(DETAILS)
        JavaBuildpack::Util::ApplicationCache.stub(:new).and_return(application_cache)
        application_cache.stub(:get).with('test-uri').and_yield(File.open('spec/fixtures/stub-redis-session-manager.zip'))

        Dir.new(lib_directory).each_entry do |entry|
          puts entry
        end

        RedisSessionManager.new(
          app_dir: 'spec/fixtures/container_tomcat',
          application: JavaBuildpack::Application.new('spec/fixtures/container_tomcat'),
          lib_directory: lib_directory,
          configuration: {}
        ).compile

        Dir.new(lib_directory).each_entry do |entry|
          puts entry
        end


        expect(File.exists? File.join(lib_directory, 'commons-pool2-2.0.jar')).to be_true
        expect(File.exists? File.join(lib_directory, 'jedis-2.1.0.jar')).to be_true
        expect(File.exists? File.join(lib_directory, 'tomcat-redis-session-manager-1.2-tomcat-7-java-7.jar')).to be_true
      end


    end


  end

end

