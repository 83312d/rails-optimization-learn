require 'json'
require 'pry'
require 'date'
require 'set'

# require 'ruby-prof'
# require 'stackprof'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_file(file_path)
  users = []
  sessions = []

  # DONE: читаем файл построчно
  File.foreach(file_path) do |line|
    fields = line.strip.split(',')
    # DONE: вызываем на уже заспличенных данных
    users << parse_user(fields) if fields[0] == 'user'
    sessions << parse_session(fields) if fields[0] == 'session'
  end

  [users, sessions]
end

def parse_user(fields)
  {
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
  }
end

def parse_session(fields)
  {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5],
  }
end

def collect_user_stats(users_objects)
  users_objects.each_with_object({}) do |user, stats|
    user_key = "#{user.attributes['first_name']} #{user.attributes['last_name']}"
    user_data = gather_user_data(user)
    stats[user_key] = format_user_stats(user, user_data)
  end
end

def gather_user_data(user)
  data = {
    total_time: 0,
    longest_session: 0,
    chrome_count: 0,
    used_ie: false,
    browsers: [],
    dates: []
  }

  user.sessions.each do |session|
    process_session_data(session, data)
  end

  data
end

def process_session_data(session, data)
  session_time = session['time'].to_i
  browser = session['browser'].upcase

  data[:total_time] += session_time
  data[:longest_session] = [data[:longest_session], session_time].max
  data[:browsers] << browser
  data[:dates] << session['date']
  data[:used_ie] ||= browser.start_with?('INTERNET EXPLORER')
  data[:chrome_count] += 1 if browser.start_with?('CHROME')
end

def format_user_stats(user, data)
  {
    'sessionsCount' => user.sessions.count,
    'totalTime' => "#{data[:total_time]} min.",
    'longestSession' => "#{data[:longest_session]} min.",
    'browsers' => data[:browsers].sort.join(', '),
    'usedIE' => data[:used_ie],
    'alwaysUsedChrome' => data[:chrome_count] == user.sessions.count,
    'dates' => data[:dates].sort.reverse
  }
end

# DONE: считаем браузеры через хэш без all уменьшая асимптотику
def collect_browsers(sessions)
  sessions.each_with_object(Set.new) do |session, unique_browsers|
    unique_browsers.add(session['browser'].upcase)
  end
end

def generate_user_objects(users, sessions)
  session_uid_index = sessions.group_by { |session| session['user_id'] || [] }
  users.map do |user|
    user_sessions = session_uid_index[user['id']]
    User.new(attributes: user, sessions: user_sessions)
  end
end

def work
  # RubyProf.measure_mode = RubyProf::WALL_TIME
  # RubyProf.start

  users, sessions = parse_file('data.txt')
  users_objects = generate_user_objects(users, sessions)
  browsers = collect_browsers(sessions)

  report = {}
  report[:totalUsers] = users.count
  report['uniqueBrowsersCount'] = browsers.count
  report['totalSessions'] = sessions.count
  report['allBrowsers'] = browsers.to_a.sort.join(',')
  report['usersStats'] = collect_user_stats(users_objects)

  File.write('result.json', "#{report.to_json}\n")

  # result = RubyProf.stop
  # # printer = RubyProf::FlatPrinter.new(result)
  # # printer.print(STDOUT)
  # printer = RubyProf::CallStackPrinter.new(result)
  # printer.print(File.open('callstack.html', 'w+'))
end

if __FILE__ == $0
  work
end
