module Laziness
  module ExceptionNotifier
    ::ExceptionNotifier.sections << 'laziness'
  end
  
  module ActionController
    module Rescue
      def rescue_action_locally_with_laziness(exception)
        add_variables_to_assigns
        @template.instance_variable_set("@exception", exception)
        @template.instance_variable_set("@rescues_path", File.dirname(rescues_path("stub")))
        @template.send!(:assign_variables_from_controller)

        contents  = @template.render_file(template_path_for_local_rescue(exception), false)
        test      = Laziness.generate_test(request.method.to_s, params, session.instance_variable_get(:@data), cookies)
        @template.instance_variable_set("@contents", contents + test)

        response.content_type = Mime::HTML
        render_for_file(rescues_path("layout"), response_code_for_rescue(exception))
      end
    end
  end

  def self.generate_test(method, params, session, cookies)
    session    ||= {}
    cookies    ||= {}
    controller   = params.delete(:controller)
    action       = params.delete(:action)
    params       = params || {}
    flash        = session.delete(:flash) || {}
"
<h2 style='margin-top:30px;'>Laziness Test</h2>

<pre>
def test_#{method}_#{controller}_#{action}_should_not_raise_exception
  assert_nothing_raised do
    #{method} :#{action}, #{params.inspect}, #{session.inspect}, #{flash.inspect}, #{cookies.inspect}
  end
end
</pre>
"
  end

end