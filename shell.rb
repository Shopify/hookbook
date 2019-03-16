require('open3')
require('pty')
require('pathname')
require('timeout')

class Shell
  def self.available_versions(shell)
    shells = ENV['PATH'].split(':').map { |d| File.join(d, shell) }
      .select { |f| File.file?(f) && File.executable?(f) }
      .uniq { |f| Pathname.new(f).realpath }

    shells.inject({}) do |h, path|
      v, st = Open3.capture2e(path, '--version')
      if st.success?
        version = v.match(/[\d.]+/)[0]
        h.merge(version => path)
      else
        h
      end
    end
  end

  def initialize(*args, prompt:)
    @prompt = prompt
    @ours, theirs = PTY.open
    @pid = Process.spawn({'PS1' => @prompt }, *args, in: theirs, out: theirs, err: theirs, pgroup: true)
    @output = ''
    advance_to_prompt
  end

  def send_commands(commands)
    commands.each { |command| send_command(command) }
  end

  def send_command(command)
    tw = Thread.new do
      @ours.puts(command);
    end
    advance_to_prompt
    tw.join
  end

  def output
    @output.gsub("\r\n", "\n").lines
  end

  def output!
    output
  ensure
    @output = ''
  end

  def close
    @ours.close
    Process.waitpid2(@pid)
  end

  private

  def advance_to_prompt
    size = 16
    Timeout.timeout(3) do
      begin
        loop do
          @output += @ours.read_nonblock(size)
          break if @output.end_with?(@prompt)
        end
      rescue IO::EAGAINWaitReadable
        size /= 2 unless size == 1
        retry
      end
    end
  end
end
