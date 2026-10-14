#!/bin/bash
# Greengo — a little green cowboy robot for Claude Code. Yeehaw.
#
#   greengo.sh hook             called by Claude Code hooks (event JSON on stdin)
#   greengo.sh status           called by the status line (session JSON on stdin)
#   greengo.sh name <name>      rename the robot
#   greengo.sh color <color>    recolor it (green, cyan, yellow, red, blue, magenta, white, orange, pink, gray)
#   greengo.sh hat on|off       wear the boater or go bareheaded (one line instead of two)
#   greengo.sh hide | show      tuck it away / bring it back
#   greengo.sh stats            lifetime stats
#
# Pure bash 3.2 + grep/sed, so it runs on a stock Mac with nothing to install.

GG_DIR="${GG_DIR:-$HOME/.claude/greengo}"
CONFIG="$GG_DIR/config"
mkdir -p "$GG_DIR/state" 2>/dev/null

# ---------- config ----------
NAME="Greengo"; COLOR="green"; HIDDEN="0"; HAT="1"
[ -f "$CONFIG" ] && . "$CONFIG" 2>/dev/null

save_config() {
  printf 'NAME=%q\nCOLOR=%q\nHIDDEN=%q\nHAT=%q\n' "$NAME" "$COLOR" "$HIDDEN" "$HAT" > "$CONFIG"
}

# ---------- tiny JSON helpers (no jq needed) ----------
# Input is flattened to one line; these pull the first "key": "string" or "key": number.
json_str() {
  printf '%s' "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
}
json_num() {
  printf '%s' "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9.]*" | head -1 \
    | sed "s/^\"$1\"[[:space:]]*:[[:space:]]*//"
}
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
pick() { local n=$#; local i=$(( RANDOM % n + 1 )); eval "printf '%s' \"\${$i}\""; }
safe_id() { printf '%s' "$1" | tr -cd 'A-Za-z0-9_-'; }

# Greengo's faces (the 3 characters between his brackets). Each mood draws one at
# random when it starts, so he isn't always the same cowboy. Add your own here.
face_for() {
  case "$1" in
    boot)   pick "•ᴗ•" "¬‿¬" "-_•" "•_•" ;;           # friendly, smirk, squinty nod
    listen) pick "•_•" "≖_≖" "¬_¬" "-_•" "•ᴗ•" ;;     # listenin' close, sizin' you up
    blush)  pick "≧ᴗ≦" "¬‿¬" "-‿-" ;;                 # aw shucks, smug, content
    work)   pick "•_•" "≖_≖" "ò_ó" "-_•" "¬_¬" "•ᴗ•" ;;  # focused, gunslinger squint, gritty
    wait)   pick "¬_¬" "¬_¬" "•_•" "≖_≖" ;;           # stone cold (with a cigarillo)
    happy)  pick "^ᴗ^" "¬‿¬" "-‿-" "¬‿¬" ;;           # rare grin, mostly a smug smirk
    error)  pick "ò_ó" "×_×" "-_-" "ó_ò" ;;           # rough, KO'd, unimpressed, worried
    *)      printf '%s' "•_•" ;;
  esac
}

set_state() {  # set_state <mood> <text>   (state file: mood|time|face|text)
  printf '%s|%s|%s|%s\n' "$1" "$(date +%s)" "$(face_for "$1")" "$2" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
}
bump() {  # bump a counter file by +1 (or by $2)
  local f="$GG_DIR/$1" n=0
  [ -f "$f" ] && n=$(cat "$f" 2>/dev/null)
  case "$n" in ''|*[!0-9-]*) n=0 ;; esac
  n=$(( n + ${2:-1} )); [ "$n" -lt 0 ] && n=0
  echo "$n" > "$f"
}

