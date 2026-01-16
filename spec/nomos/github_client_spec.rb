# frozen_string_literal: true

require "net/http"

RSpec.describe Nomos::GitHubClient do
  class FakeHTTP
    def initialize(responses)
      @responses = responses
    end

    attr_accessor :use_ssl

    def request(_request)
      @responses.shift
    end
  end

  class FakeResponse
    def initialize(code:, body:, headers: {}, success: true, message: "OK")
      @code = code
      @body = body
      @headers = headers
      @success = success
      @message = message
    end

    attr_reader :body, :message, :code

    def each_header
      @headers.to_h
    end

    def is_a?(klass)
      return true if klass == Net::HTTPSuccess && @success

      super
    end
  end

  let(:client) { described_class.new(token: "token", api_url: "https://api.github.com") }

  it "fetches JSON responses" do
    response = FakeResponse.new(code: "200", body: "{\"number\":1}", success: true)
    allow(Net::HTTP).to receive(:new).and_return(FakeHTTP.new([response]))

    pr = client.pull_request("owner/repo", 1)

    expect(pr["number"]).to eq(1)
  end

  it "follows pagination links" do
    response1 = FakeResponse.new(
      code: "200",
      body: "[{\"id\":1}]",
      headers: { "link" => "<https://api.github.com?page=2>; rel=\"next\"" },
      success: true
    )
    response2 = FakeResponse.new(code: "200", body: "[{\"id\":2}]", success: true)
    allow(Net::HTTP).to receive(:new).and_return(FakeHTTP.new([response1, response2]))

    comments = client.list_issue_comments("owner/repo", 1)

    expect(comments.map { |comment| comment["id"] }).to eq([1, 2])
  end

  it "raises on API error responses" do
    response = FakeResponse.new(code: "400", body: "{\"message\":\"bad\"}", success: false, message: "Bad Request")
    allow(Net::HTTP).to receive(:new).and_return(FakeHTTP.new([response]))

    expect {
      client.pull_request("owner/repo", 1)
    }.to raise_error(Nomos::Error, /GitHub API error/)
  end

  it "raises on invalid JSON" do
    response = FakeResponse.new(code: "200", body: "{", success: true)
    allow(Net::HTTP).to receive(:new).and_return(FakeHTTP.new([response]))

    expect {
      client.pull_request("owner/repo", 1)
    }.to raise_error(Nomos::Error, /GitHub API JSON error/)
  end
end
