/* Select2 4.0.3 | https://github.com/select2/select2/blob/master/LICENSE.md */
(function(){if(jQuery&&jQuery.fn&&jQuery.fn.select2&&jQuery.fn.select2.amd){var a=jQuery.fn.select2.amd}return a.define("select2/i18n/sk",[],function(){var b={2:function(c){return c?"dva":"dve"},3:function(){return"tri"},4:function(){return"štyri"}};return{inputTooLong:function(c){var d=c.input.length-c.maximum;return d==1?"Prosím, zadajte o jeden znak menej":d>=2&&d<=4?"Prosím, zadajte o "+b[d](!0)+" znaky menej":"Prosím, zadajte o "+d+" znakov menej"},inputTooShort:function(c){var d=c.minimum-c.input.length;return d==1?"Prosím, zadajte ešte jeden znak":d<=4?"Prosím, zadajte ešte ďalšie "+b[d](!0)+" znaky":"Prosím, zadajte ešte ďalších "+d+" znakov"},loadingMore:function(){return"Loading more results…"},maximumSelected:function(c){return c.maximum==1?"Môžete zvoliť len jednu položku":c.maximum>=2&&c.maximum<=4?"Môžete zvoliť najviac "+b[c.maximum](!1)+" položky":"Môžete zvoliť najviac "+c.maximum+" položiek"},noResults:function(){return"Nenašli sa žiadne položky"},searching:function(){return"Vyhľadávanie…"}}}),{define:a.define,require:a.require}})();