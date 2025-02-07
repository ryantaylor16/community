"""
Applet: Pokedex+
Summary: Pokémon Pokédex
Description: Displays a random Pokedex entry from any generation. This includes its name, image, number, and a scrolling PokeDex entry description. Customizable font color and background color allows users to customize the app to their liking.
Author: Forrest Syrett
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_COLOR = "#000024"
DEFAULT_FONT_COLOR = "#FFFFFF"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.

POKEMON_API = "https://pokeapi.co/api/v2/pokemon/{}"
POKEMON_SPECIES_API = "https://pokeapi.co/api/v2/pokemon-species/{}"

def main(config):
    bgColor = config.str("bgColor", DEFAULT_COLOR)
    fontColor = config.str("fontColor", DEFAULT_FONT_COLOR)

    imageHeight = 36
    imageWidth = 36

    # Generate a random Pokémon ID between 1 and 898
    # staticID for testing layout.
    # random_pokemon_id = str(62)

    # Pokemon Data
    random.seed(time.now().unix // 15)
    random_pokemon_id = random.number(1, 898)
    pokemon = get_pokemon(random_pokemon_id)
    species = get_species(random_pokemon_id)

    pokemonName = pokemon["name"].title()

    pokemonRawFlavorText = ""
    for flavor_entry in species["flavor_text_entries"]:
        if flavor_entry["language"]["name"] == "en":
            pokemonRawFlavorText = flavor_entry["flavor_text"]
            break
    flavor_text = pokemonRawFlavorText.replace("\n", " ")

    # Get the Pokémon sprite. Check if there is an animated version available, if not revert to the default.
    spriteURL = pokemon["sprites"]["versions"]["generation-v"]["black-white"]["animated"]["front_default"]
    if spriteURL == None:
        spriteURL = pokemon["sprites"]["front_default"]
        # Set the animated image size to be slightly smaller so animations don't get cropped.

    else:
        imageHeight = 30
        imageWidth = 30

    pokemonSprite = get_cacheable_data(spriteURL)

    pokemonImage = render.Image(src = pokemonSprite, width = imageWidth, height = imageHeight)

    return render.Root(
        delay = 70,
        child = render.Box(
            child = render.Stack(
                children = [
                    render.Column(
                        children = [
                            render.Marquee(width = 45, child = render.Text(pokemonName, font = "tb-8", color = fontColor)),
                            render.Text("#" + str(random_pokemon_id), font = "6x13", color = fontColor),
                        ],
                        expanded = True,
                        main_align = "start",
                    ),
                    render.Column(
                        children = [
                            render.Marquee(
                                child = render.Text(flavor_text, font = "5x8", color = fontColor),
                                width = 64,
                                offset_start = 32,
                                offset_end = 64,
                            ),
                        ],
                        expanded = True,
                        main_align = "end",
                    ),
                    render.Row(
                        children = [
                            render.Box(width = 28, height = 32),  # used for padding
                            render.Box(child = pokemonImage, width = 30, height = 30, padding = 0),
                        ],
                        expanded = True,
                        main_align = "end",
                    ),
                ],
            ),
            padding = 1,
            color = bgColor,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "bgColor",
                name = "Background Color",
                desc = "The background color of your Pokédex",
                icon = "brush",
                default = DEFAULT_COLOR,
                palette = [
                    "#000019",
                    "#24000D",
                    "#000000",
                ],
            ),
            schema.Color(
                id = "fontColor",
                name = "Font Color",
                desc = "The font color of your Pokédex",
                icon = "brush",
                default = DEFAULT_FONT_COLOR,
                palette = [
                    "#FFFFFF",
                    "#FECA1C",
                ],
            ),
        ],
    )

def get_pokemon(id):
    url = POKEMON_API.format(id)
    data = get_cacheable_data(url)
    return json.decode(data)

def get_species(id):
    url = POKEMON_SPECIES_API.format(id)
    data = get_cacheable_data(url)
    return json.decode(data)

def get_cacheable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    res = http.get(url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
