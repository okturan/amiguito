#!/bin/bash
input=$(cat)

# ═══ PARSE JSON INPUT ═══
CTX_PCT=$(echo "$input" | grep -o '"used_percentage":[0-9]*' | head -1 | grep -o '[0-9]*$')
COST_USD=$(echo "$input" | grep -o '"total_cost_usd":[0-9.]*' | head -1 | sed 's/.*://')
LINES_ADD=$(echo "$input" | grep -o '"total_lines_added":[0-9]*' | head -1 | grep -o '[0-9]*$')
LINES_REM=$(echo "$input" | grep -o '"total_lines_removed":[0-9]*' | head -1 | grep -o '[0-9]*$')
CTX_PCT=${CTX_PCT:-0}
COST_USD=${COST_USD:-0}
LINES_ADD=${LINES_ADD:-0}
LINES_REM=${LINES_REM:-0}
# Integer cost for comparisons
COST_INT=${COST_USD%.*}
COST_INT=${COST_INT:-0}

# ═══ CONFIG ═══
CONF_FILE="$HOME/.claude/amiguito.conf"
BIRTHDAY=""
WEATHER_CITY=""
if [ -f "$CONF_FILE" ]; then
  BIRTHDAY=$(grep '^birthday=' "$CONF_FILE" 2>/dev/null | cut -d= -f2)
  WEATHER_CITY=$(grep '^weather_city=' "$CONF_FILE" 2>/dev/null | cut -d= -f2)
fi

# ═══ COLORS ═══
FB="\033[38;2;215;119;87m"   # fg: clawd_body (orange/terracotta)
BB="\033[48;2;215;119;87m"   # bg: clawd_body
FE="\033[38;2;0;0;0m"        # fg: black (for eyes)
DIM="\033[2m"
R="\033[0m"

# Normal hat colors
HAT_GORRITO="\033[38;2;147;112;219m"
HAT_SOMBRERO="\033[38;2;194;140;60m"
HAT_BOINA="\033[38;2;180;30;30m"
HAT_FIESTA1="\033[38;2;255;200;0m"
HAT_FIESTA2="\033[38;2;255;100;150m"
HAT_MAGO="\033[38;2;80;80;200m"
HAT_MAGO_S="\033[38;2;255;255;100m"

# Seasonal hat colors
HAT_SANTA="\033[38;2;200;30;30m"
HAT_SANTA_W="\033[38;2;255;255;255m"
HAT_WITCH="\033[38;2;50;0;70m"
HAT_WITCH_B="\033[38;2;120;60;170m"
HAT_HEART="\033[38;2;255;50;100m"
HAT_CAKE="\033[38;2;255;180;200m"
HAT_CAKE_C="\033[38;2;255;120;50m"

# Accessory colors
ACC_SCARF="\033[38;2;240;240;240m"
ACC_GLASSES="\033[38;2;100;100;100m"
ACC_BOW="\033[38;2;100;50;180m"
ACC_FLOWER="\033[38;2;255;150;200m"

# Companion colors (single-char friends)
C_BIRD="\033[38;2;255;220;50m"
C_CAT="\033[38;2;170;170;170m"
C_FLOWER="\033[38;2;255;130;180m"
C_STAR="\033[38;2;255;200;50m"
C_FLY="\033[38;2;100;200;80m"

# Bebé clawd colors (mini clawds)
CE="\033[38;2;30;30;30m"
CB_AZUL="\033[38;2;150;190;230m"
BB_AZUL="\033[48;2;150;190;230m"
CB_VERDE="\033[38;2;160;210;140m"
BB_VERDE="\033[48;2;160;210;140m"
CB_ROSA="\033[38;2;230;150;190m"
BB_ROSA="\033[48;2;230;150;190m"
CB_DORADO="\033[38;2;220;190;110m"
BB_DORADO="\033[48;2;220;190;110m"
CB_MORADO="\033[38;2;175;145;215m"
BB_MORADO="\033[48;2;175;145;215m"

