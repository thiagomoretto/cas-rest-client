require 'base64'

module CasRestClientCacheManager
  
  def self.use_driver=(driver)
    CasRestClientCache.use_driver(driver)
  end
  
  class DriverFacade
    @@debug  = false
    @@driver = nil
  
    def self.get_tgt_for(uri, username, password, cache_opts={})
      raise "Not implemented yet"
    end
  
    def self.save_tgt_for(uri, username, password, tgt, cache_opts={})
      raise "Not implemented yet"
    end
  
    def self.get_st_for(uri, username, password, cache_opts={})
      debug("Trying to get cached ticket for #{key_for(uri, username, password)}")
      key    = key_for(uri, username, password)
      holder = current_driver.get(key)
      return nil if holder.nil?

      st, st_created_at = holder[:service_ticket], holder[:created_at]
      if (now_uts - st_created_at) >= cache_opts[:st_expiration_time] or is_usage_exceeded_for?(st, cache_opts) 
        current_driver.purge(key)
        current_driver.zeroify_usage_counter(st)
        debug("Ticket expired! SORRY! you want to generate a new one")
        nil
      else
        current_driver.increment_hit(st)
        st
      end
    end
  
    def self.save_st_for(uri, username, password, service_ticket, cache_opts={})
      debug("Writing ticket to cache for #{key_for(uri, username, password)} -> #{service_ticket}")
      current_driver.set(key_for(uri, username, password), { :service_ticket => service_ticket, :created_at => now_uts })
      current_driver.increment_hit(service_ticket) unless cache_opts[:max_usage_count] == nil
    end
  
    def self.is_usage_exceeded_for?(service_ticket, cache_opts)
      cache_opts[:max_usage_count] != nil and current_driver.get_count(service_ticket) >= cache_opts[:max_usage_count]
    end
  
    def self.current_driver
      @@driver ||= CasRestClientCacheManager::BasicCacheDriver
    end
  
    def self.use_driver(driver)
      @@driver = driver
    end
  
    def self.reset!
      current_driver.reset!
    end
  
  private
    def self.debug(message)
      puts message if @@debug
    end

    def self.now_uts
      Time.now.to_i
    end

    def self.key_for(uri, username, password)
      Base64.encode64(OpenSSL::HMAC.digest('sha1', password, "#{username}-#{uri}"))
    end
  end
end