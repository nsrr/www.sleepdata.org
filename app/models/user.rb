class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable and :omniauthable
  devise :database_authenticatable, :registerable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable

  # Concerns
  include Contourable, Deletable, TokenAuthenticatable

  # Callbacks
  before_save :ensure_authentication_token
  after_create :notify_system_admins

  # Named Scopes
  scope :aug_members, -> { current.where( aug_member: true ) }
  scope :core_members, -> { current.where( core_member: true ) }
  scope :system_admins, -> { current.where( system_admin: true ) }
  scope :search, lambda { |arg| where( 'LOWER(first_name) LIKE ? or LOWER(last_name) LIKE ? or LOWER(email) LIKE ?', arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%'), arg.to_s.downcase.gsub(/^| |$/, '%') ) }
  scope :with_name, lambda { |arg| where("(users.first_name || ' ' || users.last_name) IN (?)", arg) }

  # Model Validation
  validates_presence_of :first_name, :last_name

  # Model Relationships
  has_many :agreements, -> { where deleted: false }
  has_many :comments, -> { where deleted: false }
  has_many :datasets, -> { where deleted: false }
  has_many :dataset_file_audits
  has_many :tools
  has_many :topics, -> { where deleted: false }
  has_many :subscriptions

  # User Methods

  def all_topics
    if self.system_admin?
      Topic.current
    else
      self.topics
    end
  end

  def all_comments
    if self.system_admin?
      Comment.current
    else
      self.comments
    end
  end

  def all_agreements
    if self.system_admin?
      Agreement.current
    else
      self.agreements
    end
  end

  # If a user has auto-subscribe enabled, then the user receives notifications on topics they have not explicity squelched.
  # If a user has auto-subscribe disabled, then the user receives notifications on topics to which they have explicitely subscribed.
  def subscribed_topics
    @subscribed_topics ||= begin
      if self.auto_subscribe?
        Topic.current.not_banned.where.not( id: self.subscriptions.where( subscribed: false ).pluck( :topic_id ) )
      else
        Topic.current.not_banned.where( id: self.subscriptions.where( subscribed: true ).pluck( :topic_id ) )
      end
    end
  end

  # All comments created in the last day, or over the weekend if it is Monday
  # Ex: On Monday, returns tasks created since Friday morning (Time.now - 3.day)
  # Ex: On Tuesday, returns tasks created since Monday morning (Time.now - 1.day)
  def digest_comments
    Comment.digest_visible.where( topic_id: self.subscribed_topics.pluck(:id) ).where("created_at > ?", (Time.now.monday? ? Time.now.midnight - 3.day : Time.now.midnight - 1.day))
  end

  def all_datasets
    Dataset.current.with_editor( self.id )
  end

  def all_viewable_datasets
    Dataset.current.with_viewer( self.id )
  end

  def all_tools
    Tool.current.with_editor( self.id )
  end

  def all_viewable_tools
    Tool.current.with_viewer( self.id )
  end

  def avatar_url(size = 80, default = 'mm')
    gravatar_id = Digest::MD5.hexdigest(self.email.to_s.downcase)
    "//gravatar.com/avatar/#{gravatar_id}.png?&s=#{size}&r=pg&d=#{default}"
  end

  def can_post_links?
    aug_member? or core_member?
  end

  def topics_created_in_last_day
    self.topics.where( "created_at >= ?", Date.today - 1.day )
  end

  def max_topics
    if aug_member? or core_member?
      10
    else
      2
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def reverse_name
    "#{last_name}, #{first_name}"
  end

  def id_and_auth_token
    "#{self.id}-#{self.authentication_token}"
  end

  # Overriding Devise built-in active_for_authentication? method
  def active_for_authentication?
    super and not self.deleted?
  end

  def destroy
    super
    update_column :updated_at, Time.now
  end

  def apply_omniauth(omniauth)
    unless omniauth['info'].blank?
      self.first_name = omniauth['info']['first_name'] if first_name.blank?
      self.last_name = omniauth['info']['last_name'] if last_name.blank?
    end
    super
  end

  private

  def notify_system_admins
    User.system_admins.each do |system_admin|
      UserMailer.notify_system_admin(system_admin, self).deliver if Rails.env.production?
    end
  end

end