# ═══ FRAME STATE ═══
FRAME_FILE="/tmp/amiguito-frame"
FRAME=$(cat "$FRAME_FILE" 2>/dev/null || echo 0)
echo $(( (FRAME + 1) % 10 )) > "$FRAME_FILE"

# ═══ SESSION DURATION ═══
SESSION_FILE="/tmp/amiguito-session-start"
NOW=$(date +%s)
if [ -f "$SESSION_FILE" ]; then
  SESSION_START=$(cat "$SESSION_FILE")
  if [ $(( NOW - SESSION_START )) -gt 28800 ]; then
    echo "$NOW" > "$SESSION_FILE"
    SESSION_START=$NOW
  fi
else
  echo "$NOW" > "$SESSION_FILE"
  SESSION_START=$NOW
fi
SESSION_MINS=$(( (NOW - SESSION_START) / 60 ))

# ═══ TIME & DATE & DAY ═══
HOUR=$((10#$(date +%H)))
MINUTE=$((10#$(date +%M)))
MMDD=$(date +%m%d)
DOW=$(date +%u)  # 1=Monday ... 7=Sunday
DOM=$(date +%d)  # day of month

# ═══ IDLE / SLEEP TRACKING ═══
IDLE_FILE="/tmp/amiguito-last-render"
IDLE_SECS=0
if [ -f "$IDLE_FILE" ]; then
  LAST_RENDER=$(cat "$IDLE_FILE")
  IDLE_SECS=$(( NOW - LAST_RENDER ))
fi
echo "$NOW" > "$IDLE_FILE"
SLEEPING=0
WAKING=0
if [ $IDLE_SECS -ge 300 ]; then
  WAKING=1  # was away for 5+ min
elif [ $HOUR -ge 1 ] && [ $HOUR -lt 6 ] && [ $SESSION_MINS -ge 120 ]; then
  SLEEPING=1  # deep night + long session = sleep mode
fi

# ═══ MOOD ═══
if [ $SESSION_MINS -ge 120 ] || [ $HOUR -lt 6 ] || [ $HOUR -ge 23 ]; then
  MOOD="tired"
elif [ "$DOW" = "1" ] && [ $HOUR -lt 12 ]; then
  MOOD="tired"    # Monday morning blues
elif [ "$DOW" = "5" ] || [ "$DOW" = "6" ] || [ "$DOW" = "7" ]; then
  MOOD="energetic" # Friday-Sunday good vibes
elif [ $SESSION_MINS -lt 15 ] && [ $HOUR -ge 6 ] && [ $HOUR -lt 12 ]; then
  MOOD="energetic"
else
  MOOD="normal"
fi

# ═══ SEASONAL DETECTION ═══
SEASONAL=""
EVENT=""
case "$MMDD" in
  12[2-3][0-9]) SEASONAL="santa" ;;
  102[5-9]|103[01]) SEASONAL="witch" ;;
  0214) SEASONAL="heart" ;;
  0101) SEASONAL="fiesta_ny" ;;
  0314) EVENT="pi_day" ;;
  0229) EVENT="leap_day" ;;
esac

# Friday the 13th override
if [ "$DOW" = "5" ] && [ "$DOM" = "13" ]; then
  SEASONAL="witch"
fi

# Birthday override (takes priority over all!)
if [ -n "$BIRTHDAY" ] && [ "$MMDD" = "$BIRTHDAY" ]; then
  SEASONAL="birthday"
fi

# ═══ SHINY ROLL (1 in 50 chance!) ═══
SHINY=0
if [ $((RANDOM % 50)) -eq 0 ]; then
  SHINY=1
  FB="\033[38;2;255;215;0m"    # gold body
  BB="\033[48;2;255;215;0m"    # gold bg
  FE="\033[38;2;0;0;0m"        # black eyes
fi

