class FakeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "Estoy ejecutando un trabajo falso con argumentos: #{args.inspect}"
  end
end
