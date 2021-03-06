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

require 'spec_helper'
require 'java_buildpack/util/library_utils'
require 'java_buildpack/util/play_app_pre22_dist'

module JavaBuildpack::Util

  describe PlayAppPre22Dist do

    it 'should recognize Play 2.0 dist applications' do
      expect(PlayAppPre22Dist.recognizes? 'spec/fixtures/container_play_2.0_dist').to be_true
    end

    it 'should recognize Play 2.1 dist applications' do
      expect(PlayAppPre22Dist.recognizes? 'spec/fixtures/container_play_2.1_dist').to be_true
    end

    it 'should not recognize Play 2.1 staged (or equivalently 2.0 staged) applications' do
      expect(PlayAppPre22Dist.recognizes? 'spec/fixtures/container_play_2.1_staged').to be_false
    end

    it 'should not recognize Play 2.2 applications' do
      expect(PlayAppPre22Dist.recognizes? 'spec/fixtures/container_play_2.2').to be_false
    end

    it 'should construct a Play 2.0 dist application' do
      PlayAppPre22Dist.new 'spec/fixtures/container_play_2.0_dist'
    end

    it 'should construct a Play 2.1 dist application' do
      PlayAppPre22Dist.new 'spec/fixtures/container_play_2.1_dist'
    end

    it 'should fail to construct a Play 2.1 staged (or equivalently 2.0 staged) application' do
      expect { PlayAppPre22Dist.new 'spec/fixtures/container_play_2.1_staged' }.to raise_error(/Unrecognized Play application/)
    end

    it 'should fail to construct a Play 2.2 application' do
      expect { PlayAppPre22Dist.new 'spec/fixtures/container_play_2.2' }.to raise_error(/Unrecognized Play application/)
    end

    it 'should correctly determine the version of a Play 2.0 dist application' do
      play_app = PlayAppPre22Dist.new 'spec/fixtures/container_play_2.0_dist'
      expect(play_app.version).to eq('2.0')
    end

    it 'should correctly determine the version of a Play 2.1 dist application' do
      play_app = PlayAppPre22Dist.new 'spec/fixtures/container_play_2.1_dist'
      expect(play_app.version).to eq('2.1.4')
    end

    it 'should make the start script executable' do
      Dir.mktmpdir do |root|
        FileUtils.cp_r 'spec/fixtures/container_play_2.1_dist/.', root

        play_app = PlayAppPre22Dist.new root

        JavaBuildpack::Util::PlayAppPre22Dist.any_instance.should_receive(:shell).with("chmod +x #{root}/application_root/start").and_return('')

        play_app.set_executable
      end
    end

    it 'should correctly replace the bootstrap class in the start script of a Play 2.1 dist application' do
      Dir.mktmpdir do |root|
        FileUtils.cp_r 'spec/fixtures/container_play_2.1_dist/.', root

        play_app = PlayAppPre22Dist.new root

        play_app.replace_bootstrap 'test.class.name'

        actual = File.open(File.join(root, 'application_root', 'start'), 'r') { |file| file.read }

        expect(actual).to_not match(/play.core.server.NettyServer/)
        expect(actual).to match(/test.class.name/)
      end
    end

    it 'should add additional libraries to lib directory of a Play 2.0 dist application' do
      Dir.mktmpdir do |root|
        lib_dir = File.join(root, '.lib')
        FileUtils.mkdir_p lib_dir
        FileUtils.cp 'spec/fixtures/additional_libs/test-jar-1.jar', lib_dir

        FileUtils.cp_r 'spec/fixtures/container_play_2.0_dist/.', root

        play_app = PlayAppPre22Dist.new root

        play_app.add_libs_to_classpath JavaBuildpack::Util::LibraryUtils.lib_jars(lib_dir)

        relative = File.readlink(File.join root, 'application_root', 'lib', 'test-jar-1.jar')
        actual = Pathname.new(File.join root, 'application_root', 'lib', 'test-jar-1.jar').realpath.to_s
        expected = Pathname.new(File.join lib_dir, 'test-jar-1.jar').realpath.to_s

        expect(relative).to_not eq(expected)
        expect(actual).to eq(expected)
      end
    end

    it 'should correctly extend the classpath of a Play 2.1 dist application' do
      Dir.mktmpdir do |root|
        lib_dir = File.join(root, '.lib')
        FileUtils.mkdir_p lib_dir
        FileUtils.cp 'spec/fixtures/additional_libs/test-jar-1.jar', lib_dir

        FileUtils.cp_r 'spec/fixtures/container_play_2.1_dist/.', root

        play_app = PlayAppPre22Dist.new root

        play_app.add_libs_to_classpath JavaBuildpack::Util::LibraryUtils.lib_jars(lib_dir)

        actual = File.open(File.join(root, 'application_root', 'start'), 'r') { |file| file.read }

        expect(actual).to match(%r(classpath="\$scriptdir/.\./\.lib/test-jar-1\.jar:))
      end
    end

    it 'should correctly determine the relative path of the start script of a Play 2.0 dist application' do
      play_app = PlayAppPre22Dist.new 'spec/fixtures/container_play_2.0_dist'
      expect(play_app.start_script_relative).to eq('./application_root/start')
    end

    it 'should correctly determine the relative path of the start script of a Play 2.1 dist application' do
      play_app = PlayAppPre22Dist.new 'spec/fixtures/container_play_2.1_dist'
      expect(play_app.start_script_relative).to eq('./application_root/start')
    end

    it 'should correctly determine whether or not certain JARs are present in the lib directory of a Play 2.0 dist application' do
      play_app = PlayAppPre22Dist.new 'spec/fixtures/container_play_2.0_dist'
      expect(play_app.contains? 'so*st.jar').to be_true
      expect(play_app.contains? 'some.test.jar').to be_true
      expect(play_app.contains? 'nosuch.jar').to be_false
    end

    it 'should correctly determine whether or not certain JARs are present in the lib directory of a Play 2.1 dist application' do
      play_app = PlayAppPre22Dist.new 'spec/fixtures/container_play_2.1_dist'
      expect(play_app.contains? 'so*st.jar').to be_true
      expect(play_app.contains? 'some.test.jar').to be_true
      expect(play_app.contains? 'nosuch.jar').to be_false
    end

  end

end