# ═══ COMPANION ROLL (1 in 4 chance) ═══
# Bebé eye variation (independent of main amiguito)
if [ $((RANDOM % 4)) -eq 0 ]; then
  BEBE_EYES="--"
else
  BEBE_EYES="··"
fi

COMPANION=""
COMPANION_MSG=""
# Secret 11th companion — 1 in 100!
if [ $((RANDOM % 100)) -eq 0 ]; then
  COMPANION="\033[38;2;255;255;255m\033[5m§${R}"
  COMPANION_MSG="...que fue eso?!"
elif [ $((RANDOM % 4)) -eq 0 ]; then
  case $((RANDOM % 10)) in
    # Single-char friends
    0) COMPANION="${C_BIRD}◇${R}";   COMPANION_MSG="mira un pajarito!" ;;
    1) COMPANION="${C_CAT}ᓚᘏᗢ${R}"; COMPANION_MSG="hola gatico!" ;;
    2) COMPANION="${C_FLOWER}✿${R}"; COMPANION_MSG="que linda flor!" ;;
    3) COMPANION="${C_STAR}☆${R}";   COMPANION_MSG="una estrellita!" ;;
    4) COMPANION="${C_FLY}⋈${R}";    COMPANION_MSG="hola mariposa!" ;;
    # Bebé clawds
    5) COMPANION="${CB_AZUL}▐${CE}${BB_AZUL}${BEBE_EYES}${R}${CB_AZUL}▌${R}";     COMPANION_MSG="hola bebé azul!" ;;
    6) COMPANION="${CB_VERDE}▐${CE}${BB_VERDE}${BEBE_EYES}${R}${CB_VERDE}▌${R}";   COMPANION_MSG="hola bebé verde!" ;;
    7) COMPANION="${CB_ROSA}▐${CE}${BB_ROSA}${BEBE_EYES}${R}${CB_ROSA}▌${R}";     COMPANION_MSG="hola bebé rosa!" ;;
    8) COMPANION="${CB_DORADO}▐${CE}${BB_DORADO}${BEBE_EYES}${R}${CB_DORADO}▌${R}"; COMPANION_MSG="hola bebé dorado!" ;;
    9) COMPANION="${CB_MORADO}▐${CE}${BB_MORADO}${BEBE_EYES}${R}${CB_MORADO}▌${R}"; COMPANION_MSG="hola bebé morado!" ;;
  esac
fi

# ═══ RAINBOW ROLL (1 in 80 chance) ═══
RAINBOW=0
if [ $((RANDOM % 80)) -eq 0 ] && command -v lolcat &>/dev/null; then
  RAINBOW=1
fi

# ═══ ACCESSORY ROLL (1 in 3 chance, independent of hat) ═══
ACCESSORY=""
if [ $((RANDOM % 3)) -eq 0 ]; then
  case $((RANDOM % 4)) in
    0) ACCESSORY="scarf" ;;   # scarf on body line (overlaid)
    1) ACCESSORY="glasses" ;; # glasses on eye line
    2) ACCESSORY="bowtie" ;;  # bowtie on body line
    3) ACCESSORY="flower" ;;  # flower by ear
  esac
fi

# ═══ WEATHER (Open-Meteo, cached, refresh every 30 min) ═══
# City coords: add more as needed
WEATHER_LAT="" WEATHER_LON=""
case "$WEATHER_CITY" in
  Istanbul|istanbul)   WEATHER_LAT="41.01"; WEATHER_LON="28.98" ;;
  Bogota|bogota)       WEATHER_LAT="4.71";  WEATHER_LON="-74.07" ;;
  NYC|nyc)             WEATHER_LAT="40.71"; WEATHER_LON="-74.01" ;;
  London|london)       WEATHER_LAT="51.51"; WEATHER_LON="-0.13" ;;
  Tokyo|tokyo)         WEATHER_LAT="35.68"; WEATHER_LON="139.69" ;;
  Berlin|berlin)       WEATHER_LAT="52.52"; WEATHER_LON="13.41" ;;