# ---------- hook mode: turn events into moods ----------
do_hook() {
  INPUT=$(cat | tr '\n' ' ')
  SID=$(safe_id "$(json_str session_id)"); [ -z "$SID" ] && SID="default"
  STATE="$GG_DIR/state/$SID"
  EVENT=$(json_str hook_event_name)

  # Every state has a whole herd of lines, picked at random each time.
  # Add your own: just append another "quoted line" to any pick list.
  case "$EVENT" in
    SessionStart)
      echo 0 > "$GG_DIR/state/$SID.horses"
      bump sessions
      set_state boot "$(pick \
        "howdy, partner! 🤠" \
        "there's a new sheriff in town ⭐" \
        "badges? we don't need no stinkin' badges ⭐" \
        "I'm your huckleberry 🤠" \
        "once upon a time in the codebase… 🌵" \
        "mornin', pilgrim 🤠" \
        "saddlin' up…" \
        "the stagecoach has arrived 🐎" \
        "this town needs a marshal ⭐")" ;;

    UserPromptSubmit)
      P=$(lower "$(json_str prompt)")
      case "$P" in
        *please*|*thank*|*danke*|*bitte*)
          set_state blush "$(pick \
            "much obliged 🤠" \
            "aw, shucks 💚" \
            "right kind of ya 💚" \
            "mighty fine manners, partner 🎩" \
            "a gentleman and a scholar 💚" \
            "you're a real straight shooter 💚")" ;;
        *)
          set_state listen "$(pick \
            "readin' the wanted poster… 📜" \
            "I'm your huckleberry" \
            "say when, partner" \
            "head 'em up, move 'em out 🐄" \
            "you got it, pilgrim" \
            "let's ride 🐎" \
            "fixin' to get started…" \
            "consider it done, boss ⭐")" ;;
      esac ;;

    PreToolUse)
      bump chores
      TOOL=$(json_str tool_name)
      F=$(json_str file_path); F="${F##*/}"
      case "$TOOL" in
        Read)
          set_state work "$(pick "readin' ${F:-the map} 📜" "studyin' the map: ${F:-the code} 🗺️" "squintin' at ${F:-the fine print} 🔭" "sizin' up ${F:-the stranger} 🤨" "checkin' ${F:-the file} for outlaws 🔍")" ;;
        Edit|MultiEdit)
          set_state work "$(pick "patchin' up ${F:-the code} 🔨" "wranglin' ${F:-the code} 🪢" "it's high noon for ${F:-this bug} 🕛" "reshoein' ${F:-the horse} 🔨" "brandin' ${F:-the herd} 🔥" "fixin' fences in ${F:-the code} 🔨")" ;;
        Write)
          set_state work "$(pick "writin' up ${F:-a new file} 📝" "stakin' a claim: ${F:-new file} ⛏️" "buildin' a homestead: ${F:-new file} 🏠" "foundin' a new town: ${F:-new file} 🏘️")" ;;
        NotebookEdit)
          set_state work "$(pick "scribblin' in the notebook 📓" "updatin' the trail journal 📓")" ;;
        Grep|Glob|LS)
          set_state work "$(pick "trackin' through the code 🐾" "followin' the tracks 🐾" "scoutin' the territory 🔭" "pannin' for gold ⛏️" "searchin' every saloon in town 🔍")" ;;
        WebSearch)
          set_state work "$(pick "ridin' out to the web 🐎" "askin' around town 🍻" "pony express to the web 🐎" "checkin' the wanted posters 📜")" ;;
        WebFetch)
          set_state work "$(pick "fetchin' word from town 🐎" "checkin' the telegraph 📨" "waitin' on the stagecoach 📬")" ;;
        Task|Agent)
          set_state work "$(pick "roundin' up a posse 🐎" "who are those guys? 🐎" "the magnificent seven, ridin' out 🐎" "deputizin' a helper ⭐" "sendin' out scouts 🔭")" ;;
        TodoWrite|TaskCreate|TaskUpdate)
          set_state work "$(pick "markin' the trail map 🗺️" "plannin' the cattle drive 🐄" "drawin' up the battle plan 📋")" ;;
        Bash|PowerShell)
          CMD=$(lower "$(json_str command)")
          case "$CMD" in
            *test*|*jest*|*vitest*|*pytest*)
              set_state work "$(pick "testin' the herd 🧪" "high noon for the tests 🕛" "the good, the bad and the buggy 🧪" "countin' the cattle 🐄" "fastest tests in the west 🧪")" ;;
            *"git commit"*)
              set_state work "$(pick "signin' the ledger ✍️" "carvin' it in the saloon wall ✍️" "for a few commits more ✍️" "puttin' it on the record ✍️")" ;;
            *"git push"*)
              set_state work "$(pick "ridin' off to the remote 🌄" "tell 'em I'm comin' 🌄" "catchin' the 3:10 to origin 🚂" "headin' west 🌄")" ;;
            *git*)
              set_state work "$(pick "checkin' the trail 🌿" "readin' the tracks 🌿" "consultin' the old-timers 🌿")" ;;
            *install*|*" add "*)
              set_state work "$(pick "loadin' the wagon 📦" "stockin' up at the general store 📦" "a fistful of dependencies 📦")" ;;
            *build*)
              set_state work "$(pick "raisin' the barn 🏗️" "layin' the railroad 🚂" "buildin' the town 🏗️")" ;;
            *lint*|*format*|*prettier*)
              set_state work "$(pick "polishin' the spurs ✨" "shinin' the badge ⭐" "dustin' off the boots ✨")" ;;
            *rm\ *)
              set_state work "$(pick "sweepin' the saloon 🧹" "think I used enough dynamite? 🧨" "runnin' it outta town 🧹")" ;;
            *)
              set_state work "$(pick "workin' the ranch ⚙️" "doin' chores ⚙️" "fixin' fences 🔧" "shoein' horses 🔨")" ;;
          esac ;;
        mcp__*)
          S=${TOOL#mcp__}; S=${S%%__*}
          set_state work "$(pick "wirin' a telegram to $S 📨" "pony express to $S 🐎" "parleyin' with $S 🤝")" ;;
        *)
          set_state work "usin' ${TOOL:-a tool} 🔧" ;;
      esac ;;

    PostToolUseFailure)
      set_state error "$(pick \
        "well, shoot 🌵" \
        "got bucked off ⚠️" \
        "dagnabbit ⚠️" \
        "what in tarnation? ⚠️" \
        "ambushed! ⚠️" \
        "remember the Alamo ⚠️" \
        "that went south fast 🌵" \
        "deserve's got nothin' to do with it ⚠️" \
        "the bad and the ugly ⚠️")" ;;

    Notification)
      case "$(json_str notification_type)" in
        idle_prompt)
          set_state wait "$(pick "yer move, partner 🎲" "say when 🤠" "the trail's gone quiet 🌵" "waitin' at the saloon 🍻" "draw, partner! yer turn 🎲")" ;;
        *)
          set_state wait "$(pick \
            "hold yer horses, need yer say-so ✋" \
            "call it, friendo 🪙" \
            "fill yer hand, partner ✋" \
            "yer call, sheriff ⭐" \
            "badges? I'll need yours for this one ⭐" \
            "permission to ride, boss? 🐎")" ;;
      esac ;;

    SubagentStart) bump "state/$SID.horses" 1 ;;
    SubagentStop)  bump "state/$SID.horses" -1 ;;

    Stop)
      set_state happy "$(pick \
        "yeehaw! job's done ✅" \
        "that's a wrap, partner ✅" \
        "ridin' off into the sunset 🌅" \
        "happy trails ✅" \
        "this town's cleaned up ✅" \
        "another bug bites the dust 🌵" \
        "the good, the bad and the shipped ✅" \
        "mission accomplished, marshal ⭐" \
        "fastest code in the west ✅")" ;;

    StopFailure)
      set_state error "$(pick "the stagecoach broke down ⚠️" "the telegraph lines are down ⚠️" "bandits hit the stagecoach ⚠️")" ;;
    PreCompact)
      set_state work "$(pick "packin' the saddlebags 🧹" "travelin' light 🎒" "tossin' out the old maps 🧹")" ;;

    SessionEnd)  rm -f "$STATE" "$GG_DIR/state/$SID.horses" ;;
  esac

  find "$GG_DIR/state" -type f -mmin +1440 -delete 2>/dev/null
  exit 0
}

