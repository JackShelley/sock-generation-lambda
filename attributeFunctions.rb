def countBitmapPixels(bmpUrl)
  img = Magick::ImageList.new(bmpUrl)

  pixelCounts = Hash.new 0

  # each pixel has a red, green, and blue attribute which we're using to guess the name of the color using pick_color_name
  #divides by 257 because ruby does rgb values in weird way that you don't need to worry about
  # _c is the column number
  # _r is the row number
  #pixel counts is a hash that creates a color in itself if it doesnt exist
  #if it does exist, it increments its count by 1
  #really just counts occurences of each color pixel by pixel
  #pixelCounts looks like {'red' => 500, 'burnt orange' => 4890, 'yellow' => 242, ...}
  img.each_pixel do |pixel, _c, _r|
    pixel.red = pixel.red / 257
    pixel.green = pixel.green / 257
    pixel.blue = pixel.blue / 257
    pixelCounts[pick_color_name(pixel)] += 1
  end

  return pixelCounts
end

# pulls all the information needed for image generation and zoho submission from the bmp file
def defineSockAttributes(bmp_url)
  #sock attributes exists as a container to store return values of the lambda function
  #ie chasis style, size, pixel counts, colors, etc.
  #these are returned from the lambda to be used in zoho in account.sockclub
  sockAttributes = {}

  #colors is an array that stores color names to be used in page2 of the pdf
  colors = []
  pixelCounts = countBitmapPixels(bmp_url)

  i = 1
  total = 0
  pixelCounts.each do |color, count|
    color = color.split.map(&:capitalize).join(" ")

    sockAttributes[("Yarn_Color_#{i.to_s}_Lookup").intern] = color
    sockAttributes[("Yarn_Color_#{i.to_s}_Pixel").intern] = count.to_i
    colors.push(color)

    total += count.to_i
    i += 1
  end

  sockAttributes[:Number_of_Colors] = i - 1

  if total == 69_384
      sockAttributes[:Chassis_Style] = "10 - Cotton Crew"
      sockAttributes[:Size] = "Medium"
  elsif total == 56_616
    sockAttributes[:Chassis_Style] = "10 - Cotton Crew"
    sockAttributes[:Size] = "Small"
  elsif total == 76_776
    sockAttributes[:Chassis_Style] = "10 - Cotton Crew"
    sockAttributes[:Size] = "Large"
  elsif total == 46_536
    sockAttributes[:Chassis_Style] = "10 - Cotton Crew"
    sockAttributes[:Size] = "Youth"
  elsif total == 70400
    sockAttributes[:Chassis_Style] = "20 - Nylon Cushion Crew"
    sockAttributes[:Size] = "Medium"
  end

  if sockAttributes[:Chassis_Style] == "10 - Cotton Crew" || sockAttributes[:Chassis_Style] == "15 - Wool Crew" || sockAttributes[:Chassis_Style] == "16 - Ribbed Cotton Crew" || sockAttributes[:Chassis_Style] == "18 - Ribbed Cotton Crew w/ Ribbed Cuff" || sockAttributes[:Chassis_Style] == "17 - 1.25in Welt Cotton Crew"
    if sockAttributes[:Size] == "Medium"
      sockAttributes[:Heel_Break] = "226"
      sockAttributes[:Total_Courses] = "413"
      sockAttributes[:Knitting_Machine] = "168"
    elsif sockAttributes[:Size] == "Large"
      sockAttributes[:Heel_Break] = "244"
      sockAttributes[:Total_Courses] = "457"
      sockAttributes[:Knitting_Machine] = "168"
    elsif sockAttributes[:Size] == "Small"
      sockAttributes[:Heel_Break] = "186"
      sockAttributes[:Total_Courses] = "337"
      sockAttributes[:Knitting_Machine] = "168"
    elsif sockAttributes[:Size] == "Extra Large"
      sockAttributes[:Heel_Break] = "274"
      sockAttributes[:Total_Courses] = "517"
      sockAttributes[:Knitting_Machine] = "168"
    else
      sockAttributes[:Heel_Break] = ""
      sockAttributes[:Total_Courses] = ""
      sockAttributes[:Knitting_Machine] = ""
      end
  elsif sockAttributes[:Chassis_Style] == "11 - Cotton Knee High"
    if sockAttributes[:Size] == "Medium"
      sockAttributes[:Heel_Break] = "404"
      sockAttributes[:Total_Courses] = "591"
      sockAttributes[:Knitting_Machine] = "168"
    elsif sockAttributes[:Size] == "Youth"
      sockAttributes[:Heel_Break] = "299"
      sockAttributes[:Total_Courses] = "420"
      sockAttributes[:Knitting_Machine] = "168"
    end
  elsif sockAttributes[:Chassis_Style] == "12 - Cotton Ankle Length"
    if sockAttributes[:Size] == "Medium"
      sockAttributes[:Heel_Break] = "20"
      sockAttributes[:Total_Courses] = "205"
      sockAttributes[:Knitting_Machine] = "168"
    elsif sockAttributes[:Size] == "Small"
      sockAttributes[:Heel_Break] = "20"
      sockAttributes[:Total_Courses] = "177"
      sockAttributes[:Knitting_Machine] = "168"
    end
  elsif sockAttributes[:Chassis_Style] == "20 - Nylon Cushion Crew" || sockAttributes[:Chassis_Style] == "25 - 2.07in Welt Nylon Cushion Crew"
    if sockAttributes[:Size] == "Medium"
      sockAttributes[:Heel_Break] = "226"
      sockAttributes[:Total_Courses] = "413"
      sockAttributes[:Knitting_Machine] = "160"
    elsif sockAttributes[:Size] == "Large"
      sockAttributes[:Heel_Break] = "244"
      sockAttributes[:Total_Courses] = "457"
      sockAttributes[:Knitting_Machine] = "160"
    elsif sockAttributes[:Size] == "Small"
      sockAttributes[:Heel_Break] = "186"
      sockAttributes[:Total_Courses] = "337"
      sockAttributes[:Knitting_Machine] = "160"
    elsif sockAttributes[:Size] == "Youth"
      sockAttributes[:Heel_Break] = "156"
      sockAttributes[:Total_Courses] = "277"
      sockAttributes[:Knitting_Machine] = "160"
    end
  elsif sockAttributes[:Chassis_Style] == "21 - Nylon Cushion Ankle"
    if sockAttributes[:Size] == "Medium"
      sockAttributes[:Heel_Break] = "20"
      sockAttributes[:Total_Courses] = "220"
      sockAttributes[:Knitting_Machine] = "160"
    elsif sockAttributes[:Size] == "Small"
      sockAttributes[:Heel_Break] = "20"
      sockAttributes[:Total_Courses] = "177"
      sockAttributes[:Knitting_Machine] = "160"
    end
  elsif sockAttributes[:Chassis_Style] == "22 - Nylon Cushion Knee High"
    if sockAttributes[:Size] == "Medium"
      sockAttributes[:Heel_Break] = "404"
      sockAttributes[:Total_Courses] = "591"
      sockAttributes[:Knitting_Machine] = "160"
    elsif sockAttributes[:Size] == "Youth"
      sockAttributes[:Heel_Break] = "299"
      sockAttributes[:Total_Courses] = "420"
      sockAttributes[:Knitting_Machine] = "160"
    end
  elsif sockAttributes[:Chassis_Style] == "14 - Cotton Toddler"
    if sockAttributes[:Size] == "Toddler"
      sockAttributes[:Heel_Break] = "100"
      sockAttributes[:Total_Courses] = "180"
      sockAttributes[:Knitting_Machine] = "96"
    end
  elsif sockAttributes[:Chassis_Style] == "13 - Cotton Infant"
    if sockAttributes[:Size] == "Infant"
      sockAttributes[:Heel_Break] = "70"
      sockAttributes[:Total_Courses] = "122"
      sockAttributes[:Knitting_Machine] = "96"
    end
  elsif sockAttributes[:Chassis_Style] == "20 - Nylon Cushion Crew"
    if sockAttributes[:Size] == "Medium"
      sockAttributes[:Heel_Break] = "136"
      sockAttributes[:Total_Courses] = "440"
      sockAttributes[:Knitting_Machine] = "160"
    end
  end
  return [sockAttributes, colors]
end