esac

WEATHER_ICON=""
W_TEMP=""
WEATHER_CACHE="/tmp/amiguito-weather"
if [ -n "$WEATHER_LAT" ]; then
  CACHE_AGE=9999
  if [ -f "$WEATHER_CACHE" ]; then
    CACHE_TIME=$(stat -f %m "$WEATHER_CACHE" 2>/dev/null || echo 0)
    CACHE_AGE=$(( NOW - CACHE_TIME ))
  fi
  if [ $CACHE_AGE -gt 1800 ]; then
    W=$(curl -s -m 3 "https://api.open-meteo.com/v1/forecast?latitude=${WEATHER_LAT}&longitude=${WEATHER_LON}&current=temperature_2m,weather_code" 2>/dev/null)
    if [ -n "$W" ]; then
      echo "$W" > "$WEATHER_CACHE"
    fi
  fi
  if [ -f "$WEATHER_CACHE" ]; then
    W_CODE=$(grep -o '"weather_code":[0-9]*' "$WEATHER_CACHE" | grep -o '[0-9]*$')
    W_TEMP=$(grep -o '"temperature_2m":[0-9.-]*' "$WEATHER_CACHE" | grep -o '[0-9.-]*$')
    W_TEMP="${W_TEMP%.*}C"
    # WMO weather codes: 0-1=clear, 2-3=cloudy, 45-48=fog, 51-67=rain, 71-77=snow, 80-82=showers, 95-99=storm
    W_CODE=${W_CODE:-0}
    if [ $W_CODE -le 1 ]; then WEATHER_ICON="sunny"
    elif [ $W_CODE -le 3 ]; then WEATHER_ICON="cloudy"
    elif [ $W_CODE -le 48 ]; then WEATHER_ICON="cloudy"
    elif [ $W_CODE -le 67 ]; then WEATHER_ICON="rain"
    elif [ $W_CODE -le 77 ]; then WEATHER_ICON="snow"
    elif [ $W_CODE -le 82 ]; then WEATHER_ICON="rain"
    elif [ $W_CODE -le 99 ]; then WEATHER_ICON="storm"
    fi
  fi
fi

# ═══ MESSAGE POOL ═══
MESSAGES=()

# Time-of-day messages
if [ $HOUR -ge 6 ] && [ $HOUR -lt 12 ]; then
  MESSAGES+=("buenos dias! ☀" "cafe y codigo~" "a empezar bien!")
elif [ $HOUR -ge 12 ] && [ $HOUR -lt 18 ]; then
  MESSAGES+=("dale tu puedes!" "vamos con todo!" "echale ganas!")
elif [ $HOUR -ge 18 ] && [ $HOUR -lt 22 ]; then
  MESSAGES+=("buenas noches~" "que buen dia eh?" "relax y codigo~" "ya casi~")
else
  MESSAGES+=("ya descansa!" "a dormir pronto!" "trasnocho eh?")
fi

# Universal fun messages (always)
MESSAGES+=("du turu ruru~ ♪" "tiki tiki ti~ ♪" "que chevere!" "tu si puedes!" "con toda~" "sigue asi!")

# Day-of-week messages
case $DOW in
  1) MESSAGES+=("lunes con ganas!" "inicio de semana~" "lunes productivo!") ;;
  2) MESSAGES+=("martes con flow~" "dale martes!") ;;
  3) MESSAGES+=("mitad de semana!" "miercoles ya~") ;;
  4) MESSAGES+=("jueves casi viernes" "ya casi viernes!") ;;
  5) MESSAGES+=("viernes de parche!" "viernes al fin! ♪" "viernes vibes~ ♪") ;;
  6) MESSAGES+=("sabado relax~" "finde de codigo~" "sabado chevere!") ;;
  7) MESSAGES+=("domingo chill~" "domingueo y code~" "domingo tranqui~") ;;
esac

