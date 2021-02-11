require 'async'
require 'async/barrier'
require 'async/http'
require 'async/http/internet'

Async.logger.level = :debug

class Test
  def http_client
    @http_client ||= begin
      STDERR.puts "init client"
      options = {
        :retries => 0,
      }
      options[:protocol] = Async::HTTP::Protocol::HTTP2

      Async::HTTP::Internet.new(**options)
    end
  end

  def concurrent_requests_catching_errors
    Sync do |task|
      yield task
    end
  end

  def download(url)
    response = Async::Task.current.async do
      http_client.get(url)
    end.wait
    body = response.read
    case response.status
    when 301
      redirect_location = response.headers['location']
      STDERR.puts "Redirecting to #{redirect_location}"
      download(redirect_location)
    else
      STDERR.puts "Downloaded #{url}"
    end
  end

  def download_rxswift
    versions = %w[0.0.0]
    # versions = %w[0.0.0 0.7]
    # versions = %w[0.0.0 0.7 0.7.1]
    # versions = %w[0.0.0 0.7 0.7.1 0.8 0.9 1.0 1.1 1.2 1.2.1 1.3 1.3.1 1.4 1.5 1.6 1.7 1.8 1.8.1 1.9 1.9.1 2.0-alpha.1 2.0.0 2.0.0-alpha.2 2.0.0-alpha.3 2.0.0-alpha.4 2.0.0-beta.1 2.0.0-beta.2 2.0.0-beta.3 2.0.0-beta.4 2.0.0-rc.0 2.1.0 2.2.0 2.3.0 2.3.1 2.4 2.5.0 2.6.0 2.6.1 3.0.0 3.0.0-beta.1 3.0.0-beta.2 3.0.0-rc.1 3.0.0.alpha.1 3.0.1 3.1.0 3.2.0 3.3.0 3.3.1 3.4.0 3.4.1 3.5.0 3.6.0 3.6.1 4.0.0 4.0.0-alpha.0 4.0.0-alpha.1 4.0.0-beta.0 4.0.0-beta.1 4.0.0-rc.0 4.1.0 4.1.1 4.1.2 4.2.0 4.3.0 4.3.1 4.4.0 4.4.1 4.4.2 4.5.0 5.0.0 5.0.1 5.1.0 5.1.1 6.0.0 6.0.0-rc.1 6.0.0-rc.2]
    concurrent_requests_catching_errors do |task|
      versions.each do |v|
        task.async do
          download("https://cdn.cocoapods.org/Specs/2/e/c/RxSwift/#{v}/RxSwift.podspec.json")
        end
      end
    end
    STDERR.puts "Sync finished"
    
    # STDERR.puts "Downloaded #{results.count}"
  end
end

test = Test.new

2.times do |i|
  STDERR.puts "Iteration: #{i}"
  test.download_rxswift
end