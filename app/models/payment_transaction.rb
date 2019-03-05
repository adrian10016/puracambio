class PaymentTransaction < ActiveRecord::Base
  extend Enumerize

  include AASM
  include AASM::Locking
  include Currencible

  STATE = [:unconfirm, :confirming, :confirmed]
  enumerize :aasm_state, in: STATE, scope: true

  validates_presence_of :txid

  has_one :deposit
  belongs_to :payment_address, foreign_key: 'address', primary_key: 'address'
  has_one :account, through: :payment_address
  has_one :member, through: :account

  after_update :sync_update

  aasm :whiny_transitions => false do
    state :unconfirm, initial: true
    state :confirming, after_commit: :deposit_accept
    state :confirmed, after_commit: :deposit_accept

    event :check do |e|
      before :refresh_confirmations

      transitions :from => [:unconfirm, :confirming], :to => :confirming, :guard => :min_confirm?
      transitions :from => [:unconfirm, :confirming, :confirmed], :to => :confirmed, :guard => :max_confirm?
    end
  end

  def min_confirm?
    deposit.min_confirm?(confirmations)
  end

  def max_confirm?
    deposit.max_confirm?(confirmations)
  end

  def refresh_confirmations
    Rails.logger.info {"Confirmations: #{self.currency}"}
    if self.currency == 'tlcp'
      raw = CoinRPC['tlcp'].eth_getTransactionByHash(txid)
      self.confirmations = CoinRPC['tlcp'].eth_blockNumber.to_i(16) - raw[:blockNumber].to_i(16)
      Rails.logger.info {"Confirmations: #{self.confirmations}"}
    end
    self.save!
  end

  def deposit_accept
    if deposit.may_accept?
      deposit.accept! 
    end
  end

	def force_confirmed!
			channel = deposit.channel()
			self.confirmations = channel.max_confirm
      deposit.accept! 
	end

  private

  def sync_update
    if self.confirmations_changed?
      ::Pusher["private-#{deposit.member.sn}"].trigger_async('deposits', { type: 'update', id: self.deposit.id, attributes: {confirmations: self.confirmations}})
    end
  end

end
