$(function(){
	//画面外スクロールでビョンビョンするの禁止
	$(document).on('touchmove', function(e){
		e.preventDefault();
	});

	//検索ワード入れたら検索ボタンのリンクに追加
	$("#search input[name='keyword']").bind('change blur click', function(){
		if($(this).val()){
			var encoded_keyword = encodeURIComponent($(this).val());
			$("#search a").addClass("pjax");
			$("#search a").attr("href", "/search/"+ encoded_keyword);
		}else {
			//空文字のときは検索させない
			$("#search a").removeClass("pjax");
			$("#search a").attr("href", "javascript:void(0)");
		}
	});

	//PJAX処理
	$(document).on('click', 'a.pjax', function(e) {
	  e.preventDefault();
		var href = $(this).attr("href");
		$('#container section:nth-child(3)').animate({
			opacity: 0
		}, 'slow', function(){
			$("#loader").html("<img src='/img/loader.gif'/>");
		  $.pjax({
				url: href,
		    container : '#container',
		    timeout : 10000
		  });
		});

		//PJAX終了時の処理
		$(document).on('pjax:end', function(){
			$('#container section:nth-child(3)').animate({ opacity: 1 }, 'slow');
			$('#loader').empty();

			//SEARCH画面への遷移時
			if(location.href.indexOf("search") > 0) {
				$('header li:first-child a').attr('href', '/').removeClass('disabled');
				//裏で在庫検索して、基本情報と一緒にWebStorageに保存
				var storage = window.localStorage;

				$(".book_data").each(function(){
					var isbn = $(this).find(".isbn").text();
					if(!storage.getItem(isbn)) {
						//在庫検索
						if(isbn) {  //変なISBNが入った時の処理
							$.ajax({
								url: "/stock_search/" + isbn,
							}).done(function(data){
								var i = 0;
								$(".isbn").each(function(k, val) {
									if(val.innerText == isbn){ i = k; }
								});

								var div = $('.col_2').eq(i);
								//在庫あり
								if(data) {
									div.find('.notice').addClass('success').removeClass('warning');
									div.find('.notice').find('i').addClass('icon-ok-sign').removeClass('icon-spinner');
									div.find('.notice').find('span').text('在庫あり');
								//在庫なし
								}else {
									div.find('.notice').addClass('error').removeClass('warning');
									div.find('.notice').find('i').addClass('icon-remove-sign').removeClass('icon-spinner');
									div.find('.notice').find('span').text('在庫なし');
								}

								//基本情報と合わせてWebStorageに保存
								var book_info = {
									title: div.find(".title").text(),
									authors: div.find(".authors").text(),
									img_link: div.find(".img_link").text(),
									publisher: div.find(".publisher").text(),
									stock: data,
								};
								storage.setItem(isbn, JSON.stringify(book_info));

							}).fail(function(data){
								var i = 0;
								$(".isbn").each(function(k, val) {
									if(val.innerText == isbn){ i = k; }
								});
								div.find('.notice').addClass('error').removeClass('warning');
								div.find('.notice').find('i').addClass('icon-remove-sign').removeClass('icon-spinner');
								div.find('.notice').find('span').text('在庫なし');
							});
						}else {
							var i = 0;
							$(".isbn").each(function(k, val) {
								if(val.innerText == isbn){ i = k; }
							});

							var div = $('.col_2').eq(i);
							div.find('.notice').addClass('error').removeClass('warning');
							div.find('.notice').find('i').addClass('icon-remove-sign').removeClass('icon-spinner');
							div.find('.notice').find('span').text('在庫なし');

							//基本情報だけWebStorageに保存
							var book_info = {
								title: div.find(".title").text(),
								authors: div.find(".authors").text(),
								img_link: div.find(".img_link").text(),
								publisher: div.find(".publisher").text(),
								stock: "",
							};
							storage.setItem(isbn, JSON.stringify(book_info));
						}
					}else {
						//情報保存済みの場合はそれを取得して表示
						var data = JSON.parse(storage.getItem(isbn));
						if(data["stock"]){
							$(this).prev().addClass('success').removeClass('warning');
							$(this).prev().find('i').addClass('icon-ok-sign').removeClass('icon-spinner');
							$(this).prev().find('span').text('在庫あり');
						}else {
							$(this).prev().addClass('error').removeClass('warning');
							$(this).prev().find('i').addClass('icon-remove-sign').removeClass('icon-spinner');
							$(this).prev().find('span').text('在庫なし');
						}
					}
				});
			}

			//DETAIL画面への遷移時
			if(location.href.indexOf("detail") > 0) {
				$('header li:first-child a').attr('href', 'javascript:history.back()').removeClass('disabled');
				//WebStorageから情報を出力
				var storage = window.localStorage;
				var isbn = location.pathname.split("/")[2];

				if(storage.getItem(isbn)) {
					var data = JSON.parse(storage.getItem(isbn));
					if(data["img_link"]){
						$("#img").empty();
						$("#img").append("<img src='"+data["img_link"]+"' alt='書影'>");
					}else {
						$("#img").addClass("no_img");
						$("#img").innerText("No Image..");
					}
					$("#title span").text(data["title"]);
					$("#authors span").text(data["authors"].replace(/[",\[,\]]/g,''));
					$("#publisher span").text(data["publisher"]);
					if(data["stock"]){
						$("#stock").removeClass("warning").addClass("success");
						$("#stock i").removeClass("icon-spinner").addClass("icon-ok-sign");
						$("#stock span").eq(0).text("棚番号：");
						$("#stock span").eq(1).text(data["stock"]);
					}else {
						$("#stock").removeClass("warning").addClass("error");
						$("#stock i").removeClass("icon-spinner").addClass("icon-remove-sign");
						$("#stock span").eq(0).text("在庫なし");
					}
				}

				//TODO: WebStorageにないときはGoogleAPIをISBNで叩きにいく

				//検索結果をTreasureDataにログ記録
				//TODO: パラメータのエスケープ
				var stocked = data["stock"] ? 1 : 0;
				$.ajax({
					url: "/log_stock/" + isbn + "/" + data["title"] + "/"+ stocked
				});
			}
		});
	});
});
