module Usability
  module TextileHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :wikitoolbar_for, :us
      end
    end
  end
  module InstanceMethods
    def wikitoolbar_for_with_us(field_id)
      res = wikitoolbar_for_without_us(field_id)
      res += javascript_tag(" var jst_elem = $('##{field_id}').parent().siblings('.jstElements')
                              var cut_button = jst_elem.find('.jstb_cut');
                              var code_button = jst_elem.find('#space1').get(0);
                              if (cut_button.length && wikiToolbar != undefined){
                                  var cut = cut_button.clone(true, true);
                                  cut_button.remove();
                                  wikiToolbar.draw_button(code_button, 'cut');
                              }
                              var us_color_text_button = jst_elem.find('.jstb_us_color_text');
                              if (us_color_text_button.length && wikiToolbar != undefined){
                                var us_color_text = us_color_text_button.clone(true, true);
                                us_color_text_button.remove();
                                wikiToolbar.draw_button(code_button, 'us_color_text');
                             }")
    end
  end
end