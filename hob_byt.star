load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("time.star", "time")
load("encoding/json.star", "json")

BASE_URL = "https://the-one-api.dev/v2"
MOVIES_URL = BASE_URL + "/movie"
QUOTE_URL = MOVIES_URL + "/%s/quote"
CHARACTER_URL = BASE_URL + "/character/%s"
AUTH_HEADERS = {"Authorization" : "Bearer {add token here}"}

KEY_MOVIES = "movies"
KEY_QUOTES = "quotes"

JSON_KEY_ID = "_id"

def main():
  quote, movie = get_quote_and_movie()
  print(quote["dialog"])
  print(movie["name"])

  character = get_list_item_from_url_or_cache(quote["character"], CHARACTER_URL % quote["character"])
  print(character)

  return render.Root(
    child = render.Column(
      expanded = True,
      main_align = "space_evenly",
      children = [
        render.Marquee(
          child = render.Text(
            content = quote["dialog"],
            font = "6x13"),
          width = 64,
          scroll_direction = "horizontal"
        ),
        render.Marquee(
          child = render.Text(
            content = "-" + character["name"],
            color = "#099"),
          width = 64,
          scroll_direction = "horizontal"
        ),
        render.Marquee(
          child = render.Text(
            content = "-" + movie["name"],
            color = "#fa0"),
          width = 64,
          scroll_direction = "horizontal"
        )
      ]
    )
  )

def get_quote_and_movie():
  movie = get_list_item_from_url_or_cache(KEY_MOVIES, MOVIES_URL)
  if movie == None:
    return None

  quote = get_list_item_from_url_or_cache(KEY_QUOTES + movie[JSON_KEY_ID], QUOTE_URL % movie[JSON_KEY_ID])
  if quote == None:
    return get_quote_and_movie()

  return quote, movie

def get_list_item_from_url_or_cache(cache_key, url):
  items_cached = cache.get(cache_key)
  if items_cached != None:
    items = json.loads(items_cached)
  else:
    print(url)
    rep = http.get(url, headers=AUTH_HEADERS)
    if rep.status_code != 200:
      fail("the-one-api request failed with status %d", rep.status_code)
      return None

    items = rep.json()["docs"]
    cache.set(cache_key, json.dumps(items), ttl_seconds=1240)

  if len(items) == 0:
    return None

  seed = time.now().nanosecond()
  x, seed = random(seed)

  return items[int((x * len(items)) // 1)]

def random(seed):
    """
    Returns a random number and the new seed value.

    Starlark is meant to be deterministic, so anything that made the language non-deterministic (such as random number
    generators) was removed. This is a Python implementation of a linear congruential generator I found here:
    http://www.cs.wm.edu/~va/software/park/park.html
    """
    modulus = 2147483648
    multiplier = 48271

    q = modulus / multiplier
    r = modulus % multiplier
    t = multiplier * (seed % q) - r * (seed / q);

    if t > 0:
        seed = t
    else:
        seed = t + modulus

    return float(seed / modulus), seed
