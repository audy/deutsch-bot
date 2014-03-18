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
