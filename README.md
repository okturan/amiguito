# amiguito ✦

a tiny animated companion for your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) status line.

![amiguito demo](demo.gif)

## what is this?

amiguito is a little character that lives in the bottom of your Claude Code terminal. it reacts to what you're doing - time of day, how long you've been coding, the weather outside, your birthday, and more.

built entirely in bash with unicode art and ANSI colors. no dependencies required (optional ones make it prettier).

## features

- **5 rotating hats** - gorrito, sombrero, boina, fiesta, mago
- **seasonal hats** - santa (dec), witch (oct/friday 13th), heart (feb 14), new year (jan 1), birthday cake
- **animated expressions** - blinks, smiles, sleepy eyes based on mood
- **100+ spanish messages** - time-aware, day-aware, session-duration-aware
- **companions** - 1 in 4 chance a friend appears (bird, cat, butterfly, flower, star, or a bebé clawd)
- **secret companion** - 1 in 100 chance of the mysterious §
- **shiny mode** - 1 in 50 chance of golden amiguito ✦
- **rainbow mode** - 1 in 80 chance (requires `lolcat`)
- **accessories** - glasses, bowtie, flower, scarf
- **weather** - shows real weather from [Open-Meteo](https://open-meteo.com/) (free, no API key)
- **claude state awareness** - reacts to context window usage, cost milestones, lines written
- **sleep/wake detection** - knows when you've been away
- **birthday mode** - cake hat + special messages on your birthday
- **easter eggs** - 11:11 wishes, 4:04 not found, midnight magic, pi day, leap day
- **auto-sizing speech bubbles** (requires `gum`)

## install

```bash
git clone https://github.com/okturan/amiguito.git
cd amiguito
bash install.sh
```

then restart Claude Code.

## configure

edit `~/.claude/amiguito.conf`:

```
# your birthday (MMDD format)
birthday=0315

# your city for weather (Istanbul, Bogota, NYC, London, Tokyo, Berlin)
weather_city=Istanbul
```

## optional dependencies

```bash
brew install gum lolcat
```

- **gum** - auto-sizing speech bubbles (without it, uses fixed-width fallback)
- **lolcat** - enables the rare rainbow mode

## how it works

Claude Code's [status line](https://docs.anthropic.com/en/docs/claude-code/status-line) runs a shell command after each assistant message. the command receives JSON on stdin with session data (context window %, cost, lines written) and outputs ANSI-colored text.

amiguito is a ~570-line bash script that:
1. parses the JSON input for Claude state
2. checks time, date, season, weather, session duration
3. rolls for rare events (shiny, rainbow, companions, accessories)
4. picks a contextual message from a pool of 100+
5. renders the character with unicode block elements and 24-bit ANSI colors

## credits

made with claude code, unicode art, and love. all messages are in spanish because amiguito speaks spanish.

## license

MIT
