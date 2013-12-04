#encoding:utf-8
# Copyleft (C) alphaKAI 2013 http://alpha-kai-net.info
# Alumixitter is one of the high spec Twitter client written in Ruby.

require "gtk3"
require "./twitruby"

class Alumixitter
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
		@builder.add_from_file("./alumixitter_gui.glade")
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

		@main_window.add_events(Gdk::Event::Type::KEY_PRESS)
		@main_window.signal_connect("destroy"){
			Gtk.main_quit
		}
		@main_window.signal_connect("key-press-event"){|w, e|
			if Gdk::Keyval.to_name(e.keyval) == "Tab"
				@main_window.set_focus(@button)
			end
		}

		@button.signal_connect("clicked"){
			self.post(@textview.buffer.text)
			@textview.buffer.delete
		}

		@main_tab_tweet = {}
	end

	def post(str)
		@twi.update(str)
	end

	def main
		@vbox_main = Gtk::VBox.new
		@vbox_reply= Gtk::VBox.new

		@main_tab.add(@vbox_main)
		@reply_tab.add(@vbox_reply)

		@main_window.show_all

		Thread.new{
			$i = 1
			loop{
				@twi.user_stream{|str|
					hbox = Gtk::HBox.new(false, 10)
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
							p $i
							#p post_id
							str_ = "#{post_id}:#{tweet}"
							#str_ = tweet
							tweet_label = Gtk::Label.new(str_)

							hbox.set_border_width(10)
							hbox.pack_start(tweet_label, nil, nil, 10)

							@main_tab_tweet.store(1,{
								:tweet => tweet,
								:rt => tweet =~ /^RT/ ? true : false,
								:post_by => post_id
							})
						}
					end

					Thread.new{
						if tweet.include?(@account_id)
							@vbox_reply.pack_end(hbox)
						else
							@vbox_main.pack_end(hbox)
						end
					}

					@main_window.show_all
					$i += 1
				}
			}
		}
		Gtk.main
	end
end
Alumixitter.new.main
