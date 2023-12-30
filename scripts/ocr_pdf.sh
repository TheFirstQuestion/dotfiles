echo "OCR'ing $1 to $2"
echo
docker run -i --rm jbarlow83/ocrmypdf - - --rotate-pages --deskew --clean --rotate-pages-threshold 2.0 <$1 >$2

# install via: https://ocrmypdf.readthedocs.io/en/latest/docker.html#installing-the-docker-image
