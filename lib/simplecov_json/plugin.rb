# frozen_string_literal: true

module Danger
  #
  # Report your Ruby app test suite code coverage.
  #
  # You can use {https://github.com/colszowka/simplecov simplecov} to gather
  # code coverage data and a {https://github.com/vicentllongo/simplecov-json json formatter}
  # so this plugin can parse it.
  #
  # @example Report code coverage
  #   simplecov.report('coverage/coverage.json')
  #   simplecov.individual_report('coverage/coverage.json', Dir.pwd)
  #
  # @see  https://github.com/marcelofabri/danger-simplecov_json
  # @tags ruby, code-coverage, simplecov
  #
  class DangerSimpleCovJson < Plugin

    CHECK_MARK = "\u2713"
    BALLOT_X = "\u2717"

    FileCoverage = Struct.new(:filename, :covered_percent, :passed_min_threshold)

    def self.instance_name
      'simplecov'
    end

    #
    # Report full code coverage information as a message
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
    # Report on the files that you have added or modified in git as a markdown table message
    #
    # @param coverage_path [String] path to the project coverage json report
    # @param files_matcher: [nil, Proc] Optional matcher to match between commited files and coverage data.
    #   First param is a list of commited files.
    #   Second param is a single string file name from coverage report.
    #   Should return either true or false, matches on true.
    # @return void
    #
    def individual_report(
      coverage_path,
      files_matcher: nil,
      minimum_coverage_by_file: nil
    )
      fail 'Code coverage data not found' unless File.exist? coverage_path

      coverage_files = collect_coverage_files(coverage_path, files_matcher)
      return if coverage_files.empty?

      files = map_coverage_files(coverage_files, minimum_coverage_by_file)
      below_threshold = files.detect { |f| !f.passed_min_threshold }

      if minimum_coverage_by_file.nil?
        markdown render_simple_coverage_table(files)
      else
        markdown render_coverage_table_with_threshold_mark(files)
        fail 'Some files do not pass minimum coverage' unless below_threshold.nil?
      end
    end

    private def collect_coverage_files(coverage_path, files_matcher)
      committed_files = git.modified_files + git.added_files
      coverage_report_files = JSON.parse(File.read(coverage_path), symbolize_names: true).fetch(:files)

      coverage_report_files.select do |f|
        if files_matcher.nil?
          committed_files.include?(f[:filename])
        else
          files_matcher.call(committed_files, f[:filename])
        end
      end
    end

    private def map_coverage_files(coverage_files, minimum_coverage_by_file)
      threshold_predicate =
        case minimum_coverage_by_file
        when Float, Integer
          proc { |filename, covered_percent| covered_percent >= minimum_coverage_by_file }
        when Proc
          minimum_coverage_by_file
        when NilClass
          proc { true }
        else
          raise 'Expected minimum_coverage_by_file to be either Integer or a Proc'
        end

      coverage_files.map do |f|
        filename             = f[:filename]
        covered_percent      = f[:covered_percent].to_f
        passed_min_threshold = threshold_predicate.call(filename, covered_percent)

        FileCoverage.new(filename, covered_percent, passed_min_threshold)
      end
    end

    private def render_simple_coverage_table(files)
      require 'terminal-table'

      message = "### Code Coverage\n\n"
      table = Terminal::Table.new(
        headings: ['File', 'Coverage'],
        style: { border_i: '|' },
        rows: files.map { |f| [f.filename, "#{format('%.02f', f.covered_percent)}%"] }
      ).to_s

      message + table.split("\n")[1..-2].join("\n")
    end

    private def render_coverage_table_with_threshold_mark(files)
      require 'terminal-table'

      message = "### Code Coverage\n\n"
      table = Terminal::Table.new(
        headings: [' ', 'File', 'Coverage'],
        style: { border_i: '|' },
        rows: (files.map do |f|
          [
            (f.passed_min_threshold ? CHECK_MARK : BALLOT_X),
            f.filename,
            "#{format('%.02f', f.covered_percent)}%"
          ]
        end)
      ).to_s

      message + table.split("\n")[1..-2].join("\n")
    end

  end
end
