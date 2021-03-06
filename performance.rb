require "csv"

@finished_dir_name = "2020_v5"

def performance
  top = CSV.table("intermediate/finished/#{@finished_dir_name}/top.csv", {:encoding => 'UTF-8', :converters => nil})
  top_map = {}
  top.each do |t|
    top_map[t[:id]] = {horseNumber: t[:horsenumber], horseName: t[:horsename]}
  end
  wide = CSV.table("intermediate/finished/#{@finished_dir_name}/wide.csv", {:encoding => 'UTF-8', :converters => nil})
  wide_map = {}
  wide.each do |t|
    wide_map[t[:id]] = {horseNumber: t[:horsenumber], points: t[:widepoint]}
  end
 
  result = []
  (1..10).each do |i|
    place =  format("%02<number>d", number: i)
    index = CSV.table("datas/2020/#{place}/index.csv", {:encoding => 'UTF-8', :converters => nil})
    race_result = CSV.table("datas/2020/#{place}/race_result.csv", {:encoding => 'UTF-8', :converters => nil})
    race_result_map = {}
    race_result.each do |r|
      if r[:rank] == "1"
        race_result_map[r[:id]] = {horseNumber: r[:horsenumber], raceName: r[:racename]}
      end
    end
    odds = CSV.table("datas/2020/#{place}/odds.csv", {:encoding => 'UTF-8', :converters => nil})
    odds_map = {}
    
    odds.each do |o|
      if o[:type] == "単勝"
        odds_map[o[:id]] = {}
        odds_map[o[:id]][:tan] = o[:odds]
      end
    end

    id = odds[0][:id]
    wide = []
    odds.each do |o|
      if o[:id] != id
        odds_map[id][:wide] = wide
        id = o[:id]
        wide = []
      end
      if o[:type] == "ワイド"
        wide << {horse_number: o[:horsenumber], odds:o[:odds].to_f}
      end
    end
    odds_map[id][:wide] = wide

    index.each do |j|
      next unless j[:racename].include?("(G") #if j[:racename].include?("新馬") || j[:racename].include?("勝クラス") || j[:racename].include?("未勝利") #unless j[:racename].include?("未勝利") #
      id = j[:id]
      
      top_1 = top_map[id][:horseNumber] if top_map[id]
      top_number = race_result_map[id][:horseNumber]

      finished_wide_number = wide_map[id][:horseNumber] if wide_map[id][:horseNumber]
      finished_wide_points = wide_map[id][:points] if wide_map[id][:points]
      wide_1 = finished_wide_number.split(",")[0]
      wide_2 = finished_wide_number.split(",")[1]
      wide_3 = finished_wide_number.split(",")[2]
      wide_point_1 = finished_wide_points.split(",")[0].to_f
      wide_point_2 = finished_wide_points.split(",")[1].to_f
      wide_point_3 = finished_wide_points.split(",")[2].to_f
      wide3ten = [wide_1,wide_2,wide_3]
      wide2ten = [wide_1,wide_2]
      tan_odds = odds_map[id][:tan].to_f
      result_row = [race_result_map[id][:raceName]]
      #単勝
      if top_number == top_1
        result_row << tan_odds*10 -1000
      else
        result_row << -1000
      end
      #ワイド
      result_row << wide_calc(wide2ten,odds_map[id][:wide])
      result_row << wide_calc(wide3ten,odds_map[id][:wide])
      #ワイドポイント
      #result_row << (wide_point_1 + wide_point_2)
      result << result_row
    end
  end
  #result = result.sort_by{|x| x[4]*-1 }
  totals = total_eval(result)
  hit_rates = hit_rate_calc(result)
  recovery_rates = recovery_calc(totals, result)
  p [totals,hit_rates,recovery_rates]
  result.unshift(["----------"])
  result.unshift(totals)
  result.unshift(recovery_rates)
  result.unshift(hit_rates)
  result.unshift(["name","tan","wide","wide3","wide1point"])
  CSV.open("output/sandbox_v6(17-20)/重賞/performance.csv", "w") do |csv| 
    result.each do |data|
      csv << data
    end
  end
end

def total_eval(result)
  col_num = result[1].length
  totals = ["total"]
  col_num.times do |i|
    next if i == 0
    sum = 0
    result.each do |r|
      sum += r[i]
    end
    totals.push sum
  end
  totals
end

def hit_rate_calc(result)
  col_num = result[1].length
  hit_rates = ["hit_rate"]
  (col_num).times do |i|
    next if i == 0
    count = 0
    hit = 0
    result.each do |r|
      if r[i] != -1000
        hit += 1
        count += 1
      else
        count += 1
      end
    end
    rate = (hit.to_f / count)*100
    hit_rates.push (rate.round(2).to_s + "%")
  end
  hit_rates
end

def recovery_calc(totals, result)
  totals
  kakekin = result.length * 1000
  recovery_rates = ["recovery_rate"]
  totals.each_with_index do |t,i|
    next if i == 0
    rate = 100 * (t + kakekin).to_f / kakekin
    recovery_rates.push (rate.round(2).to_s + "%")
  end
  recovery_rates
end

def wide_calc(box,odds)
  wide_money = -1000
  coef = 10
  coef = 3.3 if box.length == 3
  odds.each do |o|
    if is_hit_wide?(box,o[:horse_number])
      wide_money += (o[:odds]*coef).round()
    end
  end
  wide_money
end

def is_hit_wide?(box,horse_nums)
  num1 = horse_nums.split(",")[0]
  num2 = horse_nums.split(",")[1]
  box.include?(num1) && box.include?(num2)
end

performance()
