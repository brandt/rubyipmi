require 'spec_helper'

describe :Connection do

  before :all do
    @path = '/usr/local/bin'
    @provider = "ipmitool"
    @user = "ipmiuser"
    @pass = "impipass"
    @host = "ipmihost"
  end

  before :each do

    Rubyipmi.stub(:locate_command).with('ipmitool').and_return("#{@path}/ipmitool")
    @conn = Rubyipmi.connect(@user, @pass, @host, @provider,{:debug => true})

  end

  it "connection should not be nil" do
    @conn.should_not be_nil
  end

  it "fru should not be nil" do
    @conn.fru.should_not be_nil
  end

  it "provider should not be nil" do
    @conn.provider.should_not be_nil
  end

  it "provider should be ipmitool" do
    @conn.provider.should == "ipmitool"
  end

  it "bmc should not be nil" do
    @conn.bmc.should_not be_nil
  end

  it "sensors should not be nil" do
    @conn.sensors.should_not be_nil

  end

  it "chassis should not be nill" do
    @conn.chassis.should_not be_nil
  end

  it "provider should return ipmitool" do
    @conn.provider.should eq("ipmitool")
  end

  it "debug value should be true" do
    expect(@conn.debug).to eq(true)
  end

  it 'object should have driver set to auto if not specified' do
    expect(@conn.options.has_key?('driver-type')).to eq(false)
  end

  it 'object should have driver set to auto if not specified' do
    @conn = Rubyipmi.connect(@user, @pass, @host, @provider,{:debug => true, :driver => 'auto'})
    expect(@conn.options.has_key?('I')).to eq(false)
  end

  it 'should raise exception if invalid driver type' do
    expect{Rubyipmi.connect(@user, @pass, @host, @provider,{:debug => true, :driver => 'foo'})}.to raise_error(RuntimeError)
  end

  it 'object should have priv type set to ADMINISTRATOR if not specified' do
    @conn = Rubyipmi.connect(@user, @pass, @host, @provider,{:debug => true, :driver => 'auto'})
    expect(@conn.options.has_key?('L')).to eq(false)

  end

  it 'object should have priv type set to USER ' do
    @conn = Rubyipmi.connect(@user, @pass, @host, @provider,{:privilege => 'USER', :debug => true, :driver => 'auto'})
    @conn.options.fetch('L').should eq('USER')
  end

  it 'should raise exception if invalid privilege type' do
    expect{Rubyipmi.connect(@user, @pass, @host, @provider,{:privilege => 'BLAH',:debug => true, :driver => 'auto'})}.to raise_error(RuntimeError)
  end

  it 'object should have driver set to lanplus' do
    @conn = Rubyipmi.connect(@user, @pass, @host, @provider,{:debug => true, :driver => 'lan20'})
    @conn.options['I'].should eq('lanplus')
  end

  it 'object should have driver set to lanplus' do
    @conn = Rubyipmi.connect(@user, @pass, @host, @provider,{:debug => true, :driver => 'lan15'})
    @conn.options['I'].should eq('lan')
  end

  it 'object should have driver set to open' do
    @conn = Rubyipmi.connect(@user, @pass, @host, @provider,{:debug => true, :driver => 'open'})
    @conn.options['I'].should eq('open')
  end

  describe 'use openipmi' do

    it 'should raise error when openipmi is not found' do
      allow(File).to receive(:exists?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exists?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exists?).with('/dev/ipmidev/0').and_return(false)
      expect{Rubyipmi::Ipmitool::Connection.new}.to raise_error(RuntimeError)
    end

    it 'should create an object using defaults' do
      allow(File).to receive(:exists?).with('/dev/ipmi0').and_return(true)
      expect(Rubyipmi::Ipmitool::Connection.new.class).to eq(Rubyipmi::Ipmitool::Connection)
      expect(Rubyipmi::Ipmitool::Connection.new.options).to eq({"I"=>"open"})

    end
  end
end