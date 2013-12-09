require 'license_auto/exceptions'

## [Simple and stupid code to emulate pure virtual methods in Ruby](https://gist.github.com/mssola/6138163)
##
# Here's the trick: let's open the Module class and implement the
# 'virtual' method, so it's available also for classes.
class Module
  ##
  # This method defines a method for each of the elements passed by the
  # variable length argument. The implementation for each method will be
  # just raising a VirtualMethodError coupled with the name of the method.
  def virtual(*methods)
    methods.each do |name|
      define_method(name) { raise LicenseAuto::VirtualMethodError, name }
    end
  end
end