module ActionController
  module Rendering
    def render_view_model(view_model, type=nil)
      view_model.render(self, type)
    end
  end
end

module ActionView
  module Helpers
    module RenderingHelper
      def render_view_model(view_model, type=nil)
        view_model.render(self, type)
      end
    end
  end
end