# Duration-based messages
if [ $SESSION_MINS -ge 480 ]; then
  MESSAGES+=("8 HORAS DIOS MIO!" "esto es historico!" "duermes o codeas?" "llama a emergencias" "ya ni siento nada~" "olimpiadas de code~")
elif [ $SESSION_MINS -ge 180 ]; then
  MESSAGES+=("esto ya es maraton" "warrior del code~" "eres de hierro!" "modo bestia activado" "ya comiste algo?" "ya viste la hora?!" "necesitas dormir?")
elif [ $SESSION_MINS -ge 60 ]; then
  MESSAGES+=("una horita ya!" "vas super bien!" "dale que dale~" "hacker mode on~" "maquina de codigo!" "focus total!" "agüita?" "estira piernas!")
elif [ $SESSION_MINS -ge 15 ]; then
  MESSAGES+=("buen ritmo!" "calentando motores~" "arrancamos bien!" "que concentracion" "echale ganas!" "sigue asi! ☀")
fi

# Seasonal messages
case "$SEASONAL" in
  santa)     MESSAGES+=("jo jo jo~ ♪" "feliz navidad!" "ho ho codigo~") ;;
  witch)     MESSAGES+=("buu! codigo~" "trick or debug!" "abracadebug!") ;;
  heart)     MESSAGES+=("con mucho amor~" "love y codigo~") ;;
  fiesta_ny) MESSAGES+=("feliz año nuevo!" "año nuevo bugs 0") ;;
esac

# Event messages (no hat change)
case "$EVENT" in
  pi_day)    MESSAGES+=("3.14159265~ ♪" "feliz dia de pi!" "pi pi pi~ ♪") ;;
  leap_day)  MESSAGES+=("29 FEB existe!!" "dia bisiesto! ☀" "cada 4 años esto!") ;;
esac

# ═══ EASTER EGGS ═══
# 11:11 — make a wish
if [ $HOUR -eq 11 ] && [ $MINUTE -eq 11 ]; then
  MESSAGES+=("pide un deseo! ✦" "11:11 magia~ ✦" "✦ pide un deseo! ✦")
fi

# 4:04 — not found
if [ $HOUR -eq 4 ] && [ $MINUTE -eq 4 ]; then
  MESSAGES+=("amiguito not found" "error 404~ ♪" "donde estoy?!")
fi

# Midnight exactly
if [ $HOUR -eq 0 ] && [ $MINUTE -eq 0 ]; then
  MESSAGES+=("hora bruja~ ✦" "medianoche magica!" "✦ mundo dormido ✦")
fi

# ═══ CLAUDE STATE MESSAGES ═══
# Context window awareness
if [ $CTX_PCT -ge 90 ]; then
  MESSAGES+=("cerebro al limite!" "contexto al tope!" "ya casi se llena!")
elif [ $CTX_PCT -ge 70 ]; then
  MESSAGES+=("cerebro llenando~" "contexto llenando~")
elif [ $CTX_PCT -ge 50 ]; then
  MESSAGES+=("medio cerebro usado")
elif [ $CTX_PCT -le 10 ] && [ $CTX_PCT -gt 0 ]; then
  MESSAGES+=("cerebro fresquito~" "todo limpio aqui!")
fi

# Cost milestones
if [ $COST_INT -ge 100 ]; then
  MESSAGES+=("cien dolares de code" "inversion fuerte!")
elif [ $COST_INT -ge 50 ]; then
  MESSAGES+=("50+ invertidos~" "buen billete eh~")
elif [ $COST_INT -ge 20 ]; then
  MESSAGES+=("20+ invertidos~")
fi

# Lines written milestones
if [ $LINES_ADD -ge 1000 ]; then
  MESSAGES+=("mil+ lineas! wow!" "coder serial!")
elif [ $LINES_ADD -ge 500 ]; then
  MESSAGES+=("500+ lineas! ✦" "mucho codigo hoy!")
