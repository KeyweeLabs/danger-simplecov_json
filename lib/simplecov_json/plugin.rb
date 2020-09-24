# frozen_string_literal: true

module Danger
  #
  # Report your Ruby app test suite code coverage.
  #
  # You can use [simplecov](https://github.com/colszowka/simplecov) to gather
  # code coverage data and a [json formatter](https://github.com/vicentllongo/simplecov-json)
  # so this plugin can parse it.
  #
  # @example Report code coverage
  #
  #   simplecov.report('coverage/coverage.json')
  #   simplecov.individual_report('coverage/coverage.json', Dir.pwd)
  #
  # @see  marcelofabri/danger-simplecov_json
  # @tags ruby, code-coverage, simplecov
  #
  class DangerSimpleCovJson < Plugin
    def self.instance_name
      'simplecov'
    end

    #
    # Report full code coverage information as a message in Danger
    #
    # @param coverage_path [String] path to the project coverage json report
    # @param sticky [Boolean] whether to make danger message sticky or not
    # @return void
    #
    def report(coverage_path, sticky: true)
      if File.exist? coverage_path
        coverage_json = JSON.parse(File.read(coverage_path), symbolize_names: true)
        metrics = coverage_json[:metrics]
        percentage = metrics[:covered_percent]
        lines = metrics[:covered_lines]
        total_lines = metrics[:total_lines]

        formatted_percentage = format('%.02f', percentage)
        message("Code coverage is now at #{formatted_percentage}% (#{lines}/#{total_lines} lines)", sticky: sticky)
      else
        fail('Code coverage data not found')
      end
    end

    #
    # Report on the files that you have added or modified in git.
    #
    # @param coverage_path [String] path to the project coverage json report
    # @param files_matcher: [nil, Proc] Optional matcher to match between commited files and coverage data.
    #   First param is a list of commited files.
    #   Second param is a single string file name from coverage report.
    #   Should return either true or false, matches on true.
    # @return void
    #
    def individual_report(coverage_path, files_matcher: nil)
      fail('Code coverage data not found') unless File.exist? coverage_path

      committed_files = git.modified_files + git.added_files

      coverage_report_files = JSON.parse(File.read(coverage_path), symbolize_names: true).fetch(:files)
      matched_files_with_coverage = coverage_report_files.select do |f|
        if files_matcher.nil?
          committed_files.include?(f[:filename])
        else
          files_matcher.call(committed_files, f[:filename])
        end
      end

      return if matched_files_with_coverage.empty?

      markdown render_coverage_table(matched_files_with_coverage)
    end

    private def render_coverage_table(covered_files)
      require 'terminal-table'

      message = "### Code Coverage\n\n"
      table = Terminal::Table.new(
        headings: %w(File Coverage),
        style: { border_i: '|' },
        rows: covered_files.map do |file|
          [file[:filename], "#{format('%.02f', file[:covered_percent])}%"]
        end
      ).to_s
      message + table.split("\n")[1..-2].join("\n")
    end
  end
end
