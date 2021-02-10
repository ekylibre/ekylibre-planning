module Planning
  module Backend
    class ProductsController < ::Backend::ProductsController
      unroll :name, :number, :work_number, :identification_number, container: :name, partial: 'planning/backend/interventions/available_time_or_quantity', custom_sort: :sort_by_time_use

      def sort_by_time_use(products)
        return products if products.count.zero?
        date = params["scope"]["actives"][0]["at"]
        array = []
        products.each do |product|
          time_in_use = product.time_use_in_date(date).to_f
          array.push([product.id, time_in_use])
        end
        array_values = array.map{ |e| e.inspect.gsub(/[\[\]]/, '[' => '(', ']' => ')')}.join(', ')
        products = Product.joins("JOIN (values #{array_values}) AS x (id, time) on products.id = x.id").order("x.time DESC")
        products
      end
    end
  end
end
