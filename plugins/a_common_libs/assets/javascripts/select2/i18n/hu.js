/* Select2 4.0.3 | https://github.com/select2/select2/blob/master/LICENSE.md */
(function(){if(jQuery&&jQuery.fn&&jQuery.fn.select2&&jQuery.fn.select2.amd){var a=jQuery.fn.select2.amd}return a.define("select2/i18n/hu",[],function(){return{inputTooLong:function(c){var b=c.input.length-c.maximum;return"Túl hosszú. "+b+" karakterrel több, mint kellene."},inputTooShort:function(c){var b=c.minimum-c.input.length;return"Túl rövid. Még "+b+" karakter hiányzik."},loadingMore:function(){return"Töltés…"},maximumSelected:function(b){return"Csak "+b.maximum+" elemet lehet kiválasztani."},noResults:function(){return"Nincs találat."},searching:function(){return"Keresés…"}}}),{define:a.define,require:a.require}})();