require 'csv'
require 'progressbar'

players=User.all.select{|u| u.data.where(gameName: 'Tenacity-Meditation').count > 0 }
#players = User.where(player_name: 'TM1')
puts 'total players ' + players.count.to_s
#grab all the column headers
types = AdaData.where(gameName: 'Tenacity-Meditation').distinct(:key)
puts types.inspect
examples = Array.new
bar = ProgressBar.new 'gathering types', types.count
types.each do |type|
  ex = AdaData.where(key: type).first
  if ex != nil
    examples << ex
  end
  bar.inc
end
bar.finish
puts examples.count
puts examples.inspect
all_attrs = Array.new
bar = ProgressBar.new 'gathering attributes', examples.count
examples.each do |e|
  e.attributes.keys.each do |k|
    all_attrs << k
  end
  bar.inc
end
bar.finish
puts all_attrs.inspect

#bar = ProgressBar.new 'parsing players', players.count
players.each do |play|
  data = play.data.where(gameName: 'Tenacity-Meditation')
  if data.count > 0
    CSV.open("csv/meditation/tenacity_test_"+play.email+".csv", "w") do |csv|
      data.each do |entry|
        out = Array.new
        all_attrs.uniq.each do |attr|
          if entry.attributes.keys.include?(attr)
            out << entry.attributes[attr]
          else
            out << ""
          end
        end
        csv << out
      end
    end
  end
end
#bar.finish