class Transaction

  attr_accessor :address
  attr_accessor :account
  attr_accessor :to
  attr_accessor :from
  attr_accessor :amount
  attr_accessor :fee
  attr_accessor :block_index
  attr_accessor :tx_id
  attr_accessor :block_hash
  attr_accessor :category
  attr_accessor :time
  attr_accessor :confirmations
  attr_accessor :message
  attr_accessor :comment
  attr_accessor :payment_to_self

  def initialize(t_hash = nil)
    @payment_to_self = false
    unless t_hash.nil?
      @account = t_hash['account']
      @address = t_hash['address']
      @amount = t_hash['amount']
      @block_index = t_hash['blockindex']
      @block_hash = t_hash['blockhash']
      @category = t_hash['category']
      @comment = t_hash['comment']
      @confirmations = t_hash['confirmations']
      @message = t_hash['message']
      @fee = t_hash.has_key?('fee') ? t_hash['fee'] : 0
      @from = t_hash['from']
      @time = Time.at(t_hash['time'])
      @to = t_hash['to']
      @tx_id = t_hash['txid']
    end

  end

end