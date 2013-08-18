require 'new_relic/agent/instrumentation/rack'
class AppMetric
  # アプリケーションをスルーするミドルウェアを実装：
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  end

  # call を定義した後で include すること：
  include NewRelic::Agent::Instrumentation::Rack
end
