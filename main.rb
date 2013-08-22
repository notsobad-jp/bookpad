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


#PJAX判定
class Sinatra::Request
  def pjax?
    env['HTTP_X_PJAX'] || self["_pjax"]
  end
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
	haml :index
end


#検索結果画面
get '/search/:keyword' do
	#GoogleBooksAPIで検索
	@keyword = params[:keyword]
	encoded_keyword = URI.escape(@keyword)
	max_result = 6
	uri = URI.parse("https://www.googleapis.com/books/v1/volumes?q=#{encoded_keyword}&maxResults=#{max_result}&country=JP")
	json = Net::HTTP.get(uri)
	@result = JSON.parse(json)

	haml :search, :layout => !request.pjax?
end


#書籍詳細画面
get '/detail/:isbn' do
	haml :detail, :layout => !request.pjax?
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
