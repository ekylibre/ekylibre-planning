# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityProduction::Batch, type: :model do
  subject do
    build(:activity_production_batch)
  end

  it 'Have a valid factory' do
    expect(subject).to be_valid
  end

  describe 'Validation when irregular_batch is false' do
    describe 'test of number nil' do
      subject do
        build(:activity_production_batch, number: number)
      end
      let(:number) { nil }

      it 'Have an error message if number is nil' do
        subject.valid?
        expect(subject.errors[:number]).to include("can't be blank")
      end
    end

    describe 'Number cant be negative' do
      subject do
        build(:activity_production_batch, number: number)
      end
      let(:number) { -19 }

      it 'Have an error message' do
        subject.valid?
        expect(subject.errors[:number]).to include('must be greater than 0')
      end
    end

    describe "Day interval can't be blank" do
      subject do
        build(:activity_production_batch, day_interval: day_interval)
      end
      let(:day_interval) { nil }
      it 'Have an error message if day_interval is nil' do
        subject.valid?
        expect(subject.errors[:day_interval]).to include("can't be blank")
      end
    end

    describe "Day interval can't be negative" do
      subject do
        build(:activity_production_batch, day_interval: day_interval)
      end
      let(:day_interval) { -20 }
      it 'Have an error message if day_interval is negative' do
        subject.valid?
        expect(subject.errors[:day_interval]).to include('must be greater than 0')
      end
    end
  end

  describe 'Validation when irregular_batch is true' do
    subject do
      build(:activity_production_batch,
            number: number,
            day_interval: day_interval,
            irregular_batch: irregular_batch)
    end
    let(:number) { nil }
    let(:day_interval) { nil }
    let(:irregular_batch) { true }
    it 'Is valid without number and day_interval' do
      expect(subject).to be_valid
    end

    describe 'Should have irregular_batches when true' do
      subject do
        batch = create(:activity_production_batch, irregular_batch: irregular_batch)
        batch.irregular_batches.build(
          estimated_sowing_date: Time.now + rand(1..40).days,
          area: rand(1..200)
        )
        batch
      end

      let(:irregular_batch) { true }

      it 'Have irregular_batches' do
        expect(subject.irregular_batches.any?).to be true
      end

      describe 'With irregular batch to false' do
        let(:irregular_batch) { false }

        it "Don't have irregular_batches" do
          subject.valid?
          expect(subject.irregular_batches.any?).to be false
        end
      end
    end
  end
end
