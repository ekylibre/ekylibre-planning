# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_180_405_125_117) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'activities', force: :cascade do |t|
    t.string   'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'activity_production_batches', force: :cascade do |t|
    t.integer  'number'
    t.integer  'day_interval'
    t.boolean  'irregular_batch'
    t.integer  'activity_production_id'
    t.datetime 'created_at',             null: false
    t.datetime 'updated_at',             null: false
  end

  add_index 'activity_production_batches', ['activity_production_id'], name: 'activity_production_batch_id',
                                                                       using: :btree

  create_table 'activity_production_irregular_batches', force: :cascade do |t|
    t.integer  'activity_production_batch_id'
    t.date     'estimated_sowing_date'
    t.decimal  'area'
    t.datetime 'created_at',                   null: false
    t.datetime 'updated_at',                   null: false
  end

  add_index 'activity_production_irregular_batches', ['activity_production_batch_id'],
            name: 'activity_production_irregular_batch_id', using: :btree

  create_table 'activity_productions', force: :cascade do |t|
    t.string   'name'
    t.datetime 'created_at',             null: false
    t.datetime 'updated_at',             null: false
    t.integer  'technical_itinerary_id'
    t.date     'predicated_sowing_date'
    t.boolean  'batch_planting'
    t.integer  'number_of_batch'
    t.integer  'sowing_interval'
    t.date     'started_on'
    t.date     'stopped_on'
  end

  add_index 'activity_productions', ['technical_itinerary_id'],
            name: 'index_activity_productions_on_technical_itinerary_id', using: :btree

  create_table 'campaigns', force: :cascade do |t|
    t.string   'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'daily_charges', force: :cascade do |t|
    t.date     'reference_date'
    t.string   'product_type'
    t.string   'product_general_type'
    t.decimal  'quantity'
    t.decimal  'area'
    t.integer  'intervention_template_product_parameter_id'
    t.integer  'activity_production_id'
    t.datetime 'created_at',                                 null: false
    t.datetime 'updated_at',                                 null: false
  end

  add_index 'daily_charges', ['activity_production_id'], name: 'index_daily_charges_on_activity_production_id',
                                                         using: :btree
  add_index 'daily_charges', ['intervention_template_product_parameter_id'],
            name: 'intervention_template_product_parameter_id', using: :btree

  create_table 'intervention_proposals', force: :cascade do |t|
    t.integer  'technical_itinerary_intervention_template_id'
    t.date     'estimated_date'
    t.decimal  'area'
    t.integer  'activity_production_id'
    t.datetime 'created_at',                                   null: false
    t.datetime 'updated_at',                                   null: false
    t.integer  'number'
  end

  add_index 'intervention_proposals', ['activity_production_id'],
            name: 'index_intervention_proposals_on_activity_production_id', using: :btree
  add_index 'intervention_proposals', ['technical_itinerary_intervention_template_id'],
            name: 'technical_itinerary_intervention_template_id', using: :btree

  create_table 'intervention_template_activities', force: :cascade do |t|
    t.integer  'intervention_template_id'
    t.integer  'activity_id'
    t.datetime 'created_at',               null: false
    t.datetime 'updated_at',               null: false
  end

  add_index 'intervention_template_activities', ['activity_id'],
            name: 'index_intervention_template_activities_on_activity_id', using: :btree
  add_index 'intervention_template_activities', ['intervention_template_id'],
            name: 'intervention_template_activity_id', using: :btree

  create_table 'intervention_template_product_parameters', force: :cascade do |t|
    t.integer  'intervention_template_id'
    t.integer  'product_nature_id'
    t.integer  'product_nature_variant_id'
    t.integer  'activity_id'
    t.decimal  'quantity'
    t.string   'unit'
    t.string   'type'
    t.jsonb    'procedure'
    t.datetime 'created_at',                null: false
    t.datetime 'updated_at',                null: false
  end

  add_index 'intervention_template_product_parameters', ['activity_id'],
            name: 'index_intervention_template_product_parameters_on_activity_id', using: :btree
  add_index 'intervention_template_product_parameters', ['intervention_template_id'],
            name: 'intervention_template_id', using: :btree
  add_index 'intervention_template_product_parameters', ['product_nature_id'], name: 'product_nature_id', using: :btree
  add_index 'intervention_template_product_parameters', ['product_nature_variant_id'],
            name: 'product_nature_variant_id', using: :btree

  create_table 'intervention_templates', force: :cascade do |t|
    t.string   'name'
    t.boolean  'active', default: true
    t.string   'description'
    t.string   'procedure_name'
    t.integer  'campaign_id'
    t.integer  'preparation_time_hours'
    t.integer  'preparation_time_minutes'
    t.decimal  'workflow'
    t.datetime 'created_at',                              null: false
    t.datetime 'updated_at',                              null: false
    t.integer  'creator_id'
    t.integer  'updater_id'
  end

  add_index 'intervention_templates', ['campaign_id'], name: 'index_intervention_templates_on_campaign_id',
                                                       using: :btree

  create_table 'interventions', force: :cascade do |t|
    t.string   'name'
    t.datetime 'created_at',               null: false
    t.datetime 'updated_at',               null: false
    t.integer  'intervention_proposal_id'
  end

  add_index 'interventions', ['intervention_proposal_id'], name: 'index_interventions_on_intervention_proposal_id',
                                                           using: :btree

  create_table 'product_nature_variants', force: :cascade do |t|
    t.string   'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'product_natures', force: :cascade do |t|
    t.string   'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'technical_itineraries', force: :cascade do |t|
    t.string   'name'
    t.integer  'campaign_id'
    t.integer  'activity_id'
    t.string   'description'
    t.datetime 'created_at',  null: false
    t.datetime 'updated_at',  null: false
    t.integer  'creator_id'
    t.integer  'updater_id'
  end

  add_index 'technical_itineraries', ['activity_id'], name: 'index_technical_itineraries_on_activity_id', using: :btree
  add_index 'technical_itineraries', ['campaign_id'], name: 'index_technical_itineraries_on_campaign_id', using: :btree

  create_table 'technical_itinerary_intervention_templates', force: :cascade do |t|
    t.integer  'technical_itinerary_id'
    t.integer  'intervention_template_id'
    t.integer  'position'
    t.integer  'day_between_intervention'
    t.integer  'duration'
    t.datetime 'created_at',                               null: false
    t.datetime 'updated_at',                               null: false
    t.boolean  'dont_divide_duration', default: false
    t.string   'reference_hash'
    t.string   'parent_hash'
  end

  add_index 'technical_itinerary_intervention_templates', ['intervention_template_id'], name: 'itinerary_template_id',
                                                                                        using: :btree
  add_index 'technical_itinerary_intervention_templates', ['technical_itinerary_id'], name: 'template_itinerary_id',
                                                                                      using: :btree

  add_foreign_key 'activity_production_batches', 'activity_productions'
  add_foreign_key 'activity_production_irregular_batches', 'activity_production_batches'
  add_foreign_key 'activity_productions', 'technical_itineraries'
  add_foreign_key 'daily_charges', 'activity_productions'
  add_foreign_key 'daily_charges', 'intervention_template_product_parameters'
  add_foreign_key 'intervention_proposals', 'activity_productions'
  add_foreign_key 'intervention_proposals', 'technical_itinerary_intervention_templates'
  add_foreign_key 'intervention_template_activities', 'activities'
  add_foreign_key 'intervention_template_activities', 'intervention_templates'
  add_foreign_key 'intervention_template_product_parameters', 'activities'
  add_foreign_key 'intervention_template_product_parameters', 'intervention_templates'
  add_foreign_key 'intervention_template_product_parameters', 'product_nature_variants'
  add_foreign_key 'intervention_template_product_parameters', 'product_natures'
  add_foreign_key 'intervention_templates', 'campaigns'
  add_foreign_key 'interventions', 'intervention_proposals'
  add_foreign_key 'technical_itineraries', 'activities'
  add_foreign_key 'technical_itineraries', 'campaigns'
  add_foreign_key 'technical_itinerary_intervention_templates', 'intervention_templates'
  add_foreign_key 'technical_itinerary_intervention_templates', 'technical_itineraries'
end
