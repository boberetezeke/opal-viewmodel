class ViewModelController
  def render_view_model(new_view_model)
    @controller.render_view_model new_view_model, :top_level
  end
end
