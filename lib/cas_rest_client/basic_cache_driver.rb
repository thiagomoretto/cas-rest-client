module CasRestClientCacheManager

  class BasicCacheDriver
    @@ticket_cache = {}
    @@ticket_cache_semaphore = Mutex.new
    @@ticket_usage_count = {}
    @@ticket_usage_count_semaphore = Mutex.new
    
    def self.get(key)
      @@ticket_cache[key]
    end
    
    def self.set(key, value)
      @@ticket_cache_semaphore.synchronize do
        @@ticket_cache[key] = value
      end
    end
    
    def self.purge(key)
      @@ticket_cache_semaphore.synchronize do
        @@ticket_cache[key] = nil
      end
    end
    
    def self.get_count(key)
      @@ticket_usage_count[key] || 0
    end

    def self.increment_hit(key)
      @@ticket_usage_count_semaphore.synchronize do
        @@ticket_usage_count[key] = 0 if @@ticket_usage_count[key].nil?
        @@ticket_usage_count[key] = 1 + @@ticket_usage_count[key]
      end
    end

    def self.zeroify_usage_counter(key)
      @@ticket_usage_count_semaphore.synchronize do
        @@ticket_usage_count[key] = nil
      end
    end
    
    def self.reset!
      @@ticket_cache = {}
      @@ticket_usage_count = {}
    end
  end
  
end
  