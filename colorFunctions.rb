#Objects and functions for determing color values for a given pixel

#determines how far away two rgb values are
def color_distance(rgb1,rgb2)
  (rgb1.red - rgb2[0]).abs + (rgb1.green - rgb2[1]).abs + (rgb1.blue - rgb2[2]).abs
end

def getHexFromName(name)
  HexDict[name.downcase]
end

#pick_color_name find the closest rgb value to the one given
#iterates through ColorDict and checks the distance of each one
#if its less the any previous distance, it uses that
def pick_color_name(rgb)
  distance = 1000
  color = ""

  ColorDict.each do |key, value|
    if color_distance(rgb, value) < distance
      color = key
      distance = color_distance(rgb, value)
    end

  end

  return color
end

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
