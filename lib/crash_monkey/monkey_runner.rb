# coding: utf-8

module UIAutoMonkey
  require 'fileutils'
  require 'timeout'
  require 'rexml/document'
  require 'erubis'
  require 'json'

  class MonkeyRunner
    TRACE_TEMPLATE='/Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate'
    RESULT_BASE_PATH = File.expand_path('crash_monkey_result')
    RESULT_DETAIL_EVENT_NUM = 20
    TIME_LIMIT_SEC = 100

    include UIAutoMonkey::CommandHelper

    def run(opts)
      @options = opts
      if @options[:show_config]
        show_config
        return true
      elsif @options[:list_app]
        list_app
        return true
      elsif @options[:reset_iphone_simulator]
        reset_iphone_simulator
      end
      ###########
      log @options.inspect
      FileUtils.remove_dir(result_base_dir, true)
      FileUtils.makedirs(result_base_dir)
      generate_ui_auto_monkey
      ###########
      start_time = Time.now
      result_list = []
      total_test_count.times do |times|
        @times = times
        setup_running
        result = run_a_case
        finish_running(result)
        result_list << result
      end
      #
      create_index_html({
          :start_time => start_time,
          :end_time => Time.now,
          :result_list => result_list,
      })
      all_tests_ok?(result_list)
    end

    def setup_running
      # kill_all('iPhone Simulator')
      FileUtils.remove_dir(result_dir, true)
      ENV['UIARESULTSPATH'] = result_dir
      @crashed = false
    end

    def run_a_case
      log "=================================== Start Test (#{@times+1}/#{total_test_count}) ======================================="
      cr_list = crash_report_list
      start_time = Time.now
      watch_syslog do
        begin
          Timeout.timeout(time_limit_sec + 5) do
            run_process(%W(instruments -l #{time_limit} -t #{TRACE_TEMPLATE} #{app_path} -e UIASCRIPT #{ui_auto_monkey_path} -e UIARESULTSPATH #{result_base_dir}))
          end
        rescue Timeout::Error
          log 'killall -9 instruments'
          kill_all('instruments', '9')
        end
      end
      new_cr_list = crash_report_list
      # increase crash report?
      unless cr_list[0] == new_cr_list[0]
        @crashed = true
        log "Find new crash report: #{new_cr_list[0]}"
        FileUtils.copy(new_cr_list[0], result_dir)
      end
      # output result
      create_result_html(parse_results)

      {
        :start_time => start_time,
        :end_time => Time.now,
        :times => @times,
        :ok => !@crashed,
        :result_dir => File.basename(result_history_dir(@times)),
        :message => nil
      }
    end

    def finish_running(result)
      FileUtils.remove_dir(result_history_dir(@times), true)
      FileUtils.move(result_dir, result_history_dir(@times))
      kill_all('iPhone Simulator')
    end

    def create_index_html(result_hash)
      er = Erubis::Eruby.new(File.read(template_path('index.html.erb')))
      result_hash[:test_count] = result_hash[:result_list].size
      result_hash[:ok_count] = result_hash[:result_list].select {|r| r[:ok]}.size
      result_hash[:ng_count] = result_hash[:test_count] - result_hash[:ok_count]
      open("#{result_base_dir}/index.html", 'w') {|f| f.write er.result(result_hash)}
      copy_html_resources
    end
    
    def copy_html_resources
      bootstrap_dir = File.expand_path('../../bootstrap', __FILE__)
      FileUtils.copy("#{bootstrap_dir}/css/bootstrap.css", result_base_dir)
      FileUtils.copy("#{bootstrap_dir}/js/bootstrap.js", result_base_dir)
    end

    def all_tests_ok?(result_list)
      result_list.select {|r| !r[:ok]}.empty?
    end

    def show_config
      puts File.read(config_json_path)
    end

    def show_extend_javascript
      filename = @options[:extend_javascript_path]
      return File.exist?(filename), filename
    end

    def list_app
      puts find_apps('*.app').map{|n| File.basename n}.uniq.sort.join("\n")
    end

    def log(msg)
      puts msg
    end

    def reset_iphone_simulator
      `rm -rf ~/Library/Application\ Support/iPhone\ Simulator/`
    end

    def total_test_count
      (@options[:run_count] || 2)
    end

    def app_path
      @app_path ||= find_app_path(@options)
    end

    def app_name
      File.basename(app_path).gsub(/\.app$/, '')
    end

    def find_apps(app)
      `"ls" -dt #{ENV['HOME']}/Library/Developer/Xcode/DerivedData/*/Build/Products/*/#{app}`.strip.split(/\n/)
    end

    def find_app_path(opts)
      app_path = nil
      if opts[:app_path].include?('/')
        app_path = File.expand_path(opts[:app_path])
      elsif opts[:app_path] =~ /\.app$/
        apps = find_apps(opts[:app_path])
        app_path = apps[0]
        log "#{apps.size} apps are found, USE NEWEST APP: #{app_path}" if apps.size > 1
      end
      unless app_path
        raise 'Invalid AppName'
      end
      app_path
    end

    def time_limit
      time_limit_sec * 1000
    end

    def time_limit_sec
      (@options[:time_limit_sec] || TIME_LIMIT_SEC).to_i
    end

    def ui_auto_monkey_original_path
      File.expand_path('../../ui-auto-monkey/UIAutoMonkey.js', __FILE__)
    end

    def ui_auto_monkey_path
      "#{result_base_dir}/UIAutoMonkey.js"
    end

    def result_base_dir
      @options[:result_base_dir] || RESULT_BASE_PATH
    end

    def result_dir
      "#{result_base_dir}/Run 1"
    end

    def result_history_dir(times)
      "#{result_base_dir}/result_#{sprintf('%03d', times)}"
    end

    def crash_report_dir
      "#{ENV['HOME']}/Library/Logs/DiagnosticReports"
    end

    def crash_report_list
      `ls -t #{crash_report_dir}/#{app_name}_*.crash`.strip.split(/\n/)
    end

    def grep_syslog
      'tail -n 0 -f /var/log/system.log'
    end

    def console_log_path
      "#{result_dir}/console.log"
    end

    def template_path(name)
      File.expand_path("../templates/#{name}", __FILE__)
    end

    def generate_ui_auto_monkey
      extend_javascript_flag, extend_javascript_path =  show_extend_javascript
      orig = File.read(ui_auto_monkey_original_path)
      config = JSON.parse(File.read(config_json_path))
      replace_str = "    config: #{JSON.pretty_generate(config, :indent => ' '*6)}, \n"
      js = replace_text(orig, replace_str, '__UIAutoMonkey Configuration Begin__', '__UIAutoMonkey Configuration End__')
      if extend_javascript_flag
        js = File.read(extend_javascript_path) + "\n" + js
      end
      File.open(ui_auto_monkey_path, 'w') {|f| f.write(js)}
    end

    def config_json_path
      @options[:config_path] || template_path('config.json')
    end

    def replace_text(orig, replace_str, marker_begin_line, marker_end_line)
      results = []
      status = 1
      orig.each_line do |line|
        if status == 1 && line =~ /#{marker_begin_line}/
          status = 2
          results << line
          results << replace_str
        elsif status == 2 && line =~/#{marker_end_line}/
          status = 3
        end
        results << line unless status == 2
      end
      results.join('')
    end

    def parse_results
      filename = "#{result_dir}/Automation Results.plist"
      log_list = []
      if File.exists?(filename)
        doc = REXML::Document.new(open(filename))
        doc.elements.each('plist/dict/array/dict') do |record|
          ary = record.elements.to_a.map{|a| a.text}
          log_list << Hash[*ary]
        end
        @crashed = true if log_list[-1][LOG_TYPE] == 'Fail'
      end
      log_list
    end

    def create_result_html(log_list)
      latest_list = LogDecoder.new(log_list).decode_latest(RESULT_DETAIL_EVENT_NUM)
      hash = {}
      hash[:log_list] = latest_list.reverse
      hash[:log_list_json] = JSON.dump(hash[:log_list])
      crash_report = Dir.glob("#{result_dir}/*.crash")[0]
      hash[:crash_report] = crash_report ? File.basename(crash_report) : nil
      hash[:crashed] = @crashed

      er = Erubis::Eruby.new(File.read(template_path('result.html.erb')))
      open("#{result_dir}/result.html", 'w') do |f|
        f.write(er.result(hash))
      end
      FileUtils.copy(template_path('result_view.js'), "#{result_dir}/result_view.js")
    end

    def watch_syslog
      STDOUT.sync = true
      stdin, stdout, stderr = Open3.popen3(grep_syslog)
      log_filename = "#{result_base_dir}/console.log"
      thread = Thread.new do
        File.open(log_filename, 'a') do |output|
          begin
            while true
              line = stdout.readline
              output.write(line) if line.include?(app_name)
            end
          rescue IOError
            log 'tail finished: system.log'
          end
        end
      end
      yield
      sleep 3
      stdout.close; stderr.close; stdin.close
      thread.join
      FileUtils.makedirs(result_dir) unless File.exists?(result_dir)
      if File.exists?(log_filename)
        FileUtils.move(log_filename, console_log_path)
      end
    end
  end

  LOG_TYPE = 'LogType'
  MESSAGE = 'Message'
  TIMESTAMP = 'Timestamp'
  SCREENSHOT = 'Screenshot'

  class LogDecoder
    def initialize(log_list)
      @log_list = log_list
    end

    def decode_latest(num=10)
      hash = {}
      ret = []
      @log_list.reverse.each do |log|
        break if num == 0
        if log[LOG_TYPE] == 'Screenshot'
          if log[MESSAGE] =~ /^action/
            hash[:action_image] = log[MESSAGE]
          elsif log[MESSAGE] =~ /^screen/
            hash[:screen_image] = log[MESSAGE]
            hash[:timestamp] = log[TIMESTAMP]
            # emit and init
            if block_given?
              yield(hash)
            else
              ret << hash
            end
            hash = {}
            num -= 1
          end
        elsif log[LOG_TYPE] == 'Debug' && log[MESSAGE] =~ /^target./
          hash[:message] = log[MESSAGE] unless log[MESSAGE] =~ /^target.captureRectWithName/ && log[MESSAGE] =~ /switcherScrollView/
        end
      end
      ret
    end
  end
end
