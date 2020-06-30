class Organization < ApplicationRecord
  SUPPORTED_LANGUAGES = {
    en: 'English',
    km: 'Khmer',
    my: 'Burmese'
  }.freeze

  mount_uploader :logo, ImageUploader

  before_save :clean_supported_languages, if: :supported_languages?

  validates :supported_languages, presence: true
  validates :logo, presence: true
  validates :full_name, :short_name, presence: true
  validates :short_name, uniqueness: { case_sensitive: false }, format: { with: %r{\A[a-z](?:[a-z0-9-]*[a-z0-9])?\z}i }, length: { in: 1..63 }

  scope :demo, -> { where(demo: true) }
  scope :non_demo, -> { where.not(demo: true) }

  scope :km, -> { where("array_to_string(supported_languages, ',') LIKE (?)", "%km%") }
  scope :en, -> { where("array_to_string(supported_languages, ',') LIKE (?)", "%en%") }
  scope :my, -> { where("array_to_string(supported_languages, ',') LIKE (?)", "%my%") }

  class << self
    def current
      find_by(short_name: Apartment::Tenant.current)
    end

    def switch_to(tenant_name)
      Apartment::Tenant.switch!(tenant_name)
    end

    def update_client_data
      find_each do |organization|
        Apartment::Tenant.switch(organization.short_name) do
          organization.update_columns(
            clients_count: Client.count,
            active_client: Client.active_status.count,
            accepted_client: Client.accepted_status.count
          )
        end
      end
    end
  end

  def display_supported_languages
    supported_languages.map{ |lang| SUPPORTED_LANGUAGES[lang.to_sym] }.to_sentence
  end

  def demo_status
    'YES' if demo?
  end

  def save_and_load_generic_data
    return false if invalid?

    response = HTTParty.post("http://localhost:3000/api/v1/organizations", headers: { Authorization: "Token token=#{current_admin_user&.token}" })
  end

  def clean_supported_languages
    self.supported_languages = supported_languages.select(&:present?)
  end
end