elif [ $LINES_ADD -ge 100 ]; then
  MESSAGES+=("100+ lineas nuevas~")
fi

# ═══ SLEEP / WAKE MESSAGES ═══
if [ $WAKING -eq 1 ]; then
  MESSAGES+=("*bostezo* hola~" "volvisteee!" "te extrañe!" "donde andabas?")
fi
if [ $SLEEPING -eq 1 ]; then
  MESSAGES+=("z z z z z z z z" "ñam ñam dormido~" "soñando codigo~" "shh estoy durmiendo")
fi

# ═══ BIRTHDAY MESSAGES ═══
if [ "$SEASONAL" = "birthday" ]; then
  MESSAGES+=("FELIZ CUMPLE! ✦✦" "cumple cumple! ♪" "felicidades!! ✦" "torta y codigo! ♪" "que los cumplas! ♪" "un año mas! ✦")
fi

# ═══ WEATHER MESSAGES ═══
case "$WEATHER_ICON" in
  rain)   MESSAGES+=("esta lloviendo~" "lluvia y codigo~" "dia de lluvia!") ;;
  snow)   MESSAGES+=("esta nevando! ✦" "nieve afuera! ✦") ;;
  cloudy) MESSAGES+=("dia nublado~" "nubes afuera~") ;;
  sunny)
    if [ $HOUR -ge 6 ] && [ $HOUR -lt 20 ]; then
      MESSAGES+=("hace sol afuera! ☀" "dia soleado! ☀" "que lindo dia! ☀")
    else
      MESSAGES+=("cielo despejado~" "noche estrellada~ ✦")
    fi ;;
  storm)  MESSAGES+=("tormenta afuera!" "truenos y code!") ;;
esac
if [ -n "$W_TEMP" ]; then
  MESSAGES+=("hace ${W_TEMP} afuera~")
fi

# ═══ ACCESSORY MESSAGES ═══
case "$ACCESSORY" in
  scarf)   MESSAGES+=("que frio! bufanda~") ;;
  glasses) MESSAGES+=("modo intelectual~") ;;
  bowtie)  MESSAGES+=("elegante hoy!") ;;
  flower)  MESSAGES+=("florecita bonita~") ;;
esac

# Rainbow messages
if [ $RAINBOW -eq 1 ]; then
  MESSAGES+=("soy colorful!" "modo arcoiris! ♪" "todos los colores!")
fi

# Shiny messages (only when golden)
if [ $SHINY -eq 1 ]; then
  MESSAGES+=("✦ soy dorado! ✦" "brillo brillo~ ✦" "soy especial!")
fi

# Companion messages (50% chance when companion present)
if [ -n "$COMPANION_MSG" ] && [ $((RANDOM % 2)) -eq 0 ]; then
  MESSAGES+=("$COMPANION_MSG")
fi

# Pick random message
MSG_RAW="${MESSAGES[$((RANDOM % ${#MESSAGES[@]}))]}"

# Pad to 17 visual cols (♪ ☀ ✦ ☆ are single-width in this terminal)
VIS_W=${#MSG_RAW}
PAD_R=$(( 21 - VIS_W ))
if [ $PAD_R -lt 0 ]; then PAD_R=0; fi
RPAD=""; for ((i=0;i<PAD_R;i++)); do RPAD+=" "; done
MSG="${MSG_RAW}${RPAD}"

# ═══ ANIMATION ═══
MOUTH=" "
if [ $SLEEPING -eq 1 ]; then
  # Sleeping: always closed eyes, no mouth
  EYES="${FE}${BB} ─   ─ ${R}"
elif [ $SHINY -eq 1 ]; then
  # Shiny always has star eyes
  EYES="${FE}${BB} ★   ★ ${R}"
else
  case "$MOOD" in
    tired)
      case $(( FRAME % 5 )) in
        0|1|2) EYES="${FE}${BB} ─   ─ ${R}" ;;
        3)     EYES="${FE}${BB} ▗   ▖ ${R}"; MOUTH="~" ;;
        4)     EYES="${FE}${BB} ▗   ▖ ${R}" ;;
      esac ;;
    energetic)
      case $(( FRAME % 5 )) in
        0|1|3) EYES="${FE}${BB} ▗   ▖ ${R}"; MOUTH="‿" ;;
        2|4)   EYES="${FE}${BB} ▗   ▖ ${R}" ;;
      esac ;;
    *)
      case $(( FRAME % 10 )) in
        0|2|5|8) EYES="${FE}${BB} ▗   ▖ ${R}" ;;
        1|4|6|9) EYES="${FE}${BB} ▗   ▖ ${R}"; MOUTH="‿" ;;
        3)       EYES="${FE}${BB} ─   ─ ${R}" ;;
        7)       EYES="${FE}${BB} ▗   ▖ ${R}"; MOUTH="~" ;;
      esac ;;
  esac
