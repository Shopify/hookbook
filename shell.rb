require('open3')
require('pty')
require('pathname')

class Shell
  def self.available_versions(shell)
    ENV['PATH'].split(':').map do |d|
      File.join(d, shell)
    end.select do |f|
      File.file?(f) && File.executable?(f)
    end.uniq do |f|
      Pathname.new(f).realpath
    end.inject({}) do |h, path|
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
    @output += @ours.gets(@prompt)
  end
end
