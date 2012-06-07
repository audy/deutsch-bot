#!/usr/bin/env ruby

require 'bundler'
Bundler.require

# Connect to database
MongoMapper.connection = Mongo::Connection.new '127.0.0.1'
MongoMapper.database = "german"

# Create German word
class GermanWord
  include MongoMapper::Document

  key :word,       String, :unique => true
  key :article,    String
  key :definition, String
  
  before_validation :make_everything_lowercase
  
  private

  def make_everything_lowercase
    self.word.downcase!
    self.article.downcase!
  end
end

# So we can search the DB by word
GermanWord.ensure_index :word

# Make the bot
bot = Cinch::Bot.new do

  configure do |c|
    c.server   = "irc.freenode.net"
    c.channels = [ "#heyaudy" ]
    c.nick     = "deutschbot"
  end

  # Add a word to the vocabulary
  on :channel, /!add (\w*) (\w*), (.*)/ do |m, article, word, definition|

    # Create a new German word
    w = GermanWord.new :article    => article,
                       :word       => word,
                       :definition => definition

    if w.valid?
      w.save
      m.reply "#{m.user}, added #{word}!"
    else
      m.reply "#{m.user}, #{w.errors.values.first.join(', ')}"
    end
  end

  # Give stats about word database
  on :message, /!stats/ do |m|
    m.reply "#{m.user} I now know #{GermanWord.all.length} words!"
  end

  # Retrieve a random definition
  on :message, "!random" do |m|
    w = GermanWord.all.sample
    m.reply "#{w.article} #{w.word}, #{w.definition}"
  end

  # Get a definition given a word
  on :message, /!define (\w*)/ do |m, word|
    w = GermanWord.first :word => word
    unless w.nil?
      m.reply "#{w.article} #{w.word}, #{w.definition}"
    else
      m.reply "agnaite, what does #{word} mean?"
    end
    $answer = nil # no cheating!
  end

  # Quiz game
  on :message, /!quiz/ do |m|
    # Get 3 random words
    first, second, third = GermanWord.all.sample(3)

    case [:article, :word, :definition].sample
    when :article # Quiz 1 - Which is the correct article?
      m.reply "#{m.user}, which article goes with #{first.word}? (die, der, das)"
      $answer = first.article
    when :word # Quiz 2 - Which is the correct word?
      m.reply "#{m.user}, what is the word for '#{first.definition}'?"
      $answer = first.word
    when :definition # Quiz 3 - Which is the correct definition?
      m.reply "#{m.user}, which is the correct definition for '#{first.word}'..."
      choices = [first, second, third].map(&:definition).shuffle
      $answer = ['a', 'b', 'c'][choices.index(first.definition)]
      m.reply "(a) #{choices[0]} (b) #{choices[1]} or (c) #{choices[2]} ?"
    end
  end

  # Check if user got the correct answer
  on :message, /!answer (\w*)/ do |m, answer|
    if answer == $answer
      m.reply "#{m.user}, correct!"
    elsif $answer.nil?
      m.reply "#{m.user}, you haven't asked a question!"
    else
      m.reply "#{m.user}, nope!"
    end
  end

  # Give up on a quiz question
  on :message, /!giveup/ do |m|
    m.reply "#{m.user}, the answer was '#{$answer}', dumbass!"
    $answer = nil
  end
end

# Start the bot
bot.start
