# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Nomos
  class GitHubClient
    def initialize(token:, api_url:)
      @token = token
      @api_url = api_url
    end

    def pull_request(repo, number)
      get_json("/repos/#{repo}/pulls/#{number}")
    end

    def pull_request_files(repo, number)
      get_paginated("/repos/#{repo}/pulls/#{number}/files")
    end

    def list_issue_comments(repo, number)
      get_paginated("/repos/#{repo}/issues/#{number}/comments")
    end

    def create_comment(repo, number, body)
      post_json("/repos/#{repo}/issues/#{number}/comments", body: body)
    end

    def update_comment(repo, comment_id, body)
      patch_json("/repos/#{repo}/issues/comments/#{comment_id}", body: body)
    end

    private

    def get_paginated(path)
      results = []
      page = 1

      loop do
        data, headers = request(:get, "#{path}?per_page=100&page=#{page}")
        results.concat(data)
        break unless headers["link"]&.include?("rel=\"next\"")

        page += 1
      end

      results
    end

    def get_json(path)
      data, = request(:get, path)
      data
    end

    def post_json(path, payload)
      data, = request(:post, path, payload)
      data
    end

    def patch_json(path, payload)
      data, = request(:patch, path, payload)
      data
    end

    def request(method, path, payload = nil)
      uri = URI.join(@api_url, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request_class = Net::HTTP.const_get(method.to_s.capitalize)
      request = request_class.new(uri)
      request["Accept"] = "application/vnd.github+json"
      request["User-Agent"] = "nomos"
      request["Authorization"] = "Bearer #{@token}" if @token
      request["Content-Type"] = "application/json" if payload
      request.body = JSON.generate(payload) if payload

      response = http.request(request)
      data = response.body.to_s.empty? ? {} : JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        message = data.is_a?(Hash) ? data["message"] : response.message
        raise Nomos::Error, "GitHub API error (#{response.code}): #{message}"
      end

      [data, response.each_header.to_h]
    rescue JSON::ParserError => e
      raise Nomos::Error, "GitHub API JSON error: #{e.message}"
    end
  end
end
