# frozen_string_literal: true

class DatasetPageAudit < ActiveRecord::Base

  # Model Relationships
  belongs_to :dataset
  belongs_to :user

end
