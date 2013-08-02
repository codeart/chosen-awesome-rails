module Chosen
  module Rails
    class Engine < ::Rails::Engine
      config.assets.precompile += %w[chosen-*.gif chosen-*.png]
    end
  end
end
