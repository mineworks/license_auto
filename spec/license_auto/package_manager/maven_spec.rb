require 'spec_helper'
require 'license_auto/package_manager/maven'

describe LicenseAuto::Maven do
  let(:repo_dir) { test_case_dir('package_manager/maven')}
  let(:target_listed_deps) {
    Set.new(["commons-logging:commons-logging:jar:1.1.1:compile",
             "commons-io:commons-io:jar:2.4:compile",
             "commons-collections:commons-collections:jar:3.2.1:compile"])
  }
  let(:target_collected_deps) {
    [{:name=>"commons-logging:commons-logging", :version=>"1.1.1", :remote=>"repo1.maven.org/maven2"},
     {:name=>"commons-io:commons-io", :version=>"2.4", :remote=>"repo1.maven.org/maven2"},
     {:name=>"commons-collections:commons-collections", :version=>"3.2.1", :remote=>"repo1.maven.org/maven2"}]
  }
  let(:target_parsed_deps) {
    [
        {
            "dep_file": "spec/fixtures/github.com/mineworks/license_auto_test_case/package_manager/maven/pom.xml",
            "deps": [
                {
                    "name": "commons-logging:commons-logging",
                    "version": "1.1.1",
                    "remote": 'repo1.maven.org/maven2'
                },
                {
                    "name": "commons-io:commons-io",
                    "version": "2.4",
                    "remote": 'repo1.maven.org/maven2'
                },
                {
                    "name": "commons-collections:commons-collections",
                    "version": "3.2.1",
                    "remote": 'repo1.maven.org/maven2'
                },
            ]
        }
    ]
  }
  let(:pm) {LicenseAuto::Maven.new(repo_dir)}

  it 'check system tool' do
    bool = LicenseAuto::Maven.check_cli
    expect(bool).to eq(true)
  end

  it 'resolve_dependencies' do
    ok = pm.resolve_dependencies
    expect(ok).to eq(true)
  end

  it 'list dependencies of pom.xml' do
    deps = pm.list_dependencies
    expect(deps).to eq(target_listed_deps)
  end

  it 'list collect_dependencies' do
    deps = pm.collect_dependencies
    expect(deps).to eq(target_collected_deps)
  end

  it 'parse_dependencies' do
    deps = pm.parse_dependencies
    expect(deps).to eq(target_parsed_deps)
  end



end