fi

# ═══ LAYOUT ═══
pad() { local s=""; for ((i=0;i<$1;i++)); do s+="⠀"; done; echo -n "$s"; }

# Speech bubble via gum (if available) or hand-coded fallback
if command -v gum &>/dev/null; then
  GUM_BOX=$(gum style --border rounded --padding "0 1" "$MSG_RAW")
  B_TOP="${DIM}$(echo "$GUM_BOX" | head -1)${R}"
  GUM_MID=$(echo "$GUM_BOX" | sed -n '2p')
  # DIM the border │ chars but keep message text normal
  B_MID="${DIM}│${R} ${MSG_RAW} ${DIM}│${R}"
  B_BOT="${DIM}$(echo "$GUM_BOX" | tail -1)${R}"
else
  B_TOP="${DIM}╭──────────────────────╮${R}"
  B_MID="${DIM}│${R} ${MSG}${DIM}│${R}"
  B_BOT="${DIM}╰──────────────────────╯${R}"
fi

# Build face with optional glasses accessory
if [ "$ACCESSORY" = "glasses" ]; then
  FACE="${FB}▗${EYES}${FB}▖${ACC_GLASSES}○${R}"
  CONNECTOR="${DIM}°${R}"
else
  FACE="${FB}▗${EYES}${FB}▖${R}"
  CONNECTOR="${DIM}°○${R}"
fi

# Build body with mouth + optional scarf/bowtie/flower
if [ "$ACCESSORY" = "scarf" ]; then
  BODY="⠀${BB}${ACC_SCARF}≈≈≈≈≈≈≈${R}⠀"
elif [ "$ACCESSORY" = "bowtie" ]; then
  BODY="⠀${BB}  ${ACC_BOW}⋈${FE}${MOUTH}${BB}   ${R}⠀"
elif [ "$ACCESSORY" = "flower" ]; then
  BODY="⠀${BB}   ${FE}${MOUTH}${BB}  ${ACC_FLOWER}✿${R}⠀"
else
  BODY="⠀${BB}   ${FE}${MOUTH}${BB}   ${R}⠀"
fi

# Build legs with optional shiny sparkle + companion
LEGS_EXTRA=""
if [ $SHINY -eq 1 ]; then
  LEGS_EXTRA+="⠀\033[38;2;255;215;0m✦${R}"
fi
if [ -n "$COMPANION" ]; then
  LEGS_EXTRA+="⠀${COMPANION}"
fi
LEGS="${FB}⠀⠀▘▘⠀▝▝${R}${LEGS_EXTRA}"

