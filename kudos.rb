#!/usr/bin/ruby
require 'net/http'
require 'json'
require 'uri'
require 'date'

SLACK_API_BASE="https://slack.com/api"

SLACK_PLUGIN_TOKEN="<Insert_SlackPlugin_Token>"
CHANNEL_ID="<Insert_Channel_id>"
BOT_TOKEN="<Insert_bot_token>"

class MessageData
  attr_accessor :message_time_stamp, :reactions

  def initialize(message_time_stamp, reactions)
    @message_time_stamp = message_time_stamp
    @reactions = reactions
  end
end

def get_channel_history oldest, latest
	uri = URI("#{SLACK_API_BASE}/conversations.history")
	params = { 
		:token => SLACK_PLUGIN_TOKEN, 
		:channel => KUDOS_CHANNEL_ID,
		:latest => latest,
		:oldest => oldest }

	uri.query = URI.encode_www_form(params)
	res = Net::HTTP.get_response(uri)
	res.body if res.is_a?(Net::HTTPSuccess)
end

def get_user_IDs text
	text.scan(/#{Regexp.escape("<@")}(.*?)#{Regexp.escape(">")}/)
end

def get_user_JSON id
	uri = URI("#{SLACK_API_BASE}/users.info")
	params = { 
		:token => SLACK_PLUGIN_TOKEN, 
		:user => id }

	uri.query = URI.encode_www_form(params)
	res = Net::HTTP.get_response(uri)
	res.body if res.is_a?(Net::HTTPSuccess)
end

def get_username id
	profile = get_user_JSON(id)
	data = JSON.parse(profile)
	data['user']['name']
end

def get_message_permalink message_time_stamp
	message_permalink = ""
	uri = URI("#{SLACK_API_BASE}/chat.getPermalink")
	params = { 
		:token => SLACK_PLUGIN_TOKEN, 
		:channel => KUDOS_CHANNEL_ID,
		:message_ts => message_time_stamp}

	uri.query = URI.encode_www_form(params)
	request_response = Net::HTTP.get_response(uri)
	if request_response.is_a?(Net::HTTPSuccess)
		api_response = JSON.parse(request_response.body)
		if api_response['ok']
			message_permalink = api_response['permalink']
		end
	end

	if message_permalink.empty?
		puts "Failed to get winner message permalink!"
	end

	message_permalink
end

def invite_user id
	uri = URI("#{SLACK_API_BASE}/channels.invite")
	params = {
		:token => SLACK_PLUGIN_TOKEN,
		:channel => KUDOS_CHANNEL_ID,
		:user => id }

	uri.query = URI.encode_www_form(params)
	res = Net::HTTP.get_response(uri)
end

def choose_winner pool
	prng = Random.new
	index =  prng.rand(0..pool.size)
	pool[index]
end

def get_react_count msg
	voters = Array.new
	if msg.has_key?('reactions')
		msg['reactions'].each do |rct|
			voters << rct['users']
		end
	end
	voters.flatten.uniq.count #to avoid counts of multiple votes by the same person for one nomination
end

def get_stats pool
	nominees = pool.uniq
	nominees.each { |id| puts "#{get_username(id)} has #{pool.count(id)} entries\n=====" }
end

def parse_data data
	users = Array.new
	user_messages = Hash.new
	pool = Array.new
	total_reactions = 0

	#Note: Pagination not implemented. API returns a max of 100 results unless &limit is specified
	if data["has_more"] == true
		puts "!!! Please implement pagination. There are more than 100 messages on channel that day !!!"
	end

	data["messages"].each do |msg|
        next if msg.has_key?('subtype') # Usually subtypes are for people who joined, left, shared files... etc. https://api.slack.com/events/message
    	user_ids = get_user_IDs("#{msg['text']}")
    	user_ids = user_ids.flatten.uniq #to avoid counts of multiple mentions of the same person in one text
    	if !user_ids.empty?
    		reactions = get_react_count(msg)

    		user_ids.each { |id|
	    		user_message_data = user_messages[id]
	    		skip_add_message = user_message_data != nil and user_message_data.reactions > reactions
	    		if !skip_add_message
	    			user_messages[id] = MessageData.new(msg['ts'], reactions)
	    		end 
    		}

    		total_reactions += reactions
    		users << user_ids
    		begin 
    			pool << user_ids
    			reactions -= 1
    		end while reactions >= 0
    	end
    end

    # puts "There are #{users.flatten.length} mentions today!"
    # puts "With #{total_reactions} reactions in total!"
    # puts "Number of users in pool: #{pool.flatten.length}"
    [pool.flatten, users.flatten.length, total_reactions, user_messages]
end

def post_to_slack output
	params = {
        text: output,
        channel: "#kudos",
        username: "Kudos",
        icon_emoji: ":sassyparrot:",
        mrkdown: true
    }

    uri = URI.parse("https://hooks.slack.com/services/" + BOT_TOKEN)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = params.to_json
    res = http.request(request)
    puts res.body
end

module Kudos
	yesterday = Time.now.strftime("%d").to_i - 1
	month = Time.now.month
	monthName = Date::MONTHNAMES[month]
	if Time.now.strftime("%a") == 'Mon'
		yesterday -=2
		yesterday = 1
		end_time = Time.new(2018, month, yesterday, 23, 59, 0, "-05:00").to_i
		# end_time = Time.now().to_i #Debug
	else
		end_time = Time.new(2018, month, yesterday, 23, 59, 0, "-05:00").to_i
	end
	start_time = Time.new(2018, month, yesterday, 0, 0, 0, "-05:00").to_i


	history = get_channel_history(start_time, end_time)
	data = JSON.parse(history)
	# puts JSON.pretty_generate(data)
	pool, numMentoins, numReactions, user_messages = parse_data(data)
	# get_stats(pool)
	if !pool.empty?
		winner_id = choose_winner(pool)
	    winner_name = get_username(winner_id)
	    winner_message_permalink = get_message_permalink(user_messages[winner_id].message_time_stamp)
		text = "Thank you for your votes! We got #{pool.uniq.size} nominations and #{numReactions} unique reactions on #{monthName} #{Time.at(start_time).day}.\n"
		text = "#{text}\nAnd the winner is... <@#{winner_id}|#{winner_name}>!\nCome to the reception to claim your prize, and keep up the good work :slightly_smiling_face:"
		invite_user(winner_id)
		if !winner_message_permalink.empty?
			text = "#{text}\n\nWinning Kudos message: #{winner_message_permalink}"
		end 
	else
		text = "There were no kudos given out on #{monthName}/#{Time.at(start_time).day}/2018 :rip:"
	end
	puts text

	if ARGV[0] == "post"
		post_to_slack(text)
	end
end
