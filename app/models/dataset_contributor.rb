# frozen_string_literal: true

class DatasetContributor < ActiveRecord::Base

  # Model Relationships
  belongs_to :dataset
  belongs_to :user

end
