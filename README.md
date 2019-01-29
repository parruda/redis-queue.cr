# redis-queue.cr

Based on the Ruby version: [https://github.com/taganaka/redis-queue](https://github.com/taganaka/redis-queue)

Adds Redis::Queue class which can be used as Distributed-Queue based on Redis.
Redis is often used as a messaging server to implement processing of background jobs or other kinds of messaging tasks.
It implements Reliable-queue pattern decribed here: http://redis.io/commands/rpoplpush.

## Installation

1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  redis-queue:
    github: parruda/redis-queue.cr
```
2. Run `shards install`

## Usage

```crystal
require "redis-queue"
```

```crystal
redis = Redis.new
queue = Redis::Queue.new('q_test','bp_q_test',  :redis => redis)

# Adding some elements
queue.push "a"
queue.push "b" 

# Process messages
# By default, calling pop method is a blocking operation
# Your code will wait here for a new message

while message=queue.pop
  # Remove message from the backup queue if the message has been processed without errors
  queue.commit if YourTask.new(message).perform.succeed?
end

# Process messages using block
queue.process(force_commit: false) do |message|
  # queue.commit is called if last statement of the block returns true
  # or force_commit = true
  YourTask.new(message).perform.succeed?
end

# Process messages with timeout (starting from version 0.0.3)
# Wait for 15 seconds for new messages, then exit
queue.process(force_commit: false, timeout: 15) do |message|
  puts "'#{message}'" 
end

# Process messages in a non blocking-way
# A soon as the queue is empty, the block will exit
queue.process(blocking: false) do |message|
  puts "'#{message}'" 
end
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/redis-queue/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Paulo Arruda](https://github.com/your-github-user) - creator and maintainer