# ═══ DRAW ═══
draw_amiguito() {
if [ -n "$SEASONAL" ]; then
  case "$SEASONAL" in
    santa)
      printf "${HAT_SANTA_W}⠀⠀⠀⠀●${R}$(pad 6)${B_TOP}\n"
      printf "${HAT_SANTA}⠀⠀⠀▄█▄${R}$(pad 5)${B_MID}\n"
      printf "${FACE}${CONNECTOR}${B_BOT}\n"
      printf "${BODY}\n"
      printf "${LEGS}"
      ;;
    witch)
      printf "${HAT_WITCH}⠀⠀⠀⠀▲${R}$(pad 6)${B_TOP}\n"
      printf "${HAT_WITCH_B}⠀⠀▄███▄${R}$(pad 4)${B_MID}\n"
      printf "${FACE}${CONNECTOR}${B_BOT}\n"
      printf "${BODY}\n"
      printf "${LEGS}"
      ;;
    heart)
      printf "${HAT_HEART}⠀⠀⠀⠀♥${R}$(pad 6)${B_TOP}\n"
      printf "${FACE}${CONNECTOR}${B_MID}\n"
      printf "${BODY}$(pad 2)${B_BOT}\n"
      printf "${LEGS}"
      ;;
    fiesta_ny)
      printf "${HAT_FIESTA1}⠀⠀⠀⠀★${R}$(pad 6)${B_TOP}\n"
      printf "${HAT_FIESTA2}⠀⠀⠀▄█▄${R}$(pad 5)${B_MID}\n"
      printf "${FACE}${CONNECTOR}${B_BOT}\n"
      printf "${BODY}\n"
      printf "${LEGS}"
      ;;
    birthday)
      printf "${HAT_CAKE_C}⠀⠀⠀⠀▴${R}$(pad 6)${B_TOP}\n"
      printf "${HAT_CAKE}⠀⠀⠀▄█▄${R}$(pad 5)${B_MID}\n"
      printf "${FACE}${CONNECTOR}${B_BOT}\n"
      printf "${BODY}\n"
      printf "${LEGS}"
      ;;
  esac
else
  HAT_IDX=$(( (FRAME / 2) % 5 ))
  case $HAT_IDX in
    0) printf "${HAT_GORRITO}⠀⠀⠀▄█▄${R}$(pad 5)${B_TOP}\n"
       printf "${FACE}${CONNECTOR}${B_MID}\n"
       printf "${BODY}$(pad 2)${B_BOT}\n"
       printf "${LEGS}" ;;
    1) printf "${HAT_SOMBRERO}⠀⠀⠀▄█▄${R}$(pad 5)${B_TOP}\n"
       printf "${HAT_SOMBRERO}⠀▄█████▄${R}$(pad 3)${B_MID}\n"
       printf "${FACE}${CONNECTOR}${B_BOT}\n"
       printf "${BODY}\n"
       printf "${LEGS}" ;;
    2) printf "${HAT_BOINA}⠀⠀▄███▄${R}$(pad 4)${B_TOP}\n"
       printf "${FACE}${CONNECTOR}${B_MID}\n"
       printf "${BODY}$(pad 2)${B_BOT}\n"
       printf "${LEGS}" ;;
    3) printf "${HAT_FIESTA1}⠀⠀⠀⠀★${R}$(pad 6)${B_TOP}\n"
       printf "${HAT_FIESTA2}⠀⠀⠀▄█▄${R}$(pad 5)${B_MID}\n"
       printf "${FACE}${CONNECTOR}${B_BOT}\n"
       printf "${BODY}\n"
       printf "${LEGS}" ;;
    4) printf "${HAT_MAGO}⠀⠀⠀▄█▄${R}$(pad 5)${B_TOP}\n"
       printf "${HAT_MAGO}⠀⠀${HAT_MAGO_S}✦${HAT_MAGO}███${HAT_MAGO_S}✦${R}$(pad 4)${B_MID}\n"
       printf "${FACE}${CONNECTOR}${B_BOT}\n"
       printf "${BODY}\n"
       printf "${LEGS}" ;;
  esac
fi
}

# Output (rainbow or normal)
if [ $RAINBOW -eq 1 ]; then
  draw_amiguito | lolcat -f -t 2>/dev/null || draw_amiguito
else
  draw_amiguito
fi
