#!/usr/bin/env ruby

require 'singleton'
require 'speedtest'
require 'sqlite3'

# every 5 minutes
PAUSE_TIME = 60 * 5

class NullResults
  attr_reader :error

  def initialize(error: nil)
    @error = error
  end

  def latency
    0
  end

  def download_rate
    0
  end

  def upload_rate
    0
  end

  def pretty_download_rate
    ''
  end

  def pretty_upload_rate
    ''
  end
end

class Database
  class << self
    def db
      @db ||= SQLite3::Database.new 'test.db'
    end

    def init
      db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS results (
          test_time TEXT,
          latency REAL,
          download_rate REAL,
          upload_rate REAL,
          pretty_download_rate VARCHAR(30),
          pretty_upload_rate VARCHAR(30),
          error TEXT
        );
      SQL
    end

    def persist_results(results)
      insert_sql = <<-SQL
        INSERT INTO results (
          test_time,
          latency,
          download_rate,
          upload_rate,
          pretty_download_rate,
          pretty_upload_rate,
          error
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
      SQL

      db.execute(
        insert_sql,
        [
          Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          results.latency,
          results.download_rate,
          results.upload_rate,
          results.pretty_download_rate,
          results.pretty_upload_rate,
          results.respond_to?(:error) ? results.error : ''
        ]
      )
    end
  end
end

Database.init
loop do
  results = begin
    test = Speedtest::Test.new(
      download_runs: 4,
      upload_runs: 4,
      ping_runs: 4,
      download_sizes: [750, 1500, 4000],
      upload_sizes: [10_000, 400_000],
      debug: true
    )

    test.run
  rescue StandardError => e
    NullResults.new(error: e)
  end

  Database.persist_results(results)
  sleep PAUSE_TIME
end
