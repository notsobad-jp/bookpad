$(function(){
	//画面外スクロールでビョンビョンするの禁止
	$(document).on('touchmove', function(e){
		e.preventDefault();
	});
});