# ---------- status mode: draw the cowboy ----------
do_status() {
  INPUT=$(cat | tr '\n' ' ')
  [ "$HIDDEN" = "1" ] && exit 0
  SID=$(safe_id "$(json_str session_id)"); [ -z "$SID" ] && SID="default"
  STATE="$GG_DIR/state/$SID"

  MOOD="idle"; TS=$(date +%s); FK=""; TEXT="standin' guard"
  [ -f "$STATE" ] && IFS='|' read -r MOOD TS FK TEXT < "$STATE"
  NOW=$(date +%s); AGE=$(( NOW - ${TS:-$NOW} ))
  T=$(( NOW % 2 )); T4=$(( NOW % 4 ))
  HOUR=$(date +%H); HOUR=${HOUR#0}
  NIGHT=0; { [ "$HOUR" -ge 23 ] || [ "$HOUR" -lt 5 ]; } && NIGHT=1

  # Settle down after a while; nap after 90 quiet seconds.
  case "$MOOD" in
    happy|boot|blush|idle|listen) [ "$AGE" -gt 90 ] && MOOD="sleep" ;;
    error) [ "$AGE" -gt 30 ] && MOOD="idle" && TEXT="all clear" ;;
  esac
  case "$MOOD" in happy|blush) [ "$AGE" -gt 20 ] && MOOD="idle" && TEXT="standin' guard" ;; esac
  case "$MOOD" in idle|sleep) FK="" ;; esac
  [ -z "$FK" ] && FK="•_•"

  # Every face keeps the 5-character head [xxx] in columns 1-5, right under the hat's crown.
  TIP=0
  SMOKE="╾~"; [ $T -eq 1 ] && SMOKE="╾ ~"
  case "$MOOD" in
    work)   if [ $T -eq 0 ]; then FACE="┌[$FK]┘~◯"; else FACE="└[$FK]┐~○"; fi ;;
    listen) FACE=" [$FK]"; [ $T4 -eq 0 ] && FACE=" [-_-]" ;;
    happy)  if [ "$FK" = "^ᴗ^" ]; then
              if [ $T -eq 0 ]; then FACE="\\[^ᴗ^]/"; else FACE=" [^ᴗ^]/★"; TIP=1; fi
            else FACE=" [$FK]/"; TIP=$T; fi ;;
    blush)  FACE=" [$FK]"; TIP=$T ;;
    boot)   FACE=" [$FK]/"; TIP=$T ;;
    error)  FACE=" [$FK]"
            [ "$FK" = "ò_ó" ] && [ $T -eq 1 ] && FACE=" [ó_ò]" ;;
    wait)   if [ "$FK" = "¬_¬" ]; then FACE=" [¬_¬]$SMOKE"          # stone cold, cigarillo
            elif [ $T -eq 0 ]; then FACE=" [$FK]?"; else FACE=" [$FK]!"; fi ;;
    sleep)  if [ $NIGHT -eq 1 ]; then FACE=" [=_=]"; else FACE=" [-_-]"; fi
            # Mostly snoring, with a bit of sleep-talk now and then.
            if [ $(( (NOW / 6) % 4 )) -eq 3 ]; then
              set -- "dreamin' of tumbleweeds 🌵" "countin' sheep… er, cattle 🐄" "Shane… come back… 💤" \
                     "campfire's out 🔥" "mmm… beans… 💤" "sleepin' under the stars ✨"
              i=$(( (NOW / 24) % $# + 1 )); eval "TEXT=\${$i}"
            else
              case $(( NOW % 3 )) in 0) TEXT="z";; 1) TEXT="zZ";; 2) TEXT="zZz";; esac
            fi ;;
    *)      # Idle: a new face every 30 seconds, weary ones late at night, blinking now and then.
            if [ $NIGHT -eq 1 ]; then set -- "´-\`" "=_=" "-_•" "´-\`" "¬_¬"
            else set -- "•_•" "¬_¬" "≖_≖" "-_•" "¬_¬" "•ᴗ•" "´-\`"; fi
            i=$(( (NOW / 30) % $# + 1 )); eval "FK=\${$i}"
            FACE=" [$FK]"
            [ "$FK" = "¬_¬" ] && FACE=" [¬_¬]$SMOKE"
            [ $T4 -eq 0 ] && FACE=" [-_-]"
            if [ "$TEXT" = "standin' guard" ]; then
              set -- "standin' guard" "whittlin' 🪵" "keepin' watch 🔭" "chewin' on a straw 🌾" \
                     "spurs a-jinglin'" "leanin' on the hitchin' post" "watchin' the tumbleweeds 🌵"
              [ $NIGHT -eq 1 ] && set -- "long day, partner" "burnin' the midnight oil 🕯️" \
                     "one more and then bed…" "keepin' watch 🔭" "the saloon's closin' 🍻"
              i=$(( (NOW / 20) % $# + 1 )); eval "TEXT=\${$i}"
            fi ;;
  esac

  case "$(lower "$COLOR")" in
    red) C='\033[31m';; cyan) C='\033[36m';; yellow) C='\033[33m';; blue) C='\033[34m';;
    magenta|purple) C='\033[35m';; white) C='\033[97m';; gray|grey) C='\033[90m';;
    orange) C='\033[38;5;208m';; pink) C='\033[38;5;213m';; *) C='\033[32m';;
  esac
  [ "$MOOD" = "error" ] && C='\033[31m'
  STRAW='\033[38;5;223m'; UL='\033[4m'; D='\033[2m'; R='\033[0m'

  # A little horse for each subagent out ridin'.
  HORSES=""
  N=0; [ -f "$STATE.horses" ] && N=$(cat "$STATE.horses" 2>/dev/null)
  case "$N" in ''|*[!0-9]*) N=0 ;; esac
  [ "$N" -gt 5 ] && N=5
  i=0; while [ $i -lt "$N" ]; do
    if [ $(( (NOW + i) % 2 )) -eq 0 ]; then HORSES="$HORSES ♞"; else HORSES="$HORSES  ♞"; fi
    i=$(( i + 1 ))
  done

  # Context window as a little battery.
  PCT=$(json_num used_percentage); PCT=${PCT%%.*}; [ -z "$PCT" ] && PCT=0
  CELLS=$(( (PCT + 10) / 20 )); [ "$CELLS" -gt 5 ] && CELLS=5
  BAR=""; i=0
  while [ $i -lt 5 ]; do
    if [ $i -lt "$CELLS" ]; then BAR="${BAR}▰"; else BAR="${BAR}▱"; fi
    i=$(( i + 1 ))
  done
  if   [ "$PCT" -ge 85 ]; then BC='\033[31m'
  elif [ "$PCT" -ge 60 ]; then BC='\033[33m'
  else BC='\033[32m'; fi

  # The boater: a half-height square crown sitting on one underlined brim line.
  if [ "$HAT" != "0" ]; then
    PAD=""; [ "$TIP" = "1" ] && PAD=" "
    printf '%b' "${STRAW}${PAD}${UL} ┌───┐ ${R}\n"
  fi
  BATT="  ${D}🔋${R}${BC}${BAR}${R}${D} ${PCT}%${R}"
  [ -n "$GG_NO_BATTERY" ] && BATT=""     # the VS Code extension has no context meter to show
  printf '%b' "${C}${FACE}${R} ${C}${NAME}${R} ${TEXT}${C}${HORSES}${R}${BATT}\n"
  exit 0
}

