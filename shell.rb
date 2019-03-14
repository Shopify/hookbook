require('open3')
require('pty')

class Shell
  def initialize(*args, prompt:)
    @prompt = prompt
    @ours, theirs = PTY.open
    @pid = Process.spawn({'PS1' => @prompt }, *args, in: theirs, out: theirs, err: theirs, pgroup: true)
    @output_lines = []
    @trailing_output = ''
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
    @trailing_output += @ours.gets
    tw.join
    advance_to_prompt
    self
  end

  def output
    @output_lines + trailing_as_output
  end

  def close
    @ours.close
    Process.waitpid2(@pid)
  end

  private

  def sanitize(str)
    # ZSH writes some really crazy shit to stdout when it thinks it's attached to
    # a TTY. Don't try too hard to understand this: it's just what I had to do to
    # strip all the formatting stuff.
    str
      .gsub(/\r \r/, "\r")
      .sub(/%.*?\r/, '')
      .gsub(/\x1b\[\??[\d;]*\w/, '')
      .gsub(/(.)\x08/, '')
      .tr("\r", '')
  end

  def at_prompt
    output = sanitize(@trailing_output)
    output == @prompt || output.end_with?("\n#{@prompt}")
  end

  def advance_to_prompt
    @output_lines += trailing_as_output
    @trailing_output = ''
    until at_prompt
      @trailing_output += @ours.gets(@prompt)
    end
  end

  def trailing_as_output
    sanitize(@trailing_output).lines
  end
end
