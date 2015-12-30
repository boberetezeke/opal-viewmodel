class ViewModelController
  def render_view_model(new_view_model)
    if @view_model
      #puts "old_view_model = #{@view_model.name}"
      #puts "new_view_model = #{new_view_model.name}"
      @view_model.compare_and_render(new_view_model)
      @view_model = new_view_model
    else
      #puts "initially: new_view_model = #{new_view_model.name}"
      @view_model = new_view_model
      @view_model.register_handlers
    end
  end
end
