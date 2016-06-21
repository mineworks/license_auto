require 'spec_helper'
require 'license_auto/package_manager/gradle'

describe LicenseAuto::Gradle do
  let(:repo_dir) { test_case_dir('package_manager/gradle')}

  let(:target_projects) {["commons", "commons-newer"]}

  let(:target_deps) {
    Set.new(["commons-logging:commons-logging:1.1.1",
             "commons-io:commons-io:2.1 -> 2.4",
             "commons-io:commons-io:2.4",
             "commons-collections:commons-collections:3.2.1"])
  }

  let(:target_parsed_deps) {
    [{:dep_file=>
          "spec/fixtures/github.com/mineworks/license_auto_test_case/package_manager/gradle/build.gradle",
      :deps=>
          [{:name=>"commons-logging:commons-logging",
            :version=>"1.1.1",
            :remote=>"https://repo1.maven.org/maven2/"},

           {:name=>"commons-io:commons-io",
            :version=>"2.4",
            :remote=>"https://repo1.maven.org/maven2/"},

           {:name=>"commons-io:commons-io",
            :version=>"2.4",
            :remote=>"https://repo1.maven.org/maven2/"},

           {:name=>"commons-collections:commons-collections",
            :version=>"3.2.1",
            :remote=>"https://repo1.maven.org/maven2/"}]}]
  }

  let(:pm) {LicenseAuto::Gradle.new(repo_dir)}

  it 'check system tool' do
    bool = LicenseAuto::Gradle.check_cli
    expect(bool).to eq(true)
  end

  it 'list projects' do
    projects = pm.list_projects
    expect(projects).to eq(target_projects)
  end

  it 'list dependencies of Root Project' do
    deps = pm.list_dependencies
    expect(deps).to eq(target_deps)
  end

  it 'parses simple dependencies' do
    deps = pm.parse_dependencies
    expect(deps).to eq(target_parsed_deps)
  end

end