# frozen_string_literal: true

# Tracks the number of files downloaded per dataset and by user.
class DatasetFileAudit < ApplicationRecord
  # Relationships
  belongs_to :dataset
  belongs_to :user, optional: true

  # Scopes
  scope :all_members, -> { where.not(user_id: nil) }
  scope :regular_members, -> { joins(:user).merge(User.regular_members) }
  scope :aug_members, -> { joins(:user).merge(User.aug_members) }
  scope :core_members, -> { joins(:user).merge(User.core_members) }
  scope :aug_or_core_members, -> { joins(:user).merge(User.aug_or_core_members) }
  scope :public_downloads, -> { where(user_id: nil) }

  # Methods

  def self.year(year)
    where "extract(year from dataset_file_audits.created_at) = ?", year
  end
end
