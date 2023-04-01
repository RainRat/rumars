# frozen_string_literal: true

require 'rainbow'

require_relative 'instruction'

module RuMARS
  # This class represents the core memory of the simulator. The size determines
  # how many instructions can be stored at most. When an instruction is
  # addressed, the address space wraps around so that the memory appears as a
  # circular space.
  class MemoryCore
    attr_accessor :debug_level, :logger

    COLORS = %i[silver red green yellow blue magenta cyan aqua indianred]

    @size = 8000

    # Accessor for size
    class << self
      attr_accessor :size
    end

    def initialize(size = 8000)
      MemoryCore.size = size
      @instructions = []
      @debug_level = 0
      @logger = $stdout
      size.times do |address|
        store(address, Instruction.new(0, 'DAT', 'F', Operand.new('', 0), Operand.new('', 0)))
      end
    end

    def self.fold(address)
      (MemoryCore.size + address) % MemoryCore.size
    end

    def log(text)
      @logger.puts text if @debug_level > 2
    end

    def instruction(address)
      @instructions[address]
    end

    def load(address)
      raise ArgumentError, "address #{address} out of range" if address.negative? || address >= MemoryCore.size

      @instructions[address]
    end

    def store(address, instruction)
      raise ArgumentError, "address #{address} out of range" if address.negative? || address >= MemoryCore.size

      instruction.address = address
      @instructions[address] = instruction
    end

    def list(program_counters, current_warrior, start_address = current_warrior.base_address, length = 10)
      length.times do |i|
        address = start_address + i
        puts" #{'%04d' % address} #{program_counters.include?(address) ? '>' : ' '} #{'%-8s' % (current_warrior&.resolve_address(address) || '')} #{@instructions[address]}"
      end
    end

    def load_relative(base_address, program_counter, address)
      core_address = MemoryCore.fold(base_address + program_counter + address)
      instruction = load(core_address)
      log("Loading #{'%04d' % core_address}: #{instruction}")
      instruction
    end

    def store_relative(base_address, program_counter, address, instruction)
      core_address = MemoryCore.fold(base_address + program_counter + address)
      log("Storing #{'%04d' % core_address}: #{instruction}")
      store(core_address, instruction)
    end

    def dump(program_counters)
      term = Rainbow.new

      (MemoryCore.size / 80).times do |line|
        80.times do |column|
          address = (80 * line) + column
          instruction = @instructions[address]
          print term.wrap(instruction_character(instruction)).color(COLORS[instruction.pid])
                    .background(program_counters.include?(address) ? :white : :black)
        end
        puts
      end
    end

    def instruction_character(instruction)
      case instruction.opcode
      when 'DAT'
        'X'
      when 'ADD'
        '+'
      when 'SUB'
        '-'
      when 'MUL'
        '*'
      when 'DIV'
        '/'
      when 'MOD'
        '%'
      when 'MOV'
        'M'
      when 'NOP'
        '.'
      when 'JMP', 'JMZ', 'JMN', 'DJN', 'CMP', 'SLT', 'SEC', 'SNE'
        'J'
      when 'SPL'
        '<'
      else
        '?'
      end
    end
  end
end
