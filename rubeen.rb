#encoding:utf-8
# Copyleft (C) alphaKAI 2013 http://alpha-kai-net.info

require "gtk3"
require "./twitruby"

class Rubeen
	def initialize
		consumer_key = ""
		consumer_secret = ""
		access_token = ""
		access_token_secret = ""

		cunsmer_array=[]
		cunsmer_array << consumer_key << consumer_secret << access_token << access_token_secret
		@twi=TwitRuby.new
		@twi.initalize_connection(cunsmer_array)

		@builder = Gtk::Builder.new
		@builder.add_from_file("./rubeen_gui.glade")
		@main_window = @builder["window1"]
		@main_tab = @builder["scrolledwindow1"]
		@reply_tab = @builder["scrolledwindow2"]

		@button = @builder["button1"]
		@textview = @builder["textview1"]
		@account_combo = @builder["comboboxtext1"]

		@account_id = @twi.verify_credentials["screen_name"]
		# Add account to combobox
		@account_combo.append_text(@account_id)
		@account_combo.show

		@main_window.signal_connect("destroy"){
			Gtk.main_quit
		}

		@button.signal_connect("clicked"){
			@twi.update(@textview.buffer.text)
			@textview.buffer.delete
		}
	end

	def main
		@vbox_main = Gtk::VBox.new
		@vbox_reply= Gtk::VBox.new

		@main_tab.add(@vbox_main)
		@reply_tab.add(@vbox_reply)

		@main_window.show_all

		Thread.new{
			loop{
				@twi.user_stream{|str|
					hbox = Gtk::HBox.new
					tweet = str["text"]

					# 100文字ぐらいで折り返し
#=begin
					begin
						if tweet.size >= 100
							tweet.insert(100, "\n")
						end
					rescue
					end
#=end
					begin
						Thread.new{
							post_id = str["user"]["screen_name"]

							#p post_id
							str_ = "#{post_id}:#{tweet}"
							#str_ = tweet
							tweet_label = Gtk::Label.new(str_)
							tweet_label.set_justify(Gtk::JUSTIFY_LEFT)

							hbox.pack_start(tweet_label)
						}
					end

					Thread.new{
						if tweet.include?(@account_id)
							@vbox_reply.add(hbox)
						else
							@vbox_main.add(hbox)
						end
					}

					@main_window.show_all
				}
			}
		}
		Gtk.main
	end
end
Rubeen.new.main
