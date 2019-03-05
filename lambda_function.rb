require 'json'
require 'rmagick'
require 'aws-sdk-s3'


# include Magick
ColorDict = {
    'lavender' => [160, 141, 214],
    'peach' => [247, 191, 171],
    'burnt orange' => [168, 76, 40],
    'caramel' => [216, 161, 94],
    'aruba' => [139, 239, 217],
    'Peacock' => [16, 199, 210],
    'deep pink' => [196, 8, 118],
    'slack yellow' => [253, 184, 48],
    'cornflower' => [80, 137, 208],
    'royal purple' => [64, 30, 114],
    'maroon' => [88, 28, 50],
    'spring green' => [31, 172, 113],
    'navy' => [8, 30, 44],
    'lime' => [160, 206, 62],
    'hibiscus' => [222, 75, 155],
    'sunflower' => [255, 201, 56],
    'purple' => [93, 30, 92],
    'lake' => [128, 195, 214],
    'pine' => [43, 68, 35],
    'black' => [0, 0, 0],
    'persimmon' => [253, 72, 48],
    'red' => [197, 15, 45],
    'charcoal' => [95, 100, 104],
    'lagoon' => [0, 62, 102],
    'mushroom' => [113, 98, 87],
    'ultramarine' => [53, 45, 126],
    'onyx' => [63, 66, 69],
    'seafoam' => [89, 170, 160],
    'goldenrod' => [213, 208, 58],
    'yellow' => [255, 247, 27],
    'reef' => [0, 162, 130],
    'bleach' => [255, 255, 255],
    'cyan' => [20, 161, 227],
    'iris' => [119, 71, 159],
    'red orange' => [219, 29, 60],
    'natural' => [249, 244, 236],
    'rich brown' => [55, 40, 32],
    'concrete' => [151, 160, 167],
    'sand' => [186, 179, 160],
    'clementine' => [255, 154, 35],
    'teal' => [3, 129, 119],
    'cerulean' => [37, 98, 176],
    'kelly' => [34, 116, 47],
    'turf' => [96, 147, 59],
    'blush' => [253, 174, 202],
    'rust' => [118, 55, 66],
    'dark green' => [46, 74, 52],
    'white plaiting' => [124, 103, 148],
    'grey plaiting' => [177, 133, 134],
    'black plaiting' => [127, 192, 12],
  }.freeze


  HexDict = {
    'lavender' => '#a08dd6',
    'peach' => '#f7bfab',
    'burnt orange' => '#a84c28',
    'caramel' => '#d8a15e',
    'aruba' => '#8befd9',
    'charcoal' => '#5f6468',
    'deep pink' => '#c40876',
    'slack yellow' => '#fdb830',
    'rust' => '#763742',
    'mushroom' => '#716257',
    'cornflower' => '#5089d0',
    'ultramarine' => '#352d7e',
    'onyx' => '#3f4245',
    'royal purple' => '#401e72',
    'maroon' => '#581c32',
    'seafoam' => '#59aaa0',
    'spring green' => '#1fac71',
    'red orange' => '#db1d3c',
    'yellow' => '#fff71b',
    'reef' => '#00a282',
    'bleach' => '#ffffff',
    'navy' => '#081e2c',
    'cyan' => '#14a1e3',
    'teal' => '#038177',
    'lime' => '#a0ce3e',
    'hibiscus' => '#de4b9b',
    'iris' => '#77479f',
    'goldenrod' => '#d5d03a',
    'natural' => '#f9f4ec',
    'sunflower' => '#ffc938',
    'purple' => '#5d1e5c',
    'peacock' => '#10c7d2',
    'lake' => '#80c3d6',
    'pine' => '#2b4423',
    'rich brown' => '#372820',
    'concrete' => '#9aa9ab',
    'sand' => '#bab3a0',
    'black' => '#000000',
    'red' => '#c50f2d',
    'lagoon' => '#003e66',
    'cerulean' => '#2562b0',
    'kelly' => '#22742f',
    'turf' => '#60933b',
    'blush' => '#fdaeca',
    'persimmon' => '#fd4830',
    'clementine' => '#ff9a23',
    'dark green' => '#2e4a34',
    'white plaiting' => '#7c6794',
    'grey plaiting' => '#b18586',
    'black plaiting' => '#7fc078',
  }.freeze

def getHexFromName(name)
  HexDict[name.downcase]
end

def color_distance(rgb1,rgb2)
  (rgb1.red - rgb2[0]).abs + (rgb1.green - rgb2[1]).abs + (rgb1.blue - rgb2[2]).abs
end


def pick_color_name(rgb)
  distance = 1000
  color = ''

  ColorDict.each do |key, value|
    if color_distance(rgb, value) < distance
      color = key
      distance = color_distance(rgb, value)
    end
  end
  # return check_color_exceptions(color ,rgb)
  color
end

