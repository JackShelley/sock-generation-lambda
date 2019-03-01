To push to amazon lambda run in local repository

zip -r function.zip * vendor & aws lambda update-function-code --function-name generate_product_images --zip-file fileb://function.zip
