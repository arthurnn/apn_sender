class ApnSenderGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.template 'script', 'script/apn_sender', :chmod => 0755
    end
  end

end