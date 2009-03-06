require 'memcache'

require 'benchmark'

cache = MemCache.new(MemCache::Server.new('127.0.0.1'))

class MemCache
  
  def append( key, val, exptime=0 )
    raise MemCacheError, "no active servers" unless self.active?
    raise MemCacheError, "readonly cache" if self.readonly?
    rval = nil

    @mutex.synchronize( Sync::EX ) {
      rval = self.store( :append, key, val, exptime )
    }

    rval
  end

  def delete_match( key, time=nil )
    raise MemCacheError, "no active servers" unless self.active?
    raise MemCacheError, "readonly cache" if self.readonly?
    svr = nil

    res = @mutex.synchronize( Sync::EX ) {
      svr = self.get_server( key )
      cachekey = self.make_cache_key( key )

      self.add_stat( :delete_match ) do
        cmd = "delete_match %s%s" % [ cachekey, time ? " #{time.to_i}" : "" ]
        self.send( svr => cmd )
      end
    }

		res && res[svr] && res[svr].blocks[0].cmd == "DELETED\r\n"
  end
  
end


describe 'memcache server' do

  it "should add" do
    cache.get('added_key').should == nil
    cache.add('added_key','zig')
    cache.get('added_key').should == 'zig'
    cache.add('added_key','ziglar')
    cache.get('added_key').should == 'zig'
  end

  it "should put & get" do
    100.times do |i|
      cache.set("/blog/show/#{i}","this is a big ol' blog post!!! #{i}")
    end
    
    100.times do |i|
      cache.get("/blog/show/#{i}").should == "this is a big ol' blog post!!! #{i}"
    end
  end
  
  it "should delete" do
    cache.set("key-set-123","you should never see me")
    cache.get("key-set-123").should == "you should never see me"
    cache.delete("key-set-123")
    cache.get("key-set-123").should == nil
  end
  
  it "should delete (with expiry)" do
    cache.set('delete-with-expiry', 'hillbillies')
    cache.get('delete-with-expiry').should == 'hillbillies'
    cache.delete('delete-with-expiry', 3)
    cache.get('delete-with-expiry').should == nil
    cache.replace('delete-with-expiry', 'more hillbillies')
    cache.get('delete-with-expiry').should == nil
    sleep(5)
    cache.get('delete-with-expiry').should == nil
    cache.set('delete-with-expiry', 'more hillbillies')
    cache.get('delete-with-expiry').should == 'more hillbillies'
  end
  
  it "should delete (with expiry) and set again" do
    cache.set('delete-with-expiry', 'hillbillies')
    cache.get('delete-with-expiry').should == 'hillbillies'
    cache.delete('delete-with-expiry', 3)
    cache.get('delete-with-expiry').should == nil
    cache.set('delete-with-expiry', 'more hillbillies')
    cache.get('delete-with-expiry').should == 'more hillbillies'
    sleep(5)
    cache.get('delete-with-expiry').should == 'more hillbillies'
  end
  

  it "should delete_match" do
    100.times do
      cache.set("asd/qwe/zxc/10","you should never see me")
      cache.set("asd/qwe/zxc/20","you should never see me")
      cache.set("asd/qwe/zxc/30","you should never see me")
      cache.set("asd/qwe/zxc/40","you should never see me")
      cache.set("asd/qwe/zxc/11","you should never see me")
      cache.set("asd/qwe/zxc/21","you should never see me")
      cache.set("asd/qwe/zxc/31","you should never see me")
      cache.set("asd/qwe/zxc/41","you should never see me")
      cache.set("asd/qwe/zxc/12","you should never see me")
      cache.set("asd/qwe/zxc/22","you should never see me")
      cache.set("asd/qwe/zxc/32","you should never see me")
      cache.set("asd/qwe/zxc/42","you should never see me")
      cache.set("asd/qwe/zxc/101","you should never see me")
      cache.set("asd/qwe/zxc/201","you should never see me")
      cache.set("asd/qwe/zxc/301","you should never see me")
      cache.set("asd/qwe/zxc/401","you should never see me")
      cache.set("asd/qwe/zxc/111","you should never see me")
      cache.set("asd/qwe/zxc/211","you should never see me")
      cache.set("asd/qwe/zxc/311","you should never see me")
      cache.set("asd/qwe/zxc/411","you should never see me")
      cache.set("asd/qwe/zxc/121","you should never see me")
      cache.set("asd/qwe/zxc/221","you should never see me")
      cache.set("asd/qwe/zxc/321","you should never see me")
      cache.set("asd/qwe/zxc/421","you should never see me")
      cache.delete_match("asd/qwe/zxc")
      cache.get("asd/qwe/zxc/40").should == nil
      cache.get("asd/qwe/zxc/30").should == nil
      cache.get("asd/qwe/zxc/20").should == nil
      cache.get("asd/qwe/zxc/10").should == nil
      cache.get("asd/qwe/zxc/41").should == nil
      cache.get("asd/qwe/zxc/31").should == nil
      cache.get("asd/qwe/zxc/21").should == nil
      cache.get("asd/qwe/zxc/11").should == nil
      cache.get("asd/qwe/zxc/42").should == nil
      cache.get("asd/qwe/zxc/32").should == nil
      cache.get("asd/qwe/zxc/22").should == nil
      cache.get("asd/qwe/zxc/12").should == nil
      cache.get("asd/qwe/zxc/401").should == nil
      cache.get("asd/qwe/zxc/301").should == nil
      cache.get("asd/qwe/zxc/201").should == nil
      cache.get("asd/qwe/zxc/101").should == nil
      cache.get("asd/qwe/zxc/411").should == nil
      cache.get("asd/qwe/zxc/311").should == nil
      cache.get("asd/qwe/zxc/211").should == nil
      cache.get("asd/qwe/zxc/111").should == nil
      cache.get("asd/qwe/zxc/421").should == nil
      cache.get("asd/qwe/zxc/321").should == nil
      cache.get("asd/qwe/zxc/221").should == nil
      cache.get("asd/qwe/zxc/121").should == nil
    end
  end

  it "should expire" do
    cache.set("expiring key","you should never see me", 1)
    sleep(3)
    cache.get("expiring key").should == nil
  end

  it "should replace" do
    cache.replace("replacing-key", "newkey")
    cache.get("replacing-key").should == nil
    cache.set("replacing-key", "oldkey")
    cache.replace("replacing-key", "newkey")
    cache.get("replacing-key").should == 'newkey'
  end
  
  it "should append" do
    cache.set("appending-key", "test1")
    cache.get("appending-key").should == "test1"
    cache.append("appending-key", "test2")
    cache.get("appending-key").should == "test1test2"
  end
  
  it "should incr" do
    cache.set("incr-key", 123)
    cache.incr("incr-key", 20).should == 143
    cache.get("incr-key").should == 143
  end
  
  it "should decr" do
    cache.set("decr-key", 123)
    cache.decr("decr-key", 20).should == 103
    cache.get("decr-key").should == 103
  end
  
end
