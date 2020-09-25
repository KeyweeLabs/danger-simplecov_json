# danger-simplecov_json

[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE.txt)

Report your Ruby app test suite code coverage in [Danger](https://github.com/danger/danger).

Before using this plugin, you need to setup your project to use [SimpleCov](https://github.com/colszowka/simplecov) to get code coverage information and [simplecov-json](https://github.com/vicentllongo/simplecov-json) to format it as JSON.

## How does it look?

| File   | Coverage |
|--------|----------|
| foo.rb | 20.00%   |
| bar.rb | 40.00%   |
| baz.rb | 60.00%   |

## Installation

Add this line to your Gemfile:

```ruby
gem 'danger-simplecov_json', git: 'https://github.com/KeyweeLabs/danger-simplecov_json.git'
```

## Usage

### Individual file coverage

To see the table with individual file coverage for new or modified files add this line to your `Dangerfile`:

```ruby
simplecov.individual_report('coverage/coverage.json')
```

You can specify minimum file coverage by file and fail the danger when unmet:

```ruby
simplecov.individual_report('coverage/coverage.json', minimum_coverage_by_file: 99.9)
```

By default it will check coverage of all files that were matched but if you have more exoctic use cases, e.g. you want to exclude legacy files and only enforce it on new files you can pass a proc object instead:

```ruby
predicate = lambda do |filename, covered_percent|
  git.added_files.include?(filename) ? covered_percent >= 80 : true
end

simplecov.individual_report('coverage/coverage.json', minimum_coverage_by_file: predicate)
```

Additionally, you can pass custom file matcher to match between commited files and files reported in coverage report:

```ruby
files_matcher = lambda do |commited_files, coverage_file_name| do
  coverage_file_name =~ %r{api/v2} && commited_files.include?(coverage_file_name)
end

simplecov.individual_report('coverage/coverage.json', files_matcher: files_matcher)
```

### General project coverage

In case you want just a simple message with a code coverage percentage for your project use `#report` method:

```ruby
simplecov.report 'coverage/coverage.json'
```

This would report a message like this one:

> Code coverage is now at 99.15% (1512/1525 lines)

You can also make the message not [sticky](http://danger.systems/reference.html):

```ruby
simplecov.report('coverage/coverage.json', sticky: false)
```

## License

MIT

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