def countBitmapPixels(bmpUrl)

  img = Magick::ImageList.new(bmpUrl)

  # res_array wil store unminified result of pixel counts as color names
  res_array = []

  pixelCounts = Hash.new 0

  img.each_pixel do |pixel, _c, _r|
    pixel.red = pixel.red / 257
    pixel.green = pixel.green / 257
    pixel.blue = pixel.blue / 257
    pixelCounts[pick_color_name(pixel)] += 1
  end


  return pixelCounts
end


def lambda_handler(event:, context:)
  bucket = Aws::S3::Resource.new(region: 'us-east-1').bucket('account-sockclub-com')
  obj = bucket.object('image-generation/bmp.bmp')
  obj.get(response_target: '/tmp/bmp.bmp')

  bmp_url = "/tmp/bmp.bmp"
  topColor = event["topColor"]
  heelColor = event["heelColor"]
  toeColor = event["toeColor"]
  company = event["company"]
  designNum = event["designNum"].to_i
  # cuff_url = event["cuff_url"]
  baseFileName = event["baseFileName"]

  frontSideBack = Magick::ImageList.new
  pdf1 = Magick::ImageList.new
  pdf2 = Magick::ImageList.new
  flatView = Magick::ImageList.new
  bmp = Magick::ImageList.new

