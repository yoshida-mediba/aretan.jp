/* Select2 4.0.3 | https://github.com/select2/select2/blob/master/LICENSE.md */
(function(){if(jQuery&&jQuery.fn&&jQuery.fn.select2&&jQuery.fn.select2.amd){var a=jQuery.fn.select2.amd}return a.define("select2/i18n/th",[],function(){return{inputTooLong:function(c){var b=c.input.length-c.maximum,d="โปรดลบออก "+b+" ตัวอักษร";return d},inputTooShort:function(c){var b=c.minimum-c.input.length,d="โปรดพิมพ์เพิ่มอีก "+b+" ตัวอักษร";return d},loadingMore:function(){return"กำลังค้นข้อมูลเพิ่ม…"},maximumSelected:function(c){var b="คุณสามารถเลือกได้ไม่เกิน "+c.maximum+" รายการ";return b},noResults:function(){return"ไม่พบข้อมูล"},searching:function(){return"กำลังค้นข้อมูล…"}}}),{define:a.define,require:a.require}})();