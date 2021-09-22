# frozen_string_literal: true

module Planning
  class ExtNavigation
    def self.add_navigation_xml_to_existing_tree
      ext_navigation = ExtNavigation.new
      ext_navigation.build_new_tree
    end

    attr_reader :planning_navigation_tree, :new_navigation_tree,
                :planning_xml_navigation_childrens

    def initialize
      @planning_navigation_tree = Ekylibre::Navigation::Tree
                                  .load_file(planning_navigation_file_path,
                                             :navigation,
                                             %i[part group item])

      @planning_xml_navigation_childrens = init_planning_navigation_childrens
    end

    def build_new_tree
      @planning_navigation_tree.children.each do |child|
        after_part = after_part_value(child)

        Ekylibre::Navigation.tree.insert_part_after(child, after_part)
      end

      @new_navigation_tree = Ekylibre::Navigation.tree
      @new_navigation_tree
    end

    private

    def init_planning_navigation_childrens
      parts = navigation_to_xml.xpath('//part')

      parts.map do |part|
        { after_part: part.attribute('after-part').value, node: part }
      end
    end

    def after_part_value(planning_navigation_child)
      selected_child = @planning_xml_navigation_childrens.select do |planning_xml_navigation_child|
        planning_xml_navigation_child[:node].attribute('name').value == planning_navigation_child.name.to_s
      end

      selected_child.first[:after_part]
    end

    def navigation_to_xml
      navigation_xml_file = File.open(planning_navigation_file_path)

      xml = Nokogiri::XML(navigation_xml_file) do |config|
        config.strict.nonet.noblanks
      end

      navigation_xml_file.close

      xml
    end

    def planning_navigation_file_path
      Planning.root.join('config', 'navigation.xml')
    end
  end
end
