To push to amazon lambda run in local repository

zip -r function.zip * vendor & aws lambda update-function-code --function-name generate_product_images --zip-file fileb://function.zip


Function is split into 3 files, each with its' own responsibilities
attributeFunctions.rb Defines sock attributes such as chassis style, size, pixel counts, colors, etc.
colorFunctions.rb has the functions for choosing colors from rgb values and data structs of color definitions
lambda_function.rb is the actual lambda function. It controls all the image generation and layout 
