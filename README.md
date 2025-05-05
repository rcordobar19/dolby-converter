# dolby-converter
Convert Dolby Vision Profile 7 to 8


# Usage:

```
docker build -t dvconverter .
```
Recursively
```
docker run --rm -v /mnt/user/media/movies:/mnt/user/media/movies \
           -v /mnt/user/appdata/dvconverter:/app \
           dvconverter "/mnt/user/media/movies/"
```
Single File

```
docker run --rm -v /mnt/user/media/movies:/mnt/user/media/movies \
           -v /mnt/user/appdata/dvconverter:/app \
           dvconverter "/mnt/user/media/movies/{MOVIE_FOLDER}/"
```