# ---------- commands ----------
case "$1" in
  hook)   do_hook ;;
  status) do_status ;;
  name)   shift; [ -n "$*" ] && NAME="$*"; save_config; echo "Howdy, the name's $NAME now. 🤠" ;;
  color|colour)
          COLOR=$(lower "$2")
          case "$COLOR" in
            green|cyan|red|yellow|blue|magenta|purple|white|gray|grey|orange|pink) save_config; echo "$NAME is ridin' in $COLOR now. ✨" ;;
            *) echo "Pick one of: green cyan yellow red blue magenta white gray orange pink"; exit 1 ;;
          esac ;;
  hat)    case "$2" in
            off) HAT=0; save_config; echo "$NAME hung up the hat. 🪝" ;;
            *)   HAT=1; save_config; echo "$NAME put the boater back on. 🤠" ;;
          esac ;;
  hide)   HIDDEN=1; save_config; echo "$NAME rode off for now. (greengo.sh show brings him back)" ;;
  show)   HIDDEN=0; save_config; echo "$NAME is back in the saddle! 🤠" ;;
  stats)
          C1=$(cat "$GG_DIR/chores" 2>/dev/null || echo 0)
          C2=$(cat "$GG_DIR/sessions" 2>/dev/null || echo 0)
          echo "🤠 $NAME ($COLOR) · $C2 rides together · $C1 chores wrangled" ;;
  *)      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
