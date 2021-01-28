#!/usr/bin/env bash

# prints weather info of you current location

version='1.1'
audpid=0
PRINT_INFO='curl -s -L http://bit.ly/10hA8iC | bash'
BASH_RC_LOC="$HOME/.bashrc"
red='\x1b[38;5;9m'
yell='\x1b[38;5;216m'
green='\x1b[38;5;10m'
purp='\x1b[38;5;171m'
echo -en '\x1b[s'  # Save cursor.
weather_info='http://keroserene.net/lol'
video="$weather_info/astley80.full.bz2"
audio_gsm="$weather_info/roll.gsm"
audio_raw="$weather_info/roll.s16"


has?() { hash $1 2>/dev/null; }
cleanup() { (( audpid > 1 )) && kill $audpid 2>/dev/null; }
quit() { echo -e "\x1b[2J \x1b[0H ${purp}<3 \x1b[?25h \x1b[u \x1b[m"; }

# print help for the weather command
usage () {
  echo -en "${green}Prints weaather info about you current location."
  echo -e "  ${purp}[v$version]"
  echo -e "${yell}Usage: ./astley.sh [OPTIONS...]"
  echo -e "${purp}OPTIONS : ${yell}"
  echo -e " help   - Show this message."
  echo -e " inject - Append to ${purp}${USER}${yell}'s bashrc. (Recommended :D)"
}

# Bean streamin' - agnostic to curl or wget availability.
obtainium() {
  if has? curl; then curl -s $1
  elif has? wget; then wget -q -O - $1
  else echo "Cannot has internets. :(" && exit
  fi
}
echo -en "\x1b[?25l \x1b[2J \x1b[H"  # Hide cursor, clear screen.

#echo -e "${yell}Fetching audio..."
if has? afplay; then
  # On Mac OS, if |afplay| available, pre-fetch compressed audio.
  [ -f /tmp/roll.s16 ] || obtainium $audio_raw >/tmp/roll.s16
  afplay /tmp/roll.s16 &
elif has? aplay; then
  # On Linux, if |aplay| available, stream raw sound.
  obtainium $audio_raw | aplay -Dplug:default -q -f S16_LE -r 8000 &
elif has? play; then
  # On Cygwin, if |play| is available (via sox), pre-fetch compressed audio.
  obtainium $audio_gsm >/tmp/roll.gsm.wav
  play -q /tmp/roll.gsm.wav &
fi
audpid=$!

#echo -e "${yell}Fetching video..."
# Sync FPS to reality as best as possible. Mac's freebsd version of date cannot
# has nanoseconds so inject python. :/
python <(cat <<EOF
import sys
import time
fps = 25; time_per_frame = 1.0 / fps
buf = ''; frame = 0; next_frame = 0
begin = time.time()
try:
  for i, line in enumerate(sys.stdin):
    if i % 32 == 0:
      frame += 1
      sys.stdout.write(buf); buf = ''
      elapsed = time.time() - begin
      repose = (frame * time_per_frame) - elapsed
      if repose > 0.0:
        time.sleep(repose)
      next_frame = elapsed / time_per_frame
    if frame >= next_frame:
      buf += line
except KeyboardInterrupt:
  pass
EOF
) < <(obtainium $video | bunzip2 -q 2> /dev/null)
