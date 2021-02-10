module Backend::LoadPlansHelper
  def column_color(type)
    type == :doers ? '#AED581' : '#64B5F6'
  end

  def human_date_labels
    @labels.map{ |l| l.strftime('%d/%m') }
  end

  def list_of_charge(type)
    daily_charges = @daily_charges.select { |d| d.product_general_type == type.to_s.singularize }
    data = []
    @labels.each do |label|
      if params[:week].present?
        data << daily_charges.select { |d| d.reference_date.between?(label.beginning_of_day, label.end_of_day) }.sum(&:quantity).to_i
      else
        data << daily_charges.select { |d| d.reference_date.between?(label, label.end_of_week) }.sum(&:quantity).to_i
      end
    end
    data
  end
end
