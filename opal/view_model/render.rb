module ActionView
  class Renderer
    def render_view_model(view_model, type=nil)
      #puts "in ActionView::Renderer#render_view_model"
      view_model.render(self, type)
    end
  end
end

