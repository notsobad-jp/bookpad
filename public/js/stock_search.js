$(function(){
	var i = 0;
	$.each($(".col_2"), function(){
		i++;
		var isbn = $(this).find('input[name="isbn"]').attr("value");

		$.ajax({
			url: "/stock_search/" + isbn,
		}).done(function(data){
			//在庫なし
			if(data == 1) {
				$(this).find('div').addClass("error").removeClass("warning");
		  //在庫あり
			}else {
				$(this).find('div.notice').addClass("success").removeClass("warning");
			}
		}).fail(function(data){
			// alert('error!!!');
		});
	});
});
