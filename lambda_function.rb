#Used for generation of images from source bitmap file
#files generated are Flat View, Front Side Back View, and Client Approved PDF

require 'json'
require 'rmagick'
require 'aws-sdk-s3'
require './colorFunctions.rb'
require './attributeFunctions.rb'

def lambda_handler(event:, context:)
# def lambda_handler()
  #initialize s3 bucket
  bucket = Aws::S3::Resource.new(region: "us-east-1").bucket("account-sockclub-com")
  s3 = Aws::S3::Client.new(region: "us-east-1")

  # retrieves bitmap from s3 which was uploaded immediately previous to the lambda call
  obj = bucket.object("image-generation/bmp.bmp")
  obj.get(response_target: "/tmp/bmp.bmp")

  # bmp_url = "https://res.cloudinary.com/sock-club/image/upload/v1547739005/migration/fiuifyd4sepzdkxju1ja.bmp"
  # bmp_url = "https://res.cloudinary.com/sock-club/image/upload/v1551824406/migration/PO7919_BigWild_ColorTest__168.bmp"
  # bmp_url = "https://res.cloudinary.com/sock-club/image/upload/v1551819853/migration/PO7344_CAD_168.bmp"
  # topColor = "red"
  # heelColor = "red"
  # toeColor = "red"
  # company = "fuck that"
  # designNum = "1"
  # cuff_url = ""
  # baseFileName = "fuck_that"

  # parameters of lambda function
  bmp_url = "/tmp/bmp.bmp"
  topColor = event["topColor"]
  heelColor = event["heelColor"]
  toeColor = event["toeColor"]
  company = event["company"]
  designNum = event["designNum"].to_i
  # cuff_url = event["cuff_url"]
  baseFileName = event["baseFileName"]

  #imageLists are what shapes, patterns, words, and images are placed inside of
  #files are then written from imagelist objects at the end
  frontSideBack = Magick::ImageList.new
  pdf1 = Magick::ImageList.new
  pdf2 = Magick::ImageList.new
  flatView = Magick::ImageList.new
  bmp = Magick::ImageList.new

  sockAttributes, colors = defineSockAttributes(bmp_url)

  #assign chassis and size to a new instance of the variable so they can be altered for display in the pdf
  #sockAttributes is returned from the lambda so they should remain unchanged for zoho submission
  chassis = sockAttributes[:Chassis_Style].dup
  size = sockAttributes[:Size].dup

  mediumCC = false
  largeCC = false
  smallCC = false

  #Very important piece here
  #Determines what kind of sock it is
  #Medium Cotton Crew, Large Cotton Crew, Small Cotton Crew, or Medium Athletic Crew
  #Most sizing for layout is highly dependent on sock type
  if chassis == "10 - Cotton Crew" && size == "Medium"
    mediumCC = true
  elsif chassis == "10 - Cotton Crew" && size == "Large"
    largeCC = true
  elsif chassis == "10 - Cotton Crew" && size == "Small"
    smallCC = true
  elsif chassis == "20 - Nylon Cushion Crew" && size == "Medium"
    mediumAC = true
  end

  #removes empty color strings just in case (had some weird behavior where this was happening, better safe than sorry)
  colors = colors.reject(&:empty?)

  #changing strings that will be printed to the pdf so they look nice
  chassis = chassis[chassis.index("-") + 1..-1].upcase
  size = size.upcase
  company = company.upcase
  designNum = designNum.to_s

  if chassis == "COTTON CREW" && size == "MEDIUM"
    size = "ONE SIZE FITS MOST"
  end

  #width and height for each pdf page (page1.jpg, page2.jpg, and images.pdf)
  #if you're trying to change the resolution this is probably a good place to start
  docWidth = 2550
  docHeight = 3300

  #margin here is only used for front side back view, its universally altered later
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

  if smallCC
    sockHeight = sockWidth * 4
  elsif largeCC
    sockHeight = sockWidth * 5.5
  else
    sockHeight = sockWidth * 4.93
  end

  cuffHeight = 125
  strokeWidth = 2
  scale = 1

  #simply the bmp file
  #used to composite over sock outlines as pattern
  image = Magick::ImageList.new(bmp_url)

  #sock club logo in the top right of the pdf
  sockLogo = Magick::ImageList.new("SockClubLogo.png")
  sockPattern = image.copy

  frontSideBack.new_image(1050, 1200)

  pdf1.new_image(docWidth, docHeight)
  pdf2.new_image(docWidth, docHeight)

  if smallCC
    flatView.new_image(373, 740)
  else
    flatView.new_image(373, 900)
  end

  #plain ol bmp pattern
  # Used to composite on top of second page of pdf
  bmp = sockPattern

  # FLAT VIEW
  ############################################
  if mediumCC || largeCC
    sockPattern = sockPattern.resize_to_fit(363, 890)
  elsif smallCC
    sockPattern = sockPattern.resize_to_fit(363, 730)
  elsif mediumAC
    sockPattern = sockPattern.resize_to_fit(373, 890)
  end

  flatView.composite!(sockPattern, 5, 5, Magick::OverCompositeOp)

  #draws red line across gore line
  goreLine = Magick::Draw.new
  goreLine.stroke_linejoin("round")
  goreLine.stroke_width(3)
  goreLine.stroke("red")

  if mediumCC
    goreLine.line(0, 492, 400, 492)
  elsif largeCC
    goreLine.line(0, 479, 400, 479)
  elsif smallCC
    goreLine.line(0, 407, 400, 407)
  end

  goreLine.draw(flatView)


  # SOCK FRONT VIEW
  ############################################

  if mediumCC
    frontViewSockPattern = sockPattern.resize_to_fit(0, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  elsif largeCC
    frontViewSockPattern = sockPattern.resize(sockWidth * 2, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  elsif smallCC
    frontViewSockPattern = sockPattern.resize(sockWidth * 2, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  elsif mediumAC
    frontViewSockPattern = sockPattern.resize(sockWidth * 2, sockHeight).crop(sockWidth / 2, 0, sockWidth, sockHeight)
  end

  frontSideBack.composite!(frontViewSockPattern, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)

  frontViewCuff = Magick::Draw.new
  frontViewCuff.stroke("black")
  frontViewCuff.stroke_width(strokeWidth)
  frontViewCuff.fill_color(getHexFromName(topColor))
  frontViewCuff.rectangle(leftMargin, topMargin, sockWidth + leftMargin, topMargin + cuffHeight)

  frontViewSockBody = Magick::Draw.new
  frontViewSockBody.fill_opacity(0)
  frontViewSockBody.stroke("black")
  frontViewSockBody.stroke_width(strokeWidth)
  frontViewSockBody.rectangle(leftMargin, topMargin + cuffHeight, sockWidth + leftMargin, topMargin + cuffHeight + sockHeight)

  frontViewToe = Magick::Draw.new
  frontViewToe.stroke("black")
  frontViewToe.fill_color(getHexFromName(toeColor))
  frontViewToe.stroke_width(strokeWidth)
  frontViewToe.stroke_linecap("round")
  frontViewToe.stroke_linejoin("round")
  frontViewToe.ellipse(leftMargin + sockWidth / 2, topMargin + cuffHeight + sockHeight, sockWidth / 2, sockWidth / 2, 0, 180)

  frontViewSockBody.draw(frontSideBack)
  frontViewToe.draw(frontSideBack)
  frontViewCuff.draw(frontSideBack)

  # SOCK BACK VIEW
  ############################################

  leftMargin += 845

  # the back view sock pattern splits the bmp file into a left and right side and aligns them
  backViewPatternRight = image.copy
  backViewPatternLeft = image.copy

  if mediumCC
    backViewPatternLeft = backViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 , 0, sockWidth / 2, sockHeight)
    backViewPatternRight = backViewPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2, sockHeight)
  elsif mediumAC
    backViewPatternLeft = backViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 - 33, 0, sockWidth / 2 , sockHeight)
    backViewPatternRight = backViewPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2 , sockHeight)
  elsif largeCC
    backViewPatternLeft = backViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 , 0, sockWidth / 2, sockHeight)
    backViewPatternRight = backViewPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2, sockHeight)
  elsif smallCC
    backViewPatternLeft = backViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5 - 1, 0, sockWidth / 2, sockHeight)
    backViewPatternRight = backViewPatternRight.resize_to_fit(0, sockHeight).crop(0, 0, sockWidth / 2, sockHeight)
  end

  frontSideBack.composite!(backViewPatternLeft, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  frontSideBack.composite!(backViewPatternRight, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)

  backViewCuff = Magick::Draw.new
  backViewCuff.stroke("black")
  backViewCuff.stroke_width(strokeWidth)
  backViewCuff.fill_color(getHexFromName(topColor))
  backViewCuff.rectangle(leftMargin, topMargin, sockWidth + leftMargin, topMargin + cuffHeight)

  backViewSockBody = Magick::Draw.new
  backViewSockBody.fill_opacity(0)
  backViewSockBody.stroke("black")
  backViewSockBody.stroke_width(strokeWidth)
  backViewSockBody.rectangle(leftMargin, topMargin + cuffHeight, sockWidth + leftMargin, topMargin + cuffHeight + sockHeight)

  if smallCC
    backViewHeel = Magick::Draw.new
    backViewHeel.stroke("black")
    backViewHeel.fill_color(getHexFromName(heelColor))
    backViewHeel.stroke_width(strokeWidth)
    backViewHeel.stroke_linecap("round")
    backViewHeel.stroke_linejoin("round")
    backViewHeel.path("M#{(leftMargin + sockWidth).to_s},#{(sockHeight / 1.35).to_s} Q#{(leftMargin + sockWidth / 2).to_s},#{(sockHeight / 1.35 + 60).to_s} #{leftMargin.to_s},#{(sockHeight / 1.35).to_s} Q #{(leftMargin + sockWidth / 2).to_s},#{(sockHeight / 1.35 - 60).to_s} #{(leftMargin + sockWidth).to_s},#{(sockHeight / 1.35).to_s}")
  elsif largeCC
    backViewHeel = Magick::Draw.new
    backViewHeel.stroke("black")
    backViewHeel.fill_color(getHexFromName(heelColor))
    backViewHeel.stroke_width(strokeWidth)
    backViewHeel.stroke_linecap("round")
    backViewHeel.stroke_linejoin("round")
    backViewHeel.path("M#{(leftMargin + sockWidth).to_s},#{(sockHeight / 1.475).to_s} Q#{(leftMargin + sockWidth / 2).to_s},#{(sockHeight / 1.475 + 60).to_s} #{leftMargin.to_s},#{(sockHeight / 1.475).to_s} Q #{(leftMargin + sockWidth / 2).to_s},#{(sockHeight / 1.475 - 60).to_s} #{(leftMargin + sockWidth).to_s},#{(sockHeight / 1.475).to_s}")
  else
    backViewHeel = Magick::Draw.new
    backViewHeel.stroke("black")
    backViewHeel.fill_color(getHexFromName(heelColor))
    backViewHeel.stroke_width(strokeWidth)
    backViewHeel.stroke_linecap("round")
    backViewHeel.stroke_linejoin("round")
    backViewHeel.path("M#{(leftMargin + sockWidth).to_s},#{(sockHeight / 1.35).to_s} Q#{(leftMargin + sockWidth / 2).to_s},#{(sockHeight / 1.35 + 60).to_s} #{leftMargin.to_s},#{(sockHeight / 1.35).to_s} Q #{(leftMargin + sockWidth / 2).to_s},#{(sockHeight / 1.35 - 60).to_s} #{(leftMargin + sockWidth).to_s},#{(sockHeight / 1.35).to_s}")
  end

  backViewToe = Magick::Draw.new
  backViewToe.stroke("black")
  backViewToe.fill_color(getHexFromName(toeColor))
  backViewToe.stroke_width(strokeWidth)
  backViewToe.stroke_linecap("round")
  backViewToe.stroke_linejoin("round")
  backViewToe.ellipse(leftMargin + sockWidth / 2, topMargin + cuffHeight + sockHeight, sockWidth / 2, sockWidth / 2, 0, 180)

  backViewSockBody.draw(frontSideBack)
  backViewToe.draw(frontSideBack)
  backViewCuff.draw(frontSideBack)
  backViewHeel.draw(frontSideBack)

  # SOCK SIDE VIEW
  ############################################

  leftMargin -= 393

  sideViewPatternRight = image.copy
  sideViewPatternLeft = image.copy

  if mediumCC
    sideViewPatternRight = sideViewPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 70)
    sideViewPatternLeft = sideViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5, 0, sockWidth / 2, sockHeight / 2 + 70)
    frontSideBack.composite!(sideViewPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sideViewPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  elsif largeCC
    sideViewPatternRight = sideViewPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 70)
    sideViewPatternLeft = sideViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5, 0, sockWidth / 2, sockHeight / 2 + 70)
    frontSideBack.composite!(sideViewPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sideViewPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  elsif smallCC
    sideViewPatternRight = sideViewPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 40)
    sideViewPatternLeft = sideViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.5, 0, sockWidth / 2, sockHeight / 2 + 40)
    frontSideBack.composite!(sideViewPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sideViewPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  elsif mediumAC
    sideViewPatternRight = sideViewPatternRight.resize_to_fit(0, sockHeight).crop(sockWidth, 0, sockWidth / 2, sockHeight / 2 + 70)
    sideViewPatternLeft = sideViewPatternLeft.resize_to_fit(0, sockHeight).crop(sockWidth * 1.3, 0, sockWidth / 2, sockHeight / 2 + 70)
    frontSideBack.composite!(sideViewPatternLeft, leftMargin + sockWidth / 2, topMargin + cuffHeight, Magick::OverCompositeOp)
    frontSideBack.composite!(sideViewPatternRight, leftMargin, topMargin + cuffHeight, Magick::OverCompositeOp)
  end

  sideViewCuff = Magick::Draw.new
  sideViewCuff.stroke_width(strokeWidth)
  sideViewCuff = Magick::Draw.new
  sideViewCuff.stroke("black")
  sideViewCuff.stroke_width(strokeWidth)
  sideViewCuff.fill_color(getHexFromName(topColor))
  sideViewCuff.rectangle(leftMargin, topMargin, sockWidth + leftMargin, topMargin + cuffHeight)

  sideViewHeel = Magick::Draw.new
  sideViewHeel.stroke("black")
  sideViewHeel.fill_color(getHexFromName(heelColor))
  sideViewHeel.stroke_width(strokeWidth)
  sideViewHeel.stroke_linecap("round")
  sideViewHeel.stroke_linejoin("round")

  if largeCC
    sideViewHeel.path("M #{(leftMargin + sockWidth / 2 - 20).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 22).to_s} L #{(leftMargin + sockWidth).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 22).to_s} A 40,40  0 0,1 #{(leftMargin + sockWidth - 13).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 80).to_s} Z")
  elsif smallCC
    sideViewHeel.path("M #{(leftMargin + sockWidth / 2 - 20).to_s},#{(topMargin + cuffHeight + sockHeight / 2 - 8).to_s} L #{(leftMargin + sockWidth).to_s},#{(topMargin + cuffHeight + sockHeight / 2 - 8).to_s} A 40,40  0 0,1  #{(leftMargin + sockWidth - 16).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 53).to_s} Z")
  else
    sideViewHeel.path("M #{(leftMargin + sockWidth / 2 - 20).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 22).to_s} L #{(leftMargin + sockWidth).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 22).to_s} A 40,40  0 0,1  #{(leftMargin + sockWidth - 10).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 80).to_s} Z")
  end

  tv_circle = Magick::Draw.new
  tv_circle.stroke("black")
  tv_circle.fill_color(getHexFromName(toeColor))
  tv_circle.stroke_width(strokeWidth)
  tv_circle.stroke_linecap("round")
  tv_circle.stroke_linejoin("round")

  if smallCC
    tv_circle.path("M #{(leftMargin - 167).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 198).to_s} a1,1 0 0,0 #{(sockWidth - 33).to_s},103   ")
  elsif largeCC
    tv_circle.path("M #{(leftMargin - 161).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 388).to_s} a1,1 0 0,0 #{(sockWidth - 16).to_s},68   ")
  elsif mediumAC
    tv_circle.path("M #{(leftMargin - 205).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 286).to_s} a1,1 0 0,0 #{(sockWidth - 33).to_s},93 ")
  else
    tv_circle.path("M #{(leftMargin - 215).to_s},#{(topMargin + cuffHeight + sockHeight / 2 + 296).to_s} a1,1 0 0,0 #{(sockWidth - 33).to_s},103 ")
  end

  if smallCC
    sideViewSockBodyTop = Magick::Draw.new
    sideViewSockBodyTop.fill_opacity(0)
    sideViewSockBodyTop.stroke("black")
    sideViewSockBodyTop.stroke_width(strokeWidth)
    sideViewSockBodyTop.path("M #{leftMargin.to_s} #{(topMargin + cuffHeight + sockHeight / 2 - 25).to_s} #{leftMargin.to_s} #{(topMargin + cuffHeight).to_s} #{(leftMargin + sockWidth).to_s} #{(topMargin + cuffHeight).to_s}  #{(leftMargin + sockWidth).to_s} #{(topMargin + cuffHeight + sockHeight / 2 - 5).to_s}")
  else
    sideViewSockBodyTop = Magick::Draw.new
    sideViewSockBodyTop.fill_opacity(0)
    sideViewSockBodyTop.stroke("black")
    sideViewSockBodyTop.stroke_width(strokeWidth)
    sideViewSockBodyTop.path("M #{leftMargin.to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 15).to_s} #{leftMargin.to_s} #{(topMargin + cuffHeight).to_s} #{(leftMargin + sockWidth).to_s} #{(topMargin + cuffHeight).to_s} #{(leftMargin + sockWidth).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 65).to_s}")
  end

  sideViewSockBodyBottom = Magick::Draw.new
  sideViewSockBodyBottom.stroke_width(strokeWidth)
  sideViewSockBodyBottom.fill_opacity(0)
  sideViewSockBodyBottom.stroke("black")

  #maskImage is used to draw the diagonal line that splits the pattern between top and bottom for the side view
  #it rotates the pattern, crops it, rotates it back and composites it over the top pattern
  #otherwise the line is straight and the top and bottom split at the wrong place
  maskImage = sockPattern.resize_to_fit(0, sockHeight)
  maskImage.background_color = "none"

  if mediumCC
    sideViewSockBodyBottom.path("M #{(leftMargin + sockWidth - 10).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 80).to_s} #{(leftMargin - 76).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 398).to_s} #{(leftMargin - 215).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 295).to_s} #{leftMargin.to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 12).to_s}")
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight - 10).crop(sockWidth, sockHeight / 2 +10, sockWidth, sockHeight / 2)
    sockPattern2.background_color = "none"
    sockPattern2.rotate!(37.2)
    frontSideBack.composite!(sockPattern2, 261, 550, Magick::OverCompositeOp)

    maskImage.rotate!(-7)
    maskImage = maskImage.crop(173, 393, sockWidth, 47)
    maskImage.rotate!(7)
    frontSideBack.composite!(maskImage, leftMargin-2, sockHeight/2+122, Magick::OverCompositeOp)
  elsif largeCC
    sideViewSockBodyBottom.path("M #{(leftMargin + sockWidth - 14).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 78).to_s} #{(leftMargin - 4.5).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 455).to_s} #{(leftMargin - 161).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 387).to_s} #{leftMargin.to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 12).to_s}")
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight - 20).crop(sockWidth, sockHeight / 2 + 28, sockWidth, sockHeight / 2)
    sockPattern2.background_color = "none"
    sockPattern2.rotate!(23.3)
    frontSideBack.composite!(sockPattern2, 314, 621, Magick::OverCompositeOp)

    maskImage.rotate!(-7)
    maskImage = maskImage.crop(170, 440, sockWidth, 47)
    maskImage.rotate!(7)
    frontSideBack.composite!(maskImage, leftMargin-3, sockHeight/2+119, Magick::OverCompositeOp)
  elsif smallCC
    sideViewSockBodyBottom.path("M #{(leftMargin + sockWidth - 15).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 50).to_s} #{(leftMargin - 27).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 300).to_s} #{(leftMargin - 166).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 196).to_s} #{leftMargin.to_s} #{(topMargin + cuffHeight + sockHeight / 2 - 25).to_s}")
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight).crop(sockWidth, sockHeight / 2 + 28, sockWidth, sockHeight)
    sockPattern2.background_color = "none"
    sockPattern2.rotate!(36.5)
    frontSideBack.composite!(sockPattern2, 291, 422, Magick::OverCompositeOp)

    maskImage.rotate!(-15)
    maskImage = maskImage.crop(165, 271, sockWidth, 47)
    maskImage.rotate!(15)
    frontSideBack.composite!(maskImage, leftMargin-1, sockHeight/2+60, Magick::OverCompositeOp)
  elsif mediumAC
    sideViewSockBodyBottom.path("M #{(leftMargin + sockWidth - 10).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 80).to_s} #{(leftMargin - 76).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 378).to_s} #{(leftMargin - 205).to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 285).to_s} #{leftMargin.to_s} #{(topMargin + cuffHeight + sockHeight / 2 + 15).to_s}")
    sockPattern2 = image.copy.resize(sockWidth * 2, sockHeight - 10).crop(sockWidth, sockHeight / 2 +10, sockWidth, sockHeight / 2)
    sockPattern2.background_color = "none"
    sockPattern2.rotate!(37.2)
    frontSideBack.composite!(sockPattern2, 272, 533, Magick::OverCompositeOp)

    maskImage.rotate!(-7)
    maskImage = maskImage.crop(173, 362, sockWidth, 47)
    maskImage.rotate!(7)
    frontSideBack.composite!(maskImage, leftMargin-2, sockHeight/2+122, Magick::OverCompositeOp)
  end

  sideViewSockBodyTop.draw(frontSideBack)
  sideViewSockBodyBottom.draw(frontSideBack)
  tv_circle.draw(frontSideBack)
  sideViewCuff.draw(frontSideBack)
  sideViewHeel.draw(frontSideBack)

  frontSideBack.write("/tmp/frontSideBack.jpg")

  # PDF words, lines, logos, layout etc
  ############################################
  leftMargin = 50

  contentAlignTop = 1000
  circleSize = 120
  text = Magick::Draw.new
  text.font_family = "helvetica"
  text.pointsize = 40

  copyright = Magick::Draw.new
  copyright.font_family = "helvetica"
  copyright.pointsize = 12

  sockPattern = image
  frontSideBackFile = Magick::ImageList.new("/tmp/frontSideBack.jpg")

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

  #text in top left of each page
  #as well as copyright text bottom center
  text.annotate(pdf1, 0, 0, leftMargin, 160, "#{company.upcase} CUSTOM SOCKS") { self.fill = "black" }
  text.annotate(pdf1, 0, 0, leftMargin, 240, chassis.upcase) { self.fill = "black" }
  text.annotate(pdf1, 0, 0, leftMargin, 320, size.upcase) { self.fill = "black" }
  text.annotate(pdf1, 0, 0, leftMargin, 400, "DESIGN #{designNum}") { self.fill = "black" }
  text.annotate(pdf1, 0, 0, 175, 3200, "Copyright is retained by Custom by Sock Club on all design work including words, pictures, ideas, visuals and illustrations") { self.fill = "#898989" }
  text.annotate(pdf1, 0, 0, 455, 3260, "unless specifically released in writing and after all costs/fees have been paid and settled.") { self.fill = "#898989" }

  text.annotate(pdf2, 0, 0, leftMargin, 160,  "#{company.upcase} CUSTOM SOCKS") { self.fill = "black" }
  text.annotate(pdf2, 0, 0, leftMargin, 240, chassis.upcase) { self.fill = "black" }
  text.annotate(pdf2, 0, 0, leftMargin, 320, size.upcase) { self.fill = "black" }
  text.annotate(pdf2, 0, 0, leftMargin, 400, "DESIGN #{designNum}") { self.fill = "black" }
  text.annotate(pdf2, 0, 0, 175, 3200, "Copyright is retained by Custom by Sock Club on all design work including words, pictures, ideas, visuals and illustrations") { self.fill = "#898989" }
  text.annotate(pdf2, 0, 0, 455, 3260, "unless specifically released in writing and after all costs/fees have been paid and settled.") { self.fill = "#898989" }
  text.gravity(Magick::SouthGravity)

  #makes sure toe, heel, and cuff colors are included in color list if they're not there already
  colors.push(topColor.split.map(&:capitalize).join(" "), heelColor.split.map(&:capitalize).join(" "), toeColor.split.map(&:capitalize).join(" ")).uniq!

  #ensures that plaiting colors will occur last in the circle list so factories can see them easily
  if colors.include?("Black Plaiting")
    colors.insert(-1, colors.delete_at(colors.index("Black Plaiting")))
  elsif colors.include?("White Plaiting")
    colors.insert(-1, colors.delete_at(colors.index("White Plaiting")))
  elsif colors.include?("Grey Plaiting")
    colors.insert(-1, colors.delete_at(colors.index("Grey Plaiting")))
  end

  #on page 2 of the pdf
  #draw a circle for each color that occurs in the bitmap and right the name to the right of it
  #if there's more than 6 colors make 2 columns
  yVal = contentAlignTop + circleSize

  colors.each_with_index do |colorName, i|
    colorName = colorName.split.map(&:downcase).join(" ")
    colorCircle = Magick::Draw.new
    colorCircle.stroke("black")
    colorCircle.fill_color(getHexFromName(colorName))
    colorCircle.stroke_width(strokeWidth)
    colorCircle.stroke_linecap("round")
    colorCircle.stroke_linejoin("round")
    if colors.length > 6
      yVal = contentAlignTop + circleSize if i == 6
      if i < 6
        text.annotate(pdf1, 0, 0, 1350, yVal, colorName.to_s.upcase) { self.fill = "black" }
        colorCircle.ellipse(1200, yVal, circleSize, circleSize, 0, 360)
      else
        text.annotate(pdf1, 0, 0, 1950, yVal, colorName.to_s.upcase) { self.fill = "black" }
        colorCircle.ellipse(1800, yVal, circleSize, circleSize, 0, 360)
      end
    else
      text.annotate(pdf1, 0, 0, 1650, yVal, colorName.to_s.upcase) { self.fill = "black" }
      colorCircle.ellipse(1500, yVal, circleSize, circleSize, 0, 360)
    end

    yVal += 350
    colorCircle.draw(pdf1)
  end

  ################################################################################################

  #write files to tmp filesystem
  #tmp is the only way to store files in lambda, but they only exist for that instance
  pdf1.write("/tmp/page2.jpg")
  pdf2.write("/tmp/page1.jpg")
  flatView.write("/tmp/flatView.png")
  bmp.write("/tmp/bmp.bmp")

  #another bit of code that changes the PDF rendering
  #performs the operation ion both page1 and page2 and makes a imageList from them
  #If the pdf is too large or small or low resolution this is another good place to look
  pdfImageLIst = Magick::ImageList.new("/tmp/page1.jpg", "/tmp/page2.jpg") do
    self.quality = 100
    self.density = "300"
    self.colorspace = Magick::RGBColorspace
    self.interlace = Magick::NoInterlace
  end.each_with_index do |img, i|
    img.resize_to_fit!(612, 828)
  end

  #creates pdf from page1 and page2 imageList
  pdfImageLIst.write("/tmp/images.pdf")


  images = ["/tmp/images.pdf", "/tmp/flatView.png", "/tmp/frontSideBack.jpg", "/tmp/bmp.bmp"]

  #Iterates through each generated image and uploads to s3
  images.each do |filePath|

    #If you're file is named well_fuck, somethings gone wrong
    key = "well_fuck"
    if File.basename(filePath).include?("images")
      key =  "#{baseFileName}_ClientApproved.pdf"
    elsif File.basename(filePath).include?("flatView")
      key = "#{baseFileName}_FlatView.png"
    elsif File.basename(filePath).include?("frontSideBack")
      key = "#{baseFileName}_FBSView.jpg"
    elsif File.basename(filePath).include?("bmp")
      key = "#{baseFileName}.bmp"
    end

    #S3 File upload
    response = s3.put_object(
      :bucket => "account-sockclub-com",
      :key    => "image-generation/#{key}",
      :body   => IO.read(filePath),
    )
  end

  #sock attributes is returned from the lambda
  #this includes things like chassis style, size, colors, pixel pixelCounts
  #all stuff that needs to be submitted to zoho
  return sockAttributes
end

# lambda_handler()
