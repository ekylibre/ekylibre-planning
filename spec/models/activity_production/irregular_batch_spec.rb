# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityProduction::IrregularBatch, type: :model do
  subject do
    build(:activity_production_irregular_batch)
  end

  it 'Have a valid factory' do
    expect(subject).to be_valid
  end

  describe 'Validate presence of estimated_sowing_date' do
    subject do
      build(:activity_production_irregular_batch, estimated_sowing_date: estimated_sowing_date)
    end

    let(:estimated_sowing_date) { nil }

    it 'Have an error message' do
      subject.valid?
      expect(subject.errors[:estimated_sowing_date]).to include("can't be blank")
    end
  end

  describe 'Validate presence of area' do
    subject do
      build(:activity_production_irregular_batch, area: area)
    end

    let(:area) { nil }

    it 'Have an error message' do
      subject.valid?
      expect(subject.errors[:area]).to include("can't be blank")
    end
  end

  describe 'Should have a batch' do
    subject do
      build(:activity_production_irregular_batch, activity_production_batch: activity_production_batch)
    end

    let(:activity_production_batch) { nil }

    it 'Have an error message' do
      subject.valid?
      expect(subject.errors[:activity_production_batch]).to include("can't be blank")
    end
  end

  describe 'sowing_date should be between activity_production_date' do
    subject do
      build(:activity_production_irregular_batch, estimated_sowing_date: estimated_sowing_date)
    end

    let(:estimated_sowing_date) { Time.now + 5.days }

    it 'Should have an error message' do
      subject.valid?
      expect(subject.errors[:estimated_sowing_date]).to include('Date should be after start date of the production')
    end

    describe 'Date after end of production' do
      let(:estimated_sowing_date) { Time.now + 5.years }

      it 'Should have an error message' do
        subject.valid?
        expect(subject.errors[:estimated_sowing_date]).to include('Date should be before end of production')
      end
    end
  end
end
