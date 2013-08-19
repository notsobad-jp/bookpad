require 'sinatra'
require 'sinatra/reloader'
require 'net/http'
require 'uri'
require 'json'
require 'open-uri'
require 'iconv'
require 'mechanize'

#本番ではnewrelic使用
configure :production do
  require 'newrelic_rpm'
end

#ヘルパー
helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

#CSS/SCSS
get '/css/main.css' do
  scss :'scss/main'
end



#トップページ
get '/' do
	@back = '#';
	@disabled = 'disabled';
	haml :index
end


#検索結果画面
post '/search' do
	@back = '/';

	@keyword = params[:keyword]
	encoded_keyword = URI.escape(@keyword)
	app_id = ENV["RAKUTEN_KEY"]

	uri = URI.parse("https://app.rakuten.co.jp/services/api/BooksTotal/Search/20130522?format=json&keyword=#{encoded_keyword}&booksGenreId=000&applicationId=#{app_id}")
	json = Net::HTTP.get(uri)
	@result = JSON.parse(json)
	haml :search
end


#書籍詳細画面
post '/detail' do
	@back = 'javascript:history.back()';

	@keyword = params[:keyword]
	@isbn = params[:isbn]
	@title = params[:title]
	@author = params[:author]
	@mediumImageUrl = params[:mediumImageUrl]
	@publisherName = params[:publisherName]
	@salesDate = params[:salesDate]
	@stock = params[:stock] || nil

	#前画面で在庫情報とってないときだけ検索
	if @stock.nil?
		mech = Mechanize.new
		mech.get("https://www.coopbooknavi.jp/zaik/book_search.php")
		form = mech.page.form_with(:name => "frm")
		form.field_with(:name => "isbn").value = @isbn
		form.radiobutton_with(:value => "13036").check
		form.submit
		links = mech.page.links
		@page = Array.new
		links.each do |link|
			@page.push(link) if link.href.index("hng")
		end
		@stock = (@page.empty?) ? nil : @page.join(',')
	end
	@stock = nil if @stock == "0"

	haml :detail
end


#aboutページ
get '/about' do
	haml :about, :layout => false
end


#お店の在庫検索(ajaxで呼び出し)
get '/stock_search/:isbn' do
	return false if params[:isbn].nil?

	mech = Mechanize.new
	mech.get("https://www.coopbooknavi.jp/zaik/book_search.php")
	form = mech.page.form_with(:name => "frm")
	form.field_with(:name => "isbn").value = params[:isbn]
	form.radiobutton_with(:value => "13036").check
	form.submit
	links = mech.page.links
	@page = Array.new
	links.each do |link|
		@page.push(link) if link.href.index("hng")
	end

	@stock = (@page.empty?) ? nil : @page.join(',')
	return @stock
end
