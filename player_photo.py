import requests as req
from PIL import Image
from io import BytesIO

def get_player_photo(url):
    photo = req.get(url)
    img = Image.open(BytesIO(photo.content))
    return img