#################


  sockAttributes = {}
  colors = []
  pixelCounts = countBitmapPixels(bmp_url)

  imageGenerationColors = []

  i = 1
  total = 0
  pixelCounts.each do |color, count|
    color = color.split.map(&:capitalize).join(' ')

    sockAttributes[('Yarn_Color_' + i.to_s + '_Lookup').intern] = color
    sockAttributes[('Yarn_Color_' + i.to_s + '_Pixel').intern] = count.to_i
    colors.push(color)

    total += count.to_i
    imageGenerationColors.push(color)
    i += 1
  end

  sockAttributes[:Number_of_Colors] = i - 1

  if total == 69_384
      sockAttributes[:Chassis_Style] = '10 - Cotton Crew'
      sockAttributes[:Size] = 'Medium'
    elsif total == 56_616
      sockAttributes[:Chassis_Style] = '10 - Cotton Crew'
      sockAttributes[:Size] = 'Small'
    elsif total == 76_776
      sockAttributes[:Chassis_Style] = '10 - Cotton Crew'
      sockAttributes[:Size] = 'Large'
    elsif total == 46_536
      sockAttributes[:Chassis_Style] = '10 - Cotton Crew'
      sockAttributes[:Size] = 'Youth'
    elsif total == 70400
      sockAttributes[:Chassis_Style] = '20 - Nylon Cushion Crew'
      sockAttributes[:Size] = 'Medium'
    end

    if sockAttributes[:Chassis_Style] == '10 - Cotton Crew' || sockAttributes[:Chassis_Style] == '15 - Wool Crew' || sockAttributes[:Chassis_Style] == '16 - Ribbed Cotton Crew' || sockAttributes[:Chassis_Style] == '18 - Ribbed Cotton Crew w/ Ribbed Cuff' || sockAttributes[:Chassis_Style] == '17 - 1.25in Welt Cotton Crew'
      if sockAttributes[:Size] == 'Medium'
        sockAttributes[:Heel_Break] = '226'
        sockAttributes[:Total_Courses] = '413'
        sockAttributes[:Knitting_Machine] = '168'
      elsif sockAttributes[:Size] == 'Large'
        sockAttributes[:Heel_Break] = '244'
        sockAttributes[:Total_Courses] = '457'
        sockAttributes[:Knitting_Machine] = '168'
      elsif sockAttributes[:Size] == 'Small'
        sockAttributes[:Heel_Break] = '186'
        sockAttributes[:Total_Courses] = '337'
        sockAttributes[:Knitting_Machine] = '168'
      elsif sockAttributes[:Size] == 'Extra Large'
        sockAttributes[:Heel_Break] = '274'
        sockAttributes[:Total_Courses] = '517'
        sockAttributes[:Knitting_Machine] = '168'
      else
        sockAttributes[:Heel_Break] = ''
        sockAttributes[:Total_Courses] = ''
        sockAttributes[:Knitting_Machine] = ''
        end
    elsif sockAttributes[:Chassis_Style] == '11 - Cotton Knee High'
      if sockAttributes[:Size] == 'Medium'
        sockAttributes[:Heel_Break] = '404'
        sockAttributes[:Total_Courses] = '591'
        sockAttributes[:Knitting_Machine] = '168'
      elsif sockAttributes[:Size] == 'Youth'
        sockAttributes[:Heel_Break] = '299'
        sockAttributes[:Total_Courses] = '420'
        sockAttributes[:Knitting_Machine] = '168'
      end
    elsif sockAttributes[:Chassis_Style] == '12 - Cotton Ankle Length'
      if sockAttributes[:Size] == 'Medium'
        sockAttributes[:Heel_Break] = '20'
        sockAttributes[:Total_Courses] = '205'
        sockAttributes[:Knitting_Machine] = '168'
      elsif sockAttributes[:Size] == 'Small'
        sockAttributes[:Heel_Break] = '20'
        sockAttributes[:Total_Courses] = '177'
        sockAttributes[:Knitting_Machine] = '168'
      end
    elsif sockAttributes[:Chassis_Style] == '20 - Nylon Cushion Crew' || sockAttributes[:Chassis_Style] == '25 - 2.07in Welt Nylon Cushion Crew'
      if sockAttributes[:Size] == 'Medium'
        sockAttributes[:Heel_Break] = '226'
        sockAttributes[:Total_Courses] = '413'
        sockAttributes[:Knitting_Machine] = '160'
      elsif sockAttributes[:Size] == 'Large'
        sockAttributes[:Heel_Break] = '244'
        sockAttributes[:Total_Courses] = '457'
        sockAttributes[:Knitting_Machine] = '160'
      elsif sockAttributes[:Size] == 'Small'
        sockAttributes[:Heel_Break] = '186'
        sockAttributes[:Total_Courses] = '337'
        sockAttributes[:Knitting_Machine] = '160'
      elsif sockAttributes[:Size] == 'Youth'
        sockAttributes[:Heel_Break] = '156'
        sockAttributes[:Total_Courses] = '277'
        sockAttributes[:Knitting_Machine] = '160'
      end
    elsif sockAttributes[:Chassis_Style] == '21 - Nylon Cushion Ankle'
      if sockAttributes[:Size] == 'Medium'
        sockAttributes[:Heel_Break] = '20'
        sockAttributes[:Total_Courses] = '220'
        sockAttributes[:Knitting_Machine] = '160'
      elsif sockAttributes[:Size] == 'Small'
        sockAttributes[:Heel_Break] = '20'
        sockAttributes[:Total_Courses] = '177'
        sockAttributes[:Knitting_Machine] = '160'
      end
    elsif sockAttributes[:Chassis_Style] == '22 - Nylon Cushion Knee High'
      if sockAttributes[:Size] == 'Medium'
        sockAttributes[:Heel_Break] = '404'
        sockAttributes[:Total_Courses] = '591'
        sockAttributes[:Knitting_Machine] = '160'
      elsif sockAttributes[:Size] == 'Youth'
        sockAttributes[:Heel_Break] = '299'
        sockAttributes[:Total_Courses] = '420'
        sockAttributes[:Knitting_Machine] = '160'
      end
    elsif sockAttributes[:Chassis_Style] == '14 - Cotton Toddler'
      if sockAttributes[:Size] == 'Toddler'
        sockAttributes[:Heel_Break] = '100'
        sockAttributes[:Total_Courses] = '180'
        sockAttributes[:Knitting_Machine] = '96'
      end
    elsif sockAttributes[:Chassis_Style] == '13 - Cotton Infant'
      if sockAttributes[:Size] == 'Infant'
        sockAttributes[:Heel_Break] = '70'
        sockAttributes[:Total_Courses] = '122'
        sockAttributes[:Knitting_Machine] = '96'
      end
    elsif sockAttributes[:Chassis_Style] == '20 - Nylon Cushion Crew'
      if sockAttributes[:Size] == 'Medium'
        sockAttributes[:Heel_Break] = '136'
        sockAttributes[:Total_Courses] = '440'
        sockAttributes[:Knitting_Machine] = '160'
      end
    end


  #################
  chassis = sockAttributes[:Chassis_Style]
  size = sockAttributes[:Size]

  mediumCC = false
  largeCC = false
  smallCC = false
  mediumCC = true if chassis == '10 - Cotton Crew' && size == 'Medium'
  largeCC = true if chassis == '10 - Cotton Crew' && size == 'Large'
  smallCC = true if chassis == '10 - Cotton Crew' && size == 'Small'
  mediumAC = true if chassis == '20 - Nylon Cushion Crew' && size == 'Medium'
  colors = colors.reject(&:empty?)

  chassis = chassis[chassis.index('-') + 1..-1].upcase
  size = size.upcase
  company = company.upcase
  designNum = designNum.to_s
  size = 'ONE SIZE FITS MOST' if chassis == 'COTTON CREW' && size == 'MEDIUM'

  docWidth = 2550
  docHeight = 3300

  if smallCC
    leftMargin = 7
    topMargin = 8
  else
    leftMargin = 24
    topMargin = 28
  end

  if mediumAC
    sockWidth = 160
  else
    sockWidth = 172
  end
  sockHeight = if smallCC
                 sockWidth * 4
               elsif largeCC
                 sockWidth * 5.5
               else
                 sockWidth * 4.93
               end

  cuffHeight = 125
  strokeWidth = 2

  scale = 1

  image = Magick::ImageList.new(bmp_url)

  # cuffImage = Magick::ImageList.new(cuff_url) if cuff_url != ''

  sockLogo = Magick::ImageList.new('SockClubLogo.png')
  sockPattern = image.copy
  circles = Magick::ImageList.new

  frontSideBack.new_image(1050, 1200)

  pdf1.new_image(docWidth, docHeight)
  pdf2.new_image(docWidth, docHeight)

  if smallCC
    flatView.new_image(373, 740)
  else
    flatView.new_image(373, 900)
  end

  # BMP
  ############################################
  bmp = sockPattern

  # FLAT VIEW
  ############################################
  if mediumCC
    sockPattern = sockPattern.resize_to_fit(363, 890)
  elsif largeCC
    sockPattern = sockPattern.resize(363, 890)
  elsif smallCC
    sockPattern = sockPattern.resize_to_fit(363, 730)
  elsif mediumAC
    sockPattern = sockPattern.resize_to_fit(373, 890)
  end

  flatView.composite!(sockPattern, 5, 5, Magick::OverCompositeOp)

  gc = Magick::Draw.new
  gc.stroke_linejoin('round')
  gc.stroke_width(3)
  gc.stroke('red')

  if mediumCC
    gc.line(0, 492, 400, 492)
  elsif largeCC
    gc.line(0, 479, 400, 479)
  elsif smallCC
    gc.line(0, 407, 400, 407)
  end

  gc.draw(flatView)


  # SOCK FRONT VIEW
  ############################################

  if mediumCC
    sockPattern = sockPattern.resize_to_fit(0, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  elsif largeCC
    sockPattern = sockPattern.resize(sockWidth * 2, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  elsif smallCC
    sockPattern = sockPattern.resize(sockWidth * 2, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  elsif mediumAC
    sockPattern = sockPattern.resize(sockWidth * 2, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  end
  frontSideBack.composite!(sockPattern, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)

  cuff = Magick::Draw.new
  cuff.stroke('black')
  cuff.stroke_width(strokeWidth)

  # if cuff_url == ''
    cuff.fill_color(getHexFromName(topColor))
  # else
    # cuff.fill('transparent')
    # cuffPattern = cuffImage.copy
    # cuffPattern = cuffPattern.resize_to_fit(0, cuffHeight * 2).crop(0, cuffHeight, sockWidth, cuffHeight)
    # frontSideBack.composite!(cuffPattern, leftMargin, topMargin, Magick::OverCompositeOp)
  # end

  cuff.rectangle(leftMargin, topMargin, sockWidth + leftMargin, topMargin + cuffHeight)

  mainSock = Magick::Draw.new
  mainSock.fill_opacity(0)
  mainSock.stroke('black')
  mainSock.stroke_width(strokeWidth)
  mainSock.rectangle(leftMargin, topMargin + cuffHeight, sockWidth + leftMargin, topMargin + cuffHeight + sockHeight)

  circle = Magick::Draw.new
  circle.stroke('black')
  circle.fill_color(getHexFromName(toeColor))
  circle.stroke_width(strokeWidth)
  circle.stroke_linecap('round')
  circle.stroke_linejoin('round')
  circle.ellipse(leftMargin + sockWidth / 2, topMargin + cuffHeight + sockHeight, sockWidth / 2, sockWidth / 2, 0, 180)

  mainSock.draw(frontSideBack)
  circle.draw(frontSideBack)
  cuff.draw(frontSideBack)

  # SOCK BACK VIEW
  ############################################

  leftMargin += 845

  sockPatternRight = image.copy
  sockPatternLeft = image.copy

  if mediumCC
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 , 0, sockWidth / 2, sockHeight)
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2, sockHeight)
  elsif mediumAC
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 - 33, 0, sockWidth / 2 , sockHeight)
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2 , sockHeight)
  elsif largeCC
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 , 0, sockWidth / 2, sockHeight)
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2, sockHeight)
  elsif smallCC
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 - 1, 0, sockWidth / 2, sockHeight)
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2, sockHeight)
  end

  frontSideBack.composite!(sockPatternLeft, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  frontSideBack.composite!(sockPatternRight, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)


  tv_cuff = Magick::Draw.new
  tv_cuff.stroke('black')
  tv_cuff.stroke_width(strokeWidth)
  # if cuff_url == ''
    tv_cuff.fill_color(getHexFromName(topColor))
  # else
    # tv_cuff.fill('transparent')
    # cuffPattern = cuffImage.copy
    # cuffPattern = cuffPattern.resize_to_fit(0, cuffHeight * 2).crop(0, cuffHeight, sockWidth, cuffHeight)
    # frontSideBack.composite!(cuffPattern, leftMargin, topMargin, Magick::OverCompositeOp)
  # end

  tv_cuff.rectangle(leftMargin, topMargin, sockWidth + leftMargin, topMargin + cuffHeight)

  tv_mainSock = Magick::Draw.new
  tv_mainSock.fill_opacity(0)
  tv_mainSock.stroke('black')
  tv_mainSock.stroke_width(strokeWidth)
  tv_mainSock.rectangle(leftMargin, topMargin + cuffHeight, sockWidth + leftMargin, topMargin + cuffHeight + sockHeight)

  if smallCC
    heel = Magick::Draw.new
    heel.stroke('black')
    heel.fill_color(getHexFromName(heelColor))
    heel.stroke_width(strokeWidth)
    heel.stroke_linecap('round')
    heel.stroke_linejoin('round')
    heel.path('M' + (leftMargin + sockWidth).to_s + ',' + (sockHeight / 1.35).to_s + ' Q' + (leftMargin + sockWidth / 2).to_s + ',' + (sockHeight / 1.35 + 60).to_s + ' ' + leftMargin.to_s + ',' + (sockHeight / 1.35).to_s + ' Q ' + (leftMargin + sockWidth / 2).to_s + ',' + (sockHeight / 1.35 - 60).to_s + ' ' + (leftMargin + sockWidth).to_s + ',' + (sockHeight / 1.35).to_s)
  elsif largeCC
    heel = Magick::Draw.new
    heel.stroke('black')
    heel.fill_color(getHexFromName(heelColor))
    heel.stroke_width(strokeWidth)
    heel.stroke_linecap('round')
    heel.stroke_linejoin('round')
    heel.path('M' + (leftMargin + sockWidth).to_s + ',' + (sockHeight / 1.475).to_s + ' Q' + (leftMargin + sockWidth / 2).to_s + ',' + (sockHeight / 1.475 + 60).to_s + ' ' + leftMargin.to_s + ',' + (sockHeight / 1.475).to_s + ' Q ' + (leftMargin + sockWidth / 2).to_s + ',' + (sockHeight / 1.475 - 60).to_s + ' ' + (leftMargin + sockWidth).to_s + ',' + (sockHeight / 1.475).to_s)
  else
    heel = Magick::Draw.new
    heel.stroke('black')
    heel.fill_color(getHexFromName(heelColor))
    heel.stroke_width(strokeWidth)
    heel.stroke_linecap('round')
    heel.stroke_linejoin('round')
    heel.path('M' + (leftMargin + sockWidth).to_s + ',' + (sockHeight / 1.35).to_s + ' Q' + (leftMargin + sockWidth / 2).to_s + ',' + (sockHeight / 1.35 + 60).to_s + ' ' + leftMargin.to_s + ',' + (sockHeight / 1.35).to_s + ' Q ' + (leftMargin + sockWidth / 2).to_s + ',' + (sockHeight / 1.35 - 60).to_s + ' ' + (leftMargin + sockWidth).to_s + ',' + (sockHeight / 1.35).to_s)
  end

  tv_circle = Magick::Draw.new
  tv_circle.stroke('black')
  tv_circle.fill_color(getHexFromName(toeColor))
  tv_circle.stroke_width(strokeWidth)
  tv_circle.stroke_linecap('round')
  tv_circle.stroke_linejoin('round')
  tv_circle.ellipse(leftMargin + sockWidth / 2, topMargin + cuffHeight + sockHeight, sockWidth / 2, sockWidth / 2, 0, 180)

  tv_mainSock.draw(frontSideBack)
  tv_circle.draw(frontSideBack)
  tv_cuff.draw(frontSideBack)
  heel.draw(frontSideBack)

  # SOCK SIDE VIEW
  ############################################

  leftMargin -= 393

  sockPatternRight = image.copy
  sockPatternLeft = image.copy

  if mediumCC
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 70)
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5, 0, sockWidth / 2, sockHeight / 2 + 70)
    frontSideBack.composite!(sockPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sockPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  elsif largeCC
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 70)
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5, 0, sockWidth / 2, sockHeight / 2 + 70)
    frontSideBack.composite!(sockPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sockPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  elsif smallCC
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 40)
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5, 0, sockWidth / 2, sockHeight / 2 + 40)
    frontSideBack.composite!(sockPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sockPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  elsif mediumAC
    sockPatternRight = sockPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 70)
    sockPatternLeft = sockPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.3, 0, sockWidth / 2, sockHeight / 2 + 70)
    frontSideBack.composite!(sockPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sockPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  end

  tv_cuff = Magick::Draw.new
  tv_cuff.stroke_width(strokeWidth)
  tv_cuff = Magick::Draw.new
  tv_cuff.stroke('black')
  tv_cuff.stroke_width(strokeWidth)
  # if cuff_url == ''
    tv_cuff.fill_color(getHexFromName(topColor))
  # else
    # tv_cuff.fill('transparent')
    # cuffPattern = cuffImage.copy
    # cuffPattern = cuffPattern.resize_to_fit(0, cuffHeight * 2).crop(0, cuffHeight, sockWidth, cuffHeight)
    # frontSideBack.composite!(cuffPattern, leftMargin, topMargin, Magick::OverCompositeOp)
  # end
  tv_cuff.rectangle(leftMargin, topMargin, sockWidth + leftMargin, topMargin + cuffHeight)

  if smallCC
    tv_mainSockTop = Magick::Draw.new
    tv_mainSockTop.fill_opacity(0)
    tv_mainSockTop.stroke('black')
    tv_mainSockTop.stroke_width(strokeWidth)
    tv_mainSockTop.path('M ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 - 25).to_s + ' ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight).to_s + ' ' + (leftMargin + sockWidth).to_s + ' ' + (topMargin + cuffHeight).to_s + ' ' + (leftMargin + sockWidth).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 - 5).to_s + ' ' + ' ')
  else
    tv_mainSockTop = Magick::Draw.new
    tv_mainSockTop.fill_opacity(0)
    tv_mainSockTop.stroke('black')
    tv_mainSockTop.stroke_width(strokeWidth)
    tv_mainSockTop.path('M ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 15).to_s + ' ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight).to_s + ' ' + (leftMargin + sockWidth).to_s + ' ' + (topMargin + cuffHeight).to_s + ' ' + (leftMargin + sockWidth).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 65).to_s + ' ' + ' ')
  end

  heel_2 = Magick::Draw.new
  heel_2.stroke('black')
  heel_2.fill_color(getHexFromName(heelColor))
  heel_2.stroke_width(strokeWidth)
  heel_2.stroke_linecap('round')
  heel_2.stroke_linejoin('round')

  if largeCC
    heel_2.path('M ' + (leftMargin + sockWidth / 2 - 20).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 22).to_s + '  L ' + (leftMargin + sockWidth).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 22).to_s + '  A 40,40  0 0,1  ' + (leftMargin + sockWidth - 13).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 80).to_s + '  Z')
  elsif smallCC
    heel_2.path('M ' + (leftMargin + sockWidth / 2 - 20).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 - 8).to_s + '  L ' + (leftMargin + sockWidth).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 - 8).to_s + '  A 40,40  0 0,1  ' + (leftMargin + sockWidth - 16).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 53).to_s + '  Z')
  else
    heel_2.path('M ' + (leftMargin + sockWidth / 2 - 20).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 22).to_s + '  L ' + (leftMargin + sockWidth).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 22).to_s + '  A 40,40  0 0,1  ' + (leftMargin + sockWidth - 10).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 80).to_s + '  Z')
  end

  tv_circle = Magick::Draw.new
  tv_circle.stroke('black')
  tv_circle.fill_color(getHexFromName(toeColor))
  tv_circle.stroke_width(strokeWidth)
  tv_circle.stroke_linecap('round')
  tv_circle.stroke_linejoin('round')

  if smallCC
    tv_circle.path('M ' + (leftMargin - 167).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 198).to_s + ' a1,1 0 0,0 ' + (sockWidth - 33).to_s + ',103   ')
  elsif largeCC
    tv_circle.path('M ' + (leftMargin - 161).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 388).to_s + ' a1,1 0 0,0 ' + (sockWidth - 16).to_s + ',68   ')
  elsif mediumAC
    tv_circle.path('M ' + (leftMargin - 205).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 286).to_s + ' a1,1 0 0,0 ' + (sockWidth - 33).to_s + ',93 ')
  else
    tv_circle.path('M ' + (leftMargin - 215).to_s + ',' + (topMargin + cuffHeight + sockHeight / 2 + 296).to_s + ' a1,1 0 0,0 ' + (sockWidth - 33).to_s + ',103 ')
  end

  tv_mainSockBottom = Magick::Draw.new
  tv_mainSockBottom.stroke_width(strokeWidth)
  hat = image.copy
  hat.resize!(2)
  hat.rotate!(35.5)
  tv_mainSockBottom.fill_opacity(0)
  tv_mainSockBottom.stroke('black')

  maskImage = sockPattern.resize_to_fit(0, sockHeight)
  maskImage.background_color = 'none'

  if mediumCC
    tv_mainSockBottom.path('M ' + ' ' + (leftMargin + sockWidth - 10).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 80).to_s + ' ' + (leftMargin - 76).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 398).to_s + ' ' + (leftMargin - 215).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 295).to_s + ' ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 12).to_s + ' ')
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight - 10).crop(sockWidth, sockHeight / 2 +10, sockWidth, sockHeight / 2)
    sockPattern2.background_color = 'none'
    sockPattern2.rotate!(37.2)
    frontSideBack.composite!(sockPattern2, 261, 550, Magick::OverCompositeOp)

    maskImage.rotate!(-7)
    maskImage = maskImage.crop(173, 393, sockWidth, 47)
    maskImage.rotate!(7)
    frontSideBack.composite!(maskImage, leftMargin-2, sockHeight/2+122, Magick::OverCompositeOp)
  elsif largeCC
    tv_mainSockBottom.path('M ' + ' ' + (leftMargin + sockWidth - 14).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 78).to_s + ' ' + (leftMargin - 4.5).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 455).to_s + ' ' + (leftMargin - 161).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 387).to_s + ' ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 12).to_s + ' ')
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight - 20).crop(sockWidth, sockHeight / 2 + 28, sockWidth, sockHeight / 2)
    sockPattern2.background_color = 'none'
    sockPattern2.rotate!(23.3)
    frontSideBack.composite!(sockPattern2, 314, 621, Magick::OverCompositeOp)

    maskImage.rotate!(-7)
    maskImage = maskImage.crop(170, 440, sockWidth, 47)
    maskImage.rotate!(7)
    frontSideBack.composite!(maskImage, leftMargin-3, sockHeight/2+119, Magick::OverCompositeOp)
  elsif smallCC
    tv_mainSockBottom.path('M ' + ' ' + (leftMargin + sockWidth - 15).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 50).to_s + ' ' + (leftMargin - 27 ).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 300).to_s + ' ' + (leftMargin - 166).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 196).to_s + ' ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 - 25).to_s + ' ')
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight).crop(sockWidth, sockHeight / 2 + 28, sockWidth, sockHeight)
    sockPattern2.background_color = 'none'
    sockPattern2.rotate!(36.5)
    frontSideBack.composite!(sockPattern2, 291, 422, Magick::OverCompositeOp)

    maskImage.rotate!(-15)
    maskImage = maskImage.crop(165, 271, sockWidth, 47)
    maskImage.rotate!(15)
    frontSideBack.composite!(maskImage, leftMargin-1, sockHeight/2+60, Magick::OverCompositeOp)

  elsif mediumAC
    tv_mainSockBottom.path('M ' + ' ' + (leftMargin + sockWidth - 10).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 80).to_s + ' ' + (leftMargin - 76).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 378).to_s + ' ' + (leftMargin - 205).to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 285).to_s + ' ' + leftMargin.to_s + ' ' + (topMargin + cuffHeight + sockHeight / 2 + 15).to_s + ' ')
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight - 10).crop(sockWidth, sockHeight / 2 +10, sockWidth, sockHeight / 2)
    sockPattern2.background_color = 'none'
    sockPattern2.rotate!(37.2)
    frontSideBack.composite!(sockPattern2, 272, 533, Magick::OverCompositeOp)

    maskImage.rotate!(-7)
    maskImage = maskImage.crop(173, 362, sockWidth, 47)
    maskImage.rotate!(7)
    frontSideBack.composite!(maskImage, leftMargin-2, sockHeight/2+122, Magick::OverCompositeOp)
  end

  tv_mainSockTop.draw(frontSideBack)
  tv_mainSockBottom.draw(frontSideBack)
  tv_circle.draw(frontSideBack)
  tv_cuff.draw(frontSideBack)
  heel_2.draw(frontSideBack)


  ########################################################################################

  frontSideBack.write('/tmp/frontSideBack.jpg')

  # LETTERS N SHIT
  ############################################
  leftMargin = 50

  contentAlignTop = 1000
  circleSize = 120
  text = Magick::Draw.new
  text.font_family = 'helvetica'
  text.pointsize = 40

  copyright = Magick::Draw.new
  copyright.font_family = 'helvetica'
  copyright.pointsize = 12

  sockPattern = image
  frontSideBackFile = Magick::ImageList.new('/tmp/frontSideBack.jpg')

  sockPattern = sockPattern.resize_to_fit(0, 2000)
  pdf1.composite!(sockPattern, leftMargin, contentAlignTop, Magick::OverCompositeOp)

  sockLogo = sockLogo.resize_to_fit(450, 0)
  pdf1.composite!(sockLogo, docWidth - 450 - leftMargin, 150, Magick::OverCompositeOp)

  sockLogo = sockLogo.resize_to_fit(450, 0)
  pdf2.composite!(sockLogo, docWidth - 450 - leftMargin, 150, Magick::OverCompositeOp)

  if largeCC
    frontSideBackFile = frontSideBackFile.resize_to_fit(docWidth - leftMargin * 2 - 200, 0)
    pdf2.composite!(frontSideBackFile, leftMargin + 70, 500, Magick::OverCompositeOp)
  else
    frontSideBackFile = frontSideBackFile.resize_to_fit(docWidth - leftMargin * 2, 0)
    pdf2.composite!(frontSideBackFile, leftMargin, 500, Magick::OverCompositeOp)
  end



  text.annotate(pdf1, 0, 0, leftMargin, 160, company.upcase + ' CUSTOM SOCKS') { self.fill = 'black' }
  text.annotate(pdf1, 0, 0, leftMargin, 240, chassis.upcase) { self.fill = 'black' }
  text.annotate(pdf1, 0, 0, leftMargin, 320, size.upcase) { self.fill = 'black' }
  text.annotate(pdf1, 0, 0, leftMargin, 400, 'DESIGN ' + designNum) { self.fill = 'black' }
  text.annotate(pdf1, 0, 0, 175, 3200, 'Copyright is retained by Custom by Sock Club on all design work including words, pictures, ideas, visuals and illustrations') { self.fill = '#898989' }
  text.annotate(pdf1, 0, 0, 455, 3260, 'unless specifically released in writing and after all costs/fees have been paid and settled.') { self.fill = '#898989' }

  text.annotate(pdf2, 0, 0, leftMargin, 160, company.upcase + ' CUSTOM SOCKS') { self.fill = 'black' }
  text.annotate(pdf2, 0, 0, leftMargin, 240, chassis.upcase) { self.fill = 'black' }
  text.annotate(pdf2, 0, 0, leftMargin, 320, size.upcase) { self.fill = 'black' }
  text.annotate(pdf2, 0, 0, leftMargin, 400, 'DESIGN ' + designNum) { self.fill = 'black' }
  text.annotate(pdf2, 0, 0, 175, 3200, 'Copyright is retained by Custom by Sock Club on all design work including words, pictures, ideas, visuals and illustrations') { self.fill = '#898989' }
  text.annotate(pdf2, 0, 0, 455, 3260, 'unless specifically released in writing and after all costs/fees have been paid and settled.') { self.fill = '#898989' }

  text.gravity(Magick::SouthGravity)

  yVal = contentAlignTop + circleSize

  colors.push(topColor.split.map(&:capitalize).join(' '), heelColor.split.map(&:capitalize).join(' '), toeColor.split.map(&:capitalize).join(' ')).uniq!

  if colors.include?('Black Plaiting')
    colors.insert(-1, colors.delete_at(colors.index('Black Plaiting')))
  elsif colors.include?('White Plaiting')
    colors.insert(-1, colors.delete_at(colors.index('White Plaiting')))
  elsif colors.include?('Grey Plaiting')
    colors.insert(-1, colors.delete_at(colors.index('Grey Plaiting')))
  end

  colors.each_with_index do |v, i|
    v = v.split.map(&:downcase).join(' ')
    k = Magick::Draw.new
    k.stroke('black')
    k.fill_color(getHexFromName(v))
    k.stroke_width(strokeWidth)
    k.stroke_linecap('round')
    k.stroke_linejoin('round')
    if colors.length > 6
      yVal = contentAlignTop + circleSize if i == 5
      if i < 6
        text.annotate(pdf1, 0, 0, 1350, yVal, v.to_s.upcase) { self.fill = 'black' }
        k.ellipse(1200, yVal, circleSize, circleSize, 0, 360)
      else
        text.annotate(pdf1, 0, 0, 1950, yVal, v.to_s.upcase) { self.fill = 'black' }
        k.ellipse(1800, yVal, circleSize, circleSize, 0, 360)
      end
    else
      text.annotate(pdf1, 0, 0, 1650, yVal, v.to_s.upcase) { self.fill = 'black' }
      k.ellipse(1500, yVal, circleSize, circleSize, 0, 360)
    end

    yVal += 350
    k.draw(pdf1)
  end

  ################################################################################################

  pdf1.write('/tmp/page2.jpg')
  pdf2.write('/tmp/page1.jpg')

  flatView.write('/tmp/flatView.png')
  bmp.write('/tmp/bmp.bmp')

  image_list = Magick::ImageList.new('/tmp/page1.jpg', '/tmp/page2.jpg') do
    self.quality = 100
    self.density = '300'
    self.colorspace = Magick::RGBColorspace
    self.interlace = Magick::NoInterlace
  end.each_with_index do |img, i|
    img.resize_to_fit!(612, 828)
    # img.write("/tmp/images.pdf")
  end

  # image_list = Magick::ImageList.new('/tmp/page1.jpg', '/tmp/page2.jpg')
  image_list.write('/tmp/images.pdf')

  images = ['/tmp/images.pdf', '/tmp/flatView.png', '/tmp/frontSideBack.jpg', '/tmp/bmp.bmp']

  filePath = '/tmp/images.pdf'
  s3 = Aws::S3::Client.new(region: 'us-east-1')

  # upload bmp to s3
  images.each do |filePath|
    key = 'well_fuck'
    if File.basename(filePath).include?('images')
      key = baseFileName + "_ClientApproved.pdf"
    elsif File.basename(filePath).include?('flatView')
      key = baseFileName + "_FlatView.png"
    elsif File.basename(filePath).include?('frontSideBack')
      key = baseFileName + '_FBSView.jpg'
    elsif File.basename(filePath).include?('bmp')
      key = baseFileName + '.bmp'
    end

    # Upload a file.
    response = s3.put_object(
      :bucket => 'account-sockclub-com',
      :key    => 'image-generation/' + key,
      :body   => IO.read(filePath),
    )
  end

  return sockAttributes

end
