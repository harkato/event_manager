require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  phone = phone.gsub(/[^0-9]/, '')
  return phone if phone.length == 10

  if phone.length < 10 || phone.length > 11 || phone.length == 11 && phone[0] != '1'
    'Bad number'
  elsif phone.length == 11 && phone[0] != '1'
    phone[1..9]
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def save_hour(date)
  Time.strptime(date, '%m/%d/%Y %R').hour
end

def save_week_day(date)
  Time.strptime(date, '%m/%d/%Y %R').wday
end

def find_peak_hours(registration_hours)
  day_hours = (1..24).to_a
  total_count = day_hours.each_with_object({}) { |hour, hash| hash[hour] = 0 }

  total_count = registration_hours.reduce(total_count) do |acc, hour|
    acc[hour] += 1 if acc.key?(hour)
    acc
  end

  peak_hours = total_count.values.max
  total_count.each do |hour, count|    
    puts "#{hour}h: #{count} time(s)" if peak_hours == count
  end
end

def find_peak_weekdays(registration_wdays)
  week = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  total_count = [0, 1, 2, 3, 4, 5, 6].each_with_object({}) { |day, hash| hash[day] = 0 }

  total_count = registration_wdays.reduce(total_count) do |acc, day|
    acc[day] += 1 if acc.key?(day)
    acc
  end

  peak_wdays = total_count.values.max

  total_count.each do |wday, count|    
    puts "Weekday #{week[wday]}: #{count} time(s)" if peak_wdays == count
  end
end

puts 'Event Manager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registration_hours = []
registration_weekdays = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  registration_hours << save_hour(row[:regdate])
  registration_weekdays << save_week_day(row[:regdate])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

find_peak_hours(registration_hours)
find_peak_weekdays(registration_weekdays)