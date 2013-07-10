module UIAutoMonkey
  module CommandHelper
    require 'open3'

    def shell(cmds)
      puts "Shell: #{cmds.inspect}"
      Open3.popen3(*cmds) do |stdin, stdout, stderr|
        stdin.close
        return stdout.read
      end
    end

    def run_process(cmds)
      puts "Run: #{cmds.inspect}"
      Kernel.system(cmds[0], *cmds[1..-1])
    end

    def kill_all(process_name, signal=nil)
      signal = signal ? "-#{signal}" : ''
      Kernel.system("killall #{signal} '#{process_name}'")
    end

    def xcode_path
      @xcode_path ||= shell(%w(xcode-select -print-path)).strip
    end

  end
end
