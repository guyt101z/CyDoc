class Doctor < ActiveRecord::Base
  belongs_to :praxis, :class_name => 'Vcards::Vcard', :foreign_key => 'praxis_vcard'
  belongs_to :private, :class_name => 'Vcards::Vcard', :foreign_key => 'private_vcard'

  belongs_to :billing_doctor, :class_name => 'Doctor'

  has_many :mailings
  has_and_belongs_to_many :offices

  # Proxy accessors
  def name
    praxis.full_name || ""
  end

  def colleagues
    offices.map{|o| o.doctors}.flatten
  end

  def password=(value)
    write_attribute(:password, Digest::SHA256.hexdigest(value))
  end

  # Convenience function
  def compact_address
    praxis.compact_address
  end

  def compact_contact
    praxis.compact_contact
  end

  # ZSR sanitation
  def zsr=(value)
    write_attribute(:zsr, value.delete(' .'))
  end
end
