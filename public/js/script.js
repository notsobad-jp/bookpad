$(function(){
	//画面外スクロールでビョンビョンするの禁止
	$(document).on('touchmove', function(e){
		e.preventDefault();
	});

	//検索ワード入れたら検索ボタンのリンクに追加
	$("#search input[name='keyword']").bind('change blur', function(){
		//TODO: キーワードのエスケープ処理
		$("#search a").attr("href", "/search/"+$(this).val());
	});


	//pjax
	$(document).on('click', 'a.pjax', function(e) {
	  e.preventDefault();
		var href = $(this).attr("href");
		$('#container section:nth-child(2)').animate({
			opacity: 0
		}, 'slow', function(){
		  $.pjax({
				url: href,
		    container : '#container',
		    timeout : 10000
		  });
		});
		//PJAX終了時のアニメーション
		$(document).on('pjax:end', function(){
			$('#container section:nth-child(2)').animate({ opacity: 1 }, 'slow');
		});
	});


	//検索結果画面
	if(location.href.indexOf("search") > 0) {
		//読み込んだデータをWebStorageに保存
		var storage = window.localStorage;
		$(".book_data").each(function(){
			//TODO: 変なISBNが入った時の処理
			var isbn = $(this).find("#isbn").text();
			if(!storage.getItem(isbn)) {
				//TODO: 要素が空の時の処理
				var data = {
					title: $(this).find("#title").text(),
					authors: $(this).find("#authors").text(),
					img_link: $(this).find("#img_link").text(),
					publisher: $(this).find("#publisher").text(),
				};
				storage.setItem(isbn, JSON.stringify(data));
			}
		});
	}

	//詳細表示画面
	if(location.href.indexOf("detail") > 0) {
		//WebStorageから情報を出力
		var storage = window.localStorage;
		var isbn = location.pathname.split("/")[2];

		if(storage.getItem(isbn)) {
			var data = JSON.parse(storage.getItem(isbn))
			$("#img").attr("src", data["img_link"]);
			$("#title span").text(data["title"]);
			$("#authors span").text(data["authors"].replace(/[",\[,\]]/g,''));
			$("#publisher span").text(data["publisher"]);
		}

		//TODO: WebStorageにないときはGoogleAPIをISBNで叩きにいく
	}
});
