# frozen_string_literal: true

require_relative 'parser'

module RuMARS
  # This class handles a MARS program, called a warrior. Inside of MARS
  # programs fight against each other by trying to destroy the other
  # programs.
  class Warrior
    attr_reader :task_queue, :base_address
    attr_accessor :pid

    def initialize(name)
      @task_queue = [0]
      @name = name
      @program = nil
      @base_address = nil
      @pid = nil
    end

    def parse(program)
      @program = Parser.new.parse(program)
    end

    def parse_file(file_name)
      begin
        file = File.read(file_name)
      rescue IOError
        puts "Cannot open file #{file_name}"
        return false
      end

      begin
        parse(file)
        puts "File #{file_name} loaded"
      rescue Parser::ParseError => e
        puts e
        return false
      end

      true
    end

    # Load the program of the warrior into the core memory at the given
    # absolute core memory base address.
    # @param [Integer] base_address
    # @param [MemoryCore] memory_core
    def load_program(base_address, memory_core)
      raise 'No program available for loading' unless @program

      @base_address = base_address
      @program.load_into_core(base_address, memory_core, @pid)

      # Load the program start address into the task queue. We always start with
      # a single thread.
      @task_queue = [@program.start_address]
    end

    def size
      @program&.size
    end

    # Pull the next PC from the queue and return it.
    def next_task
      @task_queue.shift
    end

    def append_tasks(tasks)
      raise ArgumentError, 'Task list must be an Array' unless tasks.respond_to?(:each)

      tasks.each do |task|
        raise ArgumentError, 'Task list must contain only Interger addresses' unless task.is_a?(Integer)
      end

      @task_queue += tasks
    end

    # A warrior is considered alive as long as its task queue is not empty.
    def alive?
      !@task_queue.empty?
    end

    def resolve_address(address)
      @program.resolve_address(address - @base_address) || ''
    end
  end
end
