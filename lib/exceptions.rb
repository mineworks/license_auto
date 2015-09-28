class MyError < StandardError

  def initialize(message)
    @message = message
  end
end