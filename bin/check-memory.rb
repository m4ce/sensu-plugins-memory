#!/usr/bin/env ruby
#
# check-memory.rb
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

require 'sensu-plugin/check/cli'

class CheckMemory < Sensu::Plugin::Check::CLI
  option :swap,
         :description => "Check SWAP rather than real memory (default: false)",
         :long => "--swap",
         :boolean => true,
         :default => false

  option :available,
         :description => "Check thresholds against memory available",
         :long => "--available",
         :boolean => true,
         :default => true

  option :used,
         :description => "Check thresholds against memory used",
         :long => "--used",
         :boolean => true,
         :default => false

  option :warn,
         :description => "Warn if PERCENTAGE exceeds current memory available/used",
         :short => "-w <PERCENTAGE>",
         :long => "--warn <PERCENTAGE>",
         :proc => proc(&:to_i),
         :default => 20

  option :crit,
         :description => "Critical if PERCENTAGE exceeds current memory available/used",
         :short => "-c <PERCENTAGE>",
         :long => "--crit <PERCENTAGE>",
         :proc => proc(&:to_i),
         :default => 15

  def initialize()
    super

    # sanity checks
    if config[:used]
      raise "Warning threshold must be lower than the critical threshold" if config[:warn] >= config[:crit]
    else
      raise "Warning threshold must be greater than the critical threshold" if config[:warn] <= config[:crit]
    end

    @vmstat = get_vmstat()
  end

  def get_vmstat()
    vmstat = {}

    meminfo = %x[cat /proc/meminfo]
    vmstat['total'] = meminfo[/^MemTotal:\s*(\d+)/, 1].to_i
    vmstat['free'] = meminfo[/^MemFree:\s*(\d+)/, 1].to_i
    vmstat['available'] = meminfo[/^MemAvailable:\s*(\d+)/, 1].to_i
    vmstat['buffers'] = meminfo[/^Buffers:\s*(\d+)/, 1].to_i
    vmstat['cached'] = meminfo[/^Cached:\s*(\d+)/, 1].to_i
    vmstat['swapcached'] = meminfo[/^SwapCached:\s*(\d+)/, 1].to_i
    vmstat['swaptotal'] = meminfo[/^SwapTotal:\s*(\d+)/, 1].to_i
    vmstat['swapfree'] = meminfo[/^SwapFree:\s*(\d+)/, 1].to_i

    vmstat
  end

  def run
    if config[:swap]
      avail = @vmstat['swapcached'] + @vmstat['swapfree']
      used = @vmstat['swaptotal'] - avail

      if @vmstat['swaptotal'] > 0
        pavail = avail * 100 / @vmstat['swaptotal']
        pused = used * 100 / @vmstat['swaptotal']
      else
        ok("Swap is disabled")
      end

      prefix = "Swap"
    else
      avail = @vmstat['cached'] + @vmstat['buffers'] + @vmstat['free']
      used = @vmstat['total'] - avail
      pavail = avail * 100 / @vmstat['total']
      pused = used * 100 / @vmstat['total']
      prefix = "Real"
    end

    if config[:used]
      msg = "#{prefix} memory used #{used / 1024}MB of #{@vmstat['total'] / 1024}MB"
      critical("#{msg} (>= #{config[:crit]}%)") if pused >= config[:crit]
      warning("#{msg} (>= #{config[:warn]}%)") if pused >= config[:warn]
      ok("#{msg} (< #{config[:warn]}%)")
    else
      msg = "#{prefix} memory available #{avail / 1024}MB of #{@vmstat['total'] / 1024}MB"
      critical("#{msg} (<= #{config[:crit]}%)") if pavail <= config[:crit]
      warning("#{msg} (<= #{config[:warn]}%)") if pavail <= config[:warn]
      ok("#{msg} (>= #{config[:warn]}%)")
    end
  end
end
