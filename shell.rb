require('open3')
require('pty')

class Shell
  def initialize(*args, prompt:)
    @prompt = prompt
    @ours, theirs = PTY.open
    @pid = Process.spawn({'PS1' => @prompt }, *args, in: theirs, out: theirs, err: theirs, pgroup: true)
    @output = ''
    advance_to_prompt
  end

  def send_commands(commands)
    commands.lines.each { |command| send_command(command) }
    self
  end

  def send_command(command)
    tw = Thread.new do
      @ours.puts(command);
    end
    advance_to_prompt
    tw.join
    self
  end

  def output
    @output.gsub("\r\n", "\n").lines
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
