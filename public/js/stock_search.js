$(function(){
	//テキスト行数揃えて...で省略
	$(".col_2 p").trunk8({
		fill: '...'
	});


	//在庫検索結果を遅延表示
	var i = 0;
	$.each($(".col_2"), function(){
		var isbn = $(this).find('input[name="isbn"]').attr("value");
		var div = $('.col_2').eq(i);

		if(!isbn) {
			div.find('.notice').addClass('error').removeClass('warning');
			div.find('i').addClass('icon-remove-sign').removeClass('icon-spinner');
			div.find('.notice').find('span').text('在庫なし');
			i++;
			return;
		}

		$.ajax({
			url: "/stock_search/" + isbn,
		}).done(function(data){
			var div = $('.col_2').eq(i);
			//在庫あり
			if(data) {
				div.find('.notice').addClass('success').removeClass('warning');
				div.find('i').addClass('icon-ok-sign').removeClass('icon-spinner');
				div.find('.notice').find('span').text('在庫あり');
				div.find('input[name="stock"]').val(data);
			//在庫なし
			}else {
				div.find('.notice').addClass('error').removeClass('warning');
				div.find('i').addClass('icon-remove-sign').removeClass('icon-spinner');
				div.find('.notice').find('span').text('在庫なし');
				div.find('input[name="stock"]').val(0);
			}
			i++;
		}).fail(function(data){
				// alert("error");
			i++;
		});
	});
});
