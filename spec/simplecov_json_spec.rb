# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe Danger::DangerSimpleCovJson do
  before do
    @dangerfile = testing_dangerfile
    @simplecov = @dangerfile.simplecov
  end

  it 'should be a plugin' do
    expect(Danger::DangerSimpleCovJson.new(nil)).to be_a Danger::Plugin
  end

  describe '#report' do
    it 'fails if code coverage not found' do
      @simplecov.report('spec/fixtures/missing_file.json')

      expect(@dangerfile.status_report[:errors]).to eq(['Code coverage data not found'])
    end

    it 'shows code coverage report' do
      @simplecov.report('spec/fixtures/coverage.json')

      expect(@dangerfile.status_report[:messages]).to eq(['Code coverage is now at 99.15% (1512/1525 lines)'])
    end
  end

  describe '#individual_report' do
    it 'fails if code coverage not found' do
      @simplecov.report('spec/fixtures/missing_file.json')

      expect(@dangerfile.status_report[:errors]).to eq(['Code coverage data not found'])
    end

    it 'shows individual code coverage report for added files' do
      allow(@simplecov.git).to receive(:added_files).and_return(['foo.rb'])
      allow(@simplecov.git).to receive(:modified_files).and_return([])

      @simplecov.individual_report('spec/fixtures/coverage.json')
      expect(@dangerfile.status_report.fetch(:markdowns).first.message).to eq <<~MSG.strip
        ### Code Coverage

        | File   | Coverage |
        |--------|----------|
        | foo.rb | 20.00%   |
      MSG
    end

    it 'shows individual code coverage report for modified files' do
      allow(@simplecov.git).to receive(:added_files).and_return([])
      allow(@simplecov.git).to receive(:modified_files).and_return(['bar.rb'])

      @simplecov.individual_report('spec/fixtures/coverage.json')
      expect(@dangerfile.status_report.fetch(:markdowns).first.message).to eq <<~MSG.strip
        ### Code Coverage

        | File   | Coverage |
        |--------|----------|
        | bar.rb | 40.00%   |
      MSG
    end

    context 'with files_matcher option' do
      it 'shows individual code coverage report per matched files only' do
        allow(@simplecov.git).to receive(:added_files).and_return(['foo.rb', 'bar.rb'])
        allow(@simplecov.git).to receive(:modified_files).and_return(['baz.rb'])

        matcher = lambda do |commited_files, coverage_file_name|
          coverage_file_name =~ /ba/ && commited_files.include?(coverage_file_name)
        end

        @simplecov.individual_report('spec/fixtures/coverage.json', files_matcher: matcher)

        expect(@dangerfile.status_report.fetch(:markdowns).first.message).to eq <<~MSG.strip
          ### Code Coverage

          | File   | Coverage |
          |--------|----------|
          | bar.rb | 40.00%   |
          | baz.rb | 60.00%   |
        MSG
      end
    end

    context 'with minimum_coverage_by_file option' do
      it 'fails when files do not pass min threshold' do
        allow(@simplecov.git).to receive(:added_files).and_return(['foo.rb'])
        allow(@simplecov.git).to receive(:modified_files).and_return([])

        @simplecov.individual_report('spec/fixtures/coverage.json', minimum_coverage_by_file: 90)

        expect(@dangerfile.status_report[:errors]).to eq(['Some files do not pass minimum coverage'])
      end

      it 'shows "check mark" next to the file with coverage equal to min threshold' do
        allow(@simplecov.git).to receive(:added_files).and_return(['foo.rb'])
        allow(@simplecov.git).to receive(:modified_files).and_return([])

        @simplecov.individual_report('spec/fixtures/coverage.json', minimum_coverage_by_file: 20)

        expect(@dangerfile.status_report.fetch(:markdowns).first.message).to eq <<~MSG.strip
          ### Code Coverage

          |   | File   | Coverage |
          |---|--------|----------|
          | ✓ | foo.rb | 20.00%   |
        MSG
      end

      it 'shows "check mark" next to the file with coverage greater than min threshold' do
        allow(@simplecov.git).to receive(:added_files).and_return(['bar.rb'])
        allow(@simplecov.git).to receive(:modified_files).and_return([])

        @simplecov.individual_report('spec/fixtures/coverage.json', minimum_coverage_by_file: 20)

        expect(@dangerfile.status_report.fetch(:markdowns).first.message).to eq <<~MSG.strip
          ### Code Coverage

          |   | File   | Coverage |
          |---|--------|----------|
          | ✓ | bar.rb | 40.00%   |
        MSG
      end

      it 'shows "cross mark" next to the file with coverage greater than min threshold' do
        allow(@simplecov.git).to receive(:added_files).and_return(%w[foo.rb bar.rb baz.rb])
        allow(@simplecov.git).to receive(:modified_files).and_return([])

        @simplecov.individual_report('spec/fixtures/coverage.json', minimum_coverage_by_file: 40.0)

        expect(@dangerfile.status_report.fetch(:markdowns).first.message).to eq <<~MSG.strip
          ### Code Coverage

          |   | File   | Coverage |
          |---|--------|----------|
          | ✗ | foo.rb | 20.00%   |
          | ✓ | bar.rb | 40.00%   |
          | ✓ | baz.rb | 60.00%   |
        MSG
      end

      it 'allows to pass custom predicate to decide whether coverage is above min threshold' do
        allow(@simplecov.git).to receive(:added_files).and_return(%w[foo.rb bar.rb baz.rb])
        allow(@simplecov.git).to receive(:modified_files).and_return([])

        predicate = lambda do |filename, covered_percent|
          filename == 'foo.rb' ? true : covered_percent.to_f >= 60.0
        end

        @simplecov.individual_report('spec/fixtures/coverage.json', minimum_coverage_by_file: predicate)

        expect(@dangerfile.status_report.fetch(:markdowns).first.message).to eq <<~MSG.strip
          ### Code Coverage

          |   | File   | Coverage |
          |---|--------|----------|
          | ✓ | foo.rb | 20.00%   |
          | ✗ | bar.rb | 40.00%   |
          | ✓ | baz.rb | 60.00%   |
        MSG
      end
    end
  end
end
