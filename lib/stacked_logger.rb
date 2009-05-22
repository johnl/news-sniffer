require 'logger'

# StackedLogger acts like a normal Logger, except that all messages
# sent to it are also duplicated to another logger.
class StackedLogger < Logger

  def initialize(original_logger, target)
    @real_logger = original_logger
    super(target)
  end

  def add(*args)
    @real_logger.add(*args)
    super(*args)
  end

end
