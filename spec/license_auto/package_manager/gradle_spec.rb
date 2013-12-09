require 'spec_helper'
require 'license_auto/package_manager/gradle'

describe LicenseAuto::Gradle do
  let(:repo_dir) { test_case_dir('oreilly-gradle-book-examples/maven-gradle-comparison-dependency-simplest')}
  let(:target_projects) {[]}
  let(:target_deps) {
    Set.new(["commons-beanutils:commons-beanutils:1.8.3", "commons-logging:commons-logging:1.1.1", "junit:junit:4.8.2"])
  }
  let(:target_parsed_deps) {
    [{:dep_file=>
          "spec/fixtures/github.com/mineworks/license_auto_test_case/oreilly-gradle-book-examples/maven-gradle-comparison-dependency-simplest/build.gradle",
      :deps=>
          [{:name=>"commons-beanutils:commons-beanutils",
            :version=>"1.8.3",
            :remote=>nil},
           {:name=>"commons-logging:commons-logging",
            :version=>"1.1.1",
            :remote=>nil},
           {:name=>"junit:junit", :version=>"4.8.2", :remote=>nil}]}]
  }
  let(:pm) {LicenseAuto::Gradle.new(repo_dir)}

  # it 'check system tool' do
  #   bool = LicenseAuto::Gradle.check_cli
  #   expect(bool).to eq(true)
  # end
  #
  # it 'list projects' do
  #   projects = pm.list_projects
  #   expect(projects).to eq(target_projects)
  # end
  #
  # it 'list dependencies of Root Project' do
  #   deps = pm.list_dependencies
  #   expect(deps).to eq(target_deps)
  # end

  it 'parse_dependencies' do
    deps = pm.parse_dependencies
    expect(deps).to eq(target_parsed_deps)
  end

end