require 'sinatra'
require 'sinatra/reloader'

require 'net/http'
require 'uri'
require 'json'

require 'open-uri'
require 'iconv'
require 'mechanize'

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

#トップページ
get '/' do
	erb :index
end

#検索結果画面
post '/search' do
	@keyword = params[:keyword]
	encoded_keyword = URI.escape(@keyword)
	app_id = 1094360803658595324

	uri = URI.parse("https://app.rakuten.co.jp/services/api/BooksTotal/Search/20130522?format=json&keyword=#{encoded_keyword}&booksGenreId=000&applicationId=#{app_id}")
	json = Net::HTTP.get(uri)
	@result = JSON.parse(json)
	erb :search
end

#書籍詳細画面
get '/result/:isbn' do
	isbn = params[:isbn]
	mech = Mechanize.new

	mech.get("https://www.coopbooknavi.jp/zaik/book_search.php")
	form = mech.page.form_with(:name => "frm")
	form.field_with(:name => "isbn").value = isbn
	form.radiobutton_with(:value => "13036").check
	form.submit
	links = mech.page.links
	@page = Array.new
	links.each do |link|
		@page.push(link) if link.href.index("hng")
	end

	erb :result
end
