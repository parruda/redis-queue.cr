module RedisQueue
  VERSION = "0.1.1"
  @last_message : String?
  @redis : ::Redis::PooledClient
  
  property "queue_name"
  property "process_queue_name"
  
  def initialize(queue_name : String, process_queue_name : String, @redis : Redis::PooledClient, @timeout = 0)
    raise "First argument must be a non empty string"  if !queue_name.is_a?(String) || queue_name.empty?
    raise "Second argument must be a non empty string" if !process_queue_name.is_a?(String) || process_queue_name.empty?
    raise "Queue and Process queue have the same name" if process_queue_name == queue_name

    @queue_name = queue_name
    @process_queue_name = process_queue_name
    @last_message = nil
  end

  def length
    @redis.llen @queue_name
  end

  def clear(clear_process_queue = false)
    @redis.del @queue_name
    @redis.del @process_queue_name if clear_process_queue
  end

  def empty?
    length <= 0
  end

  def push(obj)
    @redis.lpush(@queue_name, obj)
  end

  def pop(blocking : Bool = true, timeout : Int32? = nil)
    if blocking
      @last_message = @redis.brpoplpush(@queue_name, @process_queue_name, timeout || @timeout)
    else
      @last_message = @redis.rpoplpush(@queue_name, @process_queue_name)
    end
  end

  def commit
    @redis.lrem(@process_queue_name, 0, @last_message)
  end

  def process(blocking : Bool = true, force_commit : Bool = false, timeout : Int32? = nil, &block)
    loop do
      pop(timeout: timeout, blocking: blocking)
      next unless @last_message
      commit if yield(@last_message.not_nil!) || force_commit
      break if !blocking && empty?
    end
  end

  def refill
    while (message = @redis.lpop(@process_queue_name))
      @redis.rpush(@queue_name, message)
    end
    true
  end
end

class Redis
  class Queue
    include RedisQueue
  end
end
