module Planning
  module Forms
    module BaseHelper

      def planning_form_for(object, *args, &block)
        options = args.extract_options!

        simple_form_for([:planning, object], *(args << options.merge(builder: ::Backend::FormBuilder)), &block)
      end
    end
  end
end
