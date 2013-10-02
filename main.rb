require 'sinatra'
require 'sinatra/reloader'
require 'net/http'
require 'uri'
require 'json'
require 'open-uri'
require 'iconv'
require 'mechanize'
require 'i18n'

#本番ではnewrelic使用
configure :production do
  require 'newrelic_rpm'
end

#標準出力をバッファせず表示
STDOUT.sync = true

#PJAX判定
class Sinatra::Request
  def pjax?
    env['HTTP_X_PJAX'] || self["_pjax"]
  end
end

# We're going to load the paths to locale files,
I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml').to_s]


#ヘルパー
helpers do
	include Rack::Utils
	alias_method :h, :escape_html

  def get_locale
    @env["HTTP_ACCEPT_LANGUAGE"][0,2]  # Pulls the browser's language
  end

  def t(*args)
    I18n.t(*args)  # Just a simple alias
  end
end


#トップページ
get '/' do
	haml :index
end


#検索結果画面
get '/search/:keyword' do
	encoded_keyword = URI.escape(params[:keyword])
	puts "@[bookpad_#{ENV["RACK_ENV"]}.keywords] #{{'keyword'=>params[:keyword]}.to_json}"  #TDにログ記録

	@result = book_search(encoded_keyword, max_result=6)
	haml :search, :layout => !request.pjax?
end


#書籍詳細画面
get '/detail/:isbn' do
	store_id = 6 #民間図書館の全店舗検索
	@stocks = stock_search(params[:isbn], store_id)
	haml :detail, :layout => !request.pjax?
end


#aboutページ
get '/about' do
	haml :about, :layout => false
end


#お店の在庫検索(ajaxで呼び出し)
get '/stock_search/:isbn' do
	return false if params[:isbn].nil?
	store_id = 5  #TODO: ログイン情報に応じて検索店舗を変える
	@stock = stock_search(params[:isbn], store_id)

	return @stock
end

#在庫検索結果をTreasureDataにログ記録(ajaxで呼び出し)
get '/log_stock/:isbn/:title/:stocked' do
	puts "@[bookpad_#{ENV["RACK_ENV"]}.stocks] #{{'isbn'=>params[:isbn], 'title'=>params[:title], 'stocked'=>params[:stocked]}.to_json}"  #TDにログ記録
end


#キーワードから本を検索
def book_search(keyword, max_result)
	#GoogleBooksAPI
	# uri = URI.parse("https://www.googleapis.com/books/v1/volumes?q=#{encoded_keyword}&maxResults=#{max_result}&country=JP")

	#RakutenBooksAPI
	uri = URI.parse("https://app.rakuten.co.jp/services/api/BooksTotal/Search/20130522?format=json&keyword=#{keyword}&booksGenreId=000&hits=#{max_result}&applicationId=#{ENV['RAKUTEN_KEY']}")

	json = Net::HTTP.get(uri)
	@result = JSON.parse(json)
end


#在庫検索
def stock_search(isbn, store_id)
	case store_id
	when 1 #三省堂書店
		mech = Mechanize.new
		mech.post('https://www.coopbooknavi.jp/zaik/book_search_result.php', {'isbn'=>isbn, "and_or"=>"1", "ten_sel"=>"13036", "search"=>"1"})
		links = mech.page.links
		@page = Array.new
		links.each do |link|
			@page.push(link) if link.href.index("hng")
		end
		@stock = (@page.empty?) ? nil : @page.join(',')
	when 2 #ブックハウス神保町
		mech = Mechanize.new
		mech.get("http://jinbou.books-sanseido.co.jp/jinbou/bookTownJinbou.do?syISBN=#{isbn}")
		stock_info = mech.page.at("table[3]").at("table[3]").at("tr[5]").at("td[3]").at("p").inner_text
		@stock = (stock_info.empty?) ? nil : stock_info.gsub(".", ", ")
	when 3 #岩波ブックセンター
		mech = Mechanize.new
		mech.get("http://jinbou.books-sanseido.co.jp/jinbou/bookTownJinbou.do?syISBN=#{isbn}")
		stock_info = mech.page.at("table[3]").at("table[3]").at("tr[3]").at("td[3]").at("p").inner_text
		@stock = (stock_info.empty?) ? nil : stock_info.gsub(".", ", ")
	when 4 #東大生協(本郷)
		mech = Mechanize.new
		mech.post('https://www.coopbooknavi.jp/zaik/book_search_result.php', {'isbn'=>isbn, "and_or"=>"1", "ten_sel"=>"13036", "search"=>"1"})
		links = mech.page.links
		@page = Array.new
		links.each do |link|
			@page.push(link) if link.href.index("hng")
		end
		@stock = (@page.empty?) ? nil : @page.join(',')
	when 5 #民間図書館(ちばぎんざ)
		mech = Mechanize.new
		begin
			stocked = false
			mech.get("http://librarylife.net/search_detail.aspx?isbn13=#{isbn}")
			stocks = mech.page.at("table#ctl00_ContentPlaceHolder1_GridView1").search("tr")
			stocks.each_with_index do |stock, i|
				next if i==0 #見出し行はスキップ
				stocked = true if stock.at("td[3]").inner_text=='開架' && stock.at("td[2]").inner_text=="ちばぎんざ図書館"
			end
			@stock = '開架' if stocked
		rescue
			@stock = nil
		end
	when 6 #民間図書館(全店舗検索)
		mech = Mechanize.new
		begin
			mech.get("http://librarylife.net/search_detail.aspx?isbn13=#{isbn}")
			@stocks = mech.page.at("table#ctl00_ContentPlaceHolder1_GridView1").search("tr")
		rescue
			@stocks = nil
		end
	end
end
