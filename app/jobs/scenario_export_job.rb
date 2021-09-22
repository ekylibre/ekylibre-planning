# frozen_string_literal: true

class ScenarioExportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  protected

  def perform(scenario, format, user)
    filename = "#{I18n.t('labels.load_plans').parameterize}_#{scenario.name}"
    data = if format == 'ods'
             to_ods(scenario).bytes
           else
             %w[csv xcsv].include?(format)
             CSV.generate(headers: true, col_sep: ';', encoding: 'UTF-8') do |csv|
               to_csv(scenario, csv)
             end
           end
    file = StringIO.new(data)
    document = Document.create!(key: "#{Time.now.to_i}-#{filename.parameterize}",
                                name: filename,
                                file: file,
                                file_file_name: "#{filename.parameterize}.#{format}")
    user.notifications.create!(success_notification_params(document.id))
  rescue StandardError => e
    Rails.logger.error e
    Rails.logger.error e.backtrace.join("\n")
    ExceptionNotifier.notify_exception(e, data: { message: e })
    user.notifications.create!(error_notification_params(e.message))
  end

  private

  def error_notification_params(error)
    {
      message: 'error_during_file_generation',
      level: :error,
      interpolations: {
        error_message: error
      }
    }
  end

  def success_notification_params(document_id)
    {
      message: 'file_generated',
      level: :success,
      target_type: 'Document',
      target_url: backend_document_path(document_id),
      interpolations: {}
    }
  end

  def to_csv(scenario, csv)
    csv << [
      :campaign.tl,
      :activity_singular.tl,
      :date.tl,
      :intervention_type.tl,
      :human_area_in_hectare.tl,
      :ressource.tl,
      :intervention_parameter.tl,
      :type_of_resource.tl,
      :quantity_necessary.tl,
      :unit.tl,
      :available_quantity.tl,
      :unit.tl
    ]
    scenario.generate_daily_charges.each do |charge|
      csv << [
        charge.product_parameter.intervention_template.campaign.name,
        charge.activity.name,
        charge.reference_date.strftime('%d/%m/%Y'),
        charge.product_parameter.intervention_template.procedure.human_name,
        charge.area.to_f.round(2).to_s.gsub('.', ','),
        charge.product_general_type.tl,
        charge.product_parameter.procedure['name'],
        (charge.product_parameter.product_nature&.name || charge.product_parameter.product_nature_variant&.name),
        charge.quantity_with_unit.to_s.scan(/\d*[,.\W]\d+/).join.gsub('.', ','),
        charge.quantity_with_unit.to_s.split(/\d*[,.\W]\d+/).last,
        charge.available_quantity.to_s.scan(/\d*[,.\W]\d+/).join.gsub('.', ','),
        charge.available_quantity.to_s.split(/\d*[,.\W]\d+/).last
      ]
    end
  end

  def to_ods(scenario)
    output = RODF::Spreadsheet.new
    output.instance_eval do
      office_style :important, family: :cell do
        property :text, 'font-weight': :bold, 'font-size': '11px'
      end
      office_style :bold, family: :cell do
        property :text, 'font-weight': :bold
      end

      table scenario.name do
        row do
          cell :campaign.tl, style: :important
          cell :activity_singular.tl, style: :important
          cell :date.tl, style: :important
          cell :intervention_type.tl, style: :important
          cell :human_area_in_hectare.tl, style: :important
          cell :ressource.tl, style: :important
          cell :intervention_parameter.tl, style: :important
          cell :type_of_resource.tl, style: :important
          cell :quantity_necessary.tl, style: :important
          cell :unit.tl, style: :important
          cell :available_quantity.tl, style: :important
          cell :unit.tl, style: :important
        end
        scenario.generate_daily_charges.each do |charge|
          row do
            cell charge.product_parameter.intervention_template.campaign.name
            cell charge.activity.name
            cell charge.reference_date.strftime('%d/%m/%Y')
            cell charge.product_parameter.intervention_template.procedure.human_name
            cell charge.area.to_f.round(2)
            cell charge.product_general_type.tl
            cell charge.product_parameter.procedure['name']
            cell charge.product_parameter.product_nature&.name || charge.product_parameter.product_nature_variant&.name
            cell charge.quantity_with_unit.to_s.scan(/\d*[,.\W]\d+/).join.gsub('.', ',')
            cell charge.quantity_with_unit.to_s.split(/\d*[,.\W]\d+/).last
            cell charge.available_quantity.to_s.scan(/\d*[,.\W]\d+/).join.gsub('.', ',')
            cell charge.available_quantity.to_s.split(/\d*[,.\W]\d+/).last
          end
        end
      end
    end
    output
  end
end
