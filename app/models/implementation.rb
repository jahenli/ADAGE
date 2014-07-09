class Implementation < ActiveRecord::Base
  belongs_to :game
  attr_accessible :name, :game, :schema

  has_one :client

  after_create :create_client_credentials

  def config
    ConfigData.where("implementation_id" => self.id).first
  end


  protected

  def create_client_credentials
    client = Client.new(name: name, implementation: self)
    client.save
    raise client.inspect if client.new_record?
  end
end
