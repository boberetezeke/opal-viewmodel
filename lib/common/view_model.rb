class ViewModel
  class Actions
    attr_reader :actions
    def initialize
      @actions = []
    end

    def add(action_or_actions, indent="")
      if action_or_actions.is_a?(self.class)
        action_or_actions.actions.each{|action| push(action, indent)}
      else
        push(action_or_actions, indent)
      end
    end

    def push(action, indent)
      puts "#{indent} Adding action: #{action}"
      @actions.push(action)
    end

    def process(indent)
      @actions.select(&:delete?).each{|action| action.execute(indent)}
      @actions.reject(&:delete?).each{|action| action.execute(indent)}

      @actions = []
    end

    def to_s
      @actions.to_s
    end
  end

  class Action
    def self.delete(view_model)
      new(:delete, view_model)
    end

    def self.replace(old_view_model, new_view_model, html)
      new(:replace, old_view_model, new_view_model, html)
    end

    def self.insert(new_view_model, parent_view_model, html)
      new(:insert, nil, new_view_model, html, parent_view_model)
    end

    attr_reader :type
    def initialize(type, old_view_model, new_view_model=nil, html=nil, parent_view_model=nil)
      @type = type
      @old_view_model = old_view_model
      @new_view_model = new_view_model
      @parent_view_model = parent_view_model
      @html = html
    end

    def unregister(indent="")
      if @old_view_model
        puts "#{indent} Unregister for #{@old_view_model}"
        @old_view_model.unregister_handlers
      end
    end

    def register(indent="")
      if @new_view_model
        puts "#{indent} Register for #{@new_view_model}"
        @new_view_model.register_handlers
      end
    end

    def execute(indent="")
      self.send(@type, indent)
    end

    def replace(indent="")
      selector = "##{@old_view_model.id}"
      html = @html
      puts "#{indent} Replacing at #{@old_view_model.id}, HTML = #{html}"
      unregister(indent)
      `$(selector).replaceWith(html)`
      register(indent)
    end

    def insert(indent="")
      puts "#{indent} Appending at #{@parent_view_model.id}, HTML = #{@html}"
      Element.find("##{@parent_view_model.id}").append(@html)
      register(indent)
    end

    def delete(indent="")
      unregister(indent)
      puts "#{indent} Deleting at #{@old_view_model.id}"
      element = Element.find("##{@old_view_model.id}")
      element.remove
    end

    def delete?
      @type == :delete
    end

    def to_s
      str = "Action: #{@type}: " 
      str + case @type
      when :delete
        "#{@old_view_model}"
      when :insert
        "#{@new_view_model} appended to #{@parent_view_model}"
      when :replace
        "#{@new_view_model} with #{@old_view_model}"
      end
    end
  end

  attr_reader :controller, :view_name, :view_models, :values, :state
  def initialize(controller, view_name, view_models, values, state_defaults)
    @controller = controller
    @view_name = view_name
    @view_models = view_models
    @values = values
    @parent_id = ""
    @state = {}
    initialize_state_with_defaults(state_defaults)
  end

  def parent_id=(parent_id)
    @parent_id = parent_id
  end

  def complete_id
    @parent_id + "-" + self.id
  end

  def complete_id_with_key_name(key_name)
    complete_id + "-" + key_name.to_s
  end

  def initialize_state_with_defaults(state_defaults)
    #puts "state_defaults = #{state_defaults}"
    state_defaults.each do |key_name, default|
      param_key = complete_id_with_key_name(key_name)
      #puts "param_key = #{param_key}"
      param_value = @controller.params[param_key]
      #puts "param_value = #{param_value}, default = #{default}"
      @state[key_name] = param_value || default
    end
  end

  def locals
    @view_models.merge(@values).merge(@state).merge(view_model: self)
  end

  def render(controller_or_view, type=:top_level, view_model=nil, level=0)
    if view_model
      locals = view_model.locals
      view_name = view_model.view_name
    else
      locals = self.locals
      view_name = self.view_name
    end
    
    puts "#{indent(level)} render: for #{self}::#{type}, view_name = #{view_name}, locals = #{self.locals}"
    case type
    when :top_level
      controller_or_view.render view_name, locals: locals
    else
      controller_or_view.render partial: view_name, locals: locals
    end
  end

  def update(new_state)
    #puts "ViewModel#update: #{new_state}"
    key_name = new_state.keys.first
    comp_with_key_id = complete_id_with_key_name(key_name) 
    #puts "comp_with_key_id = #{comp_with_key_id}"
    controller.update(comp_with_key_id, new_state)
  end

  def indent(level)
    ("-" * level) + ":"
  end

  def compare_and_render(new_view_model, parent_view_model=nil, level=0)
    puts "#{indent(level)} Start VM=#{new_view_model}, parent=#{parent_view_model}"
    actions = Actions.new
    if !@view_models.empty?
      @view_models.each do |key, vm|
        puts "#{indent(level)} Key = #{key}"
        new_vm = new_view_model.view_models[key]
        puts "#{indent(level)} VM = #{vm}, NEW_VM = #{new_vm}"
        if vm.is_a?(Array)
          zipped_items = zip(vm, new_vm)
          puts "#{indent(level)} Array: old size=#{vm.size}, new size=#{new_vm.size}"

          zipped_items.each do |vm_item, new_vm_item|
            puts "#{indent(level)} vm_item = #{vm_item}, new_vm_item = #{new_vm_item}"
            if vm_item && new_vm_item
              actions.add(vm_item.compare_and_render(new_vm_item, new_view_model, level+2), indent(level))
            elsif vm_item
              actions.add(Action.delete(vm_item), indent(level))
            elsif new_vm_item
              actions.add(Action.insert(new_vm_item, new_view_model, render(@controller, :partial, new_vm_item, level)), indent(level))
            end
          end
        else
          actions = vm.compare_and_render(new_vm, new_view_model, level+2)
        end

        actions.process(indent(level))
      end
    else
      values_and_state = @values.merge(@state)
      new_values_and_state = new_view_model.values.merge(new_view_model.state)
      values_and_state.each do |key, value|
        new_value = new_values_and_state[key]
        puts "#{indent(level)} Key=#{key}, #{value.inspect} <?> #{new_value.inspect}"
        if value != new_value
          actions.add(Action.replace(self, new_view_model, render(@controller, :partial, new_view_model)), indent(level))
          break
        end
      end
    end
    puts "#{indent(level)} End Actions = #{actions}"
    return actions
  end

  def zip(old_array, new_array)
    if new_array.size > old_array.size
      old_array = old_array + ([nil] * (new_array.size - old_array.size))
    end
    old_array.zip(new_array)
  end

  def register_handlers
    each_view_model(@view_models) do |view_model|
      view_model.register_handlers if view_model.respond_to?(:register_handlers)
    end
  end

  def each_view_model(values)
    values.each do |key, value|
      if value.respond_to?(:each_value)
        value.each_value {|v| yield v}
      elsif value.respond_to?(:each)
        value.each {|v| yield v}
      else
        yield value
      end
    end
  end

  def method_missing(sym, *args)
    if @view_models.has_key?(sym)
      @view_models[sym]
    elsif @values.has_key?(sym)
      @values[sym]
    elsif @state.has_key?(sym)
      @state[sym]
    elsif m = /^(.*)=$/.match(sym.to_s)
      sym = m[1].to_sym
      value = args.first
      if @view_models.has_key?(sym)
        @view_models[sym] = value
      elsif @values.has_key?(sym)
        @values[sym] = value
      else
        @state[sym] = value
      end
    else
      super
    end
  end

  def==(other)
    return false unless other.is_a?(self.class)

    @values == other.values && @state == other.state
  end

  def to_s
    "Class: #{self.class.to_s} " +
    "view_models: #{@view_models.map{|vm| vm.to_s}.join(', ')} " +
    "values = #{@values.inspect} " +
    "state = #{@state.inspect}"
  end
end
