require 'faraday'
require 'faraday_middleware'

module Dota
  module API
    class Client
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration
      end

      def heroes(id = nil)
        id ? Hero.new(id) : Hero.all
      end

      def items(id = nil)
        id ? Item.new(id) : Item.all
      end

      def matches(options = {})
        if options.is_a?(Integer)
          id = options
          response = do_request("GetMatchDetails", match_id: id)["result"]
          Match.new(response) if response
        else
          options[:game_mode]             = options.delete(:mode_id) if options[:mode_id]
          options[:skill]                 = options.delete(:skill_level) if options[:skill_level]
          options[:date_min]              = options.delete(:from) if options[:from]
          options[:date_max]              = options.delete(:to) if options[:to]
          options[:account_id]            = options.delete(:player_id) if options[:player_id]
          options[:start_at_match_id]     = options.delete(:after) if options[:after]
          options[:matches_requested]     = options.delete(:limit) if options[:limit]
          options[:tournament_games_only] = options.delete(:league_only) if options[:league_only]

          response = do_request("GetMatchHistory", options)["result"]
          if response && (matches = response["matches"])
            matches.map { |match| Match.new(match) }
          end
        end
      end

      def leagues
        response = do_request("GetLeagueListing", language: "en")["result"]
        if response && (leagues = response["leagues"])
          leagues.map { |league| League.new(league) }
        end
      end

      private

      def do_request(method, params = {}, interface = "IDOTA2Match_570", method_version = "V001")
        url = "https://api.steampowered.com/#{interface}/#{method}/#{method_version}/"

        @faraday = Faraday.new(url) do |faraday|
          faraday.response :json
          faraday.adapter Faraday.default_adapter
        end

        response = @faraday.get do |request|
          request.url(url, params.merge(key: configuration.api_key))
        end
        response.body
      end
    end
  end
end
