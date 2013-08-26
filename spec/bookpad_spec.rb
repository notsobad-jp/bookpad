# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe "BOOKPAD" do
  include Rack::Test::Methods
  def app
    @app ||= Sinatra::Application
  end

  describe "access check" do
    describe "access to /" do
      before { get '/' }
      subject { last_response }
      it "正常なレスポンスが返ること" do
        should be_ok
      end
    end

		describe "access to /search" do
			it "should search book"
		end

		describe "access to /detail" do
			it "should show book detail"
		end
  end
end
