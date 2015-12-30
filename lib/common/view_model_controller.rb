class ViewModelController
  def initialize(controller, action, params)
    @controller = controller
    @action = action
    @params = params
    @view_model = nil
  end

  def update(complete_id_with_key_name, new_state)
    @controller.update_param(complete_id_with_key_name, new_state)
    @controller.send(@action)
  end

  def params
    @controller.params
  end

  def render(*args, &block)
    @controller.render(*args, &block)
  end
end


