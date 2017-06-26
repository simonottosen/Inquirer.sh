#!/bin/bash
set -e
source common.sh

on_text_input_left() {
  remove_regex_failed
  if [ $_current_pos -gt 0 ]; then
    tput cub1
    _current_pos=$(($_current_pos-1))
  fi
}

on_text_input_right() {
  remove_regex_failed
  if [ $_current_pos -lt ${#input} ]; then
    tput cuf1
    _current_pos=$(($_current_pos+1))
  fi
}

on_text_input_enter() {
  remove_regex_failed
  if [[ "$input" =~ $_text_input_regex ]]; then
    tput cub "$(tput cols)"
    tput cuf $((${#_read_prompt}-19))
    printf "${cyan}${input}${normal}"
    tput el
    tput cud1
    tput cub "$(tput cols)"
    tput el
    eval $var_name=\'"${input}"\'
    _break_keypress=true
  else
    _text_input_regex_failed=true
    tput civis
    tput cud1
    tput cub "$(tput cols)"
    tput el
    printf "${red}>>${normal} $_text_input_regex_failed_msg"
    tput cuu1
    tput cub "$(tput cols)"
    tput cuf $((${#_read_prompt}-19))
    tput el
    input=""
    _current_pos=0
    tput cnorm
  fi
}

on_text_input_ascii() {
  remove_regex_failed
  local c=$1

  if [ "$c" = '' ]; then
    c=' '
  fi

  local rest="${input:$_current_pos}"
  input="${input:0:$_current_pos}$c$rest"
  _current_pos=$(($_current_pos+1))

  tput civis
  printf "$c$rest"
  tput el
  if [ ${#rest} -gt 0 ]; then
    tput cub ${#rest}
  fi
  tput cnorm
}

on_text_input_backspace() {
  remove_regex_failed
  if [ $_current_pos -gt 0 ]; then
    local start="${input:0:$(($_current_pos-1))}"
    local rest="${input:$_current_pos}"
    _current_pos=$(($_current_pos-1))
    tput cub 1
    tput civis
    printf "$rest"
    tput el
    input="$start$rest"
    if [ ${#rest} -gt 0 ]; then
      tput cub ${#rest}
    fi
    tput cnorm
  fi
}

remove_regex_failed() {
  if [ $_text_input_regex_failed = true ]; then
    _text_input_regex_failed=false
    tput sc
    tput cud1
    tput cub "$(tput cols)"
    tput el
    tput rc
  fi
}

text_input() {
  prompt=$1
  local var_name=$2
  _text_input_regex="${3:-"\.+"}"
  _text_input_regex_failed_msg=${4:-"Input validation failed"}
  local _read_prompt_start=$'\e[32m?\e[39m\e[1m'
  local _read_prompt_end=$'\e[22m'
  _read_prompt="$( echo "$_read_prompt_start ${prompt} $_read_prompt_end")"
  _current_pos=0
  _text_input_regex_failed=false
  input=""
  printf "$_read_prompt"


  trap control_c SIGINT EXIT

  stty -echo

  on_keypress on_default on_default on_text_input_ascii on_text_input_enter on_text_input_left on_text_input_right on_text_input_ascii on_text_input_backspace
  eval $var_name=\'"${input}"\'
  unset _text_input_regex
  unset _text_input_regex_failed_msg
  unset _read_prompt
  unset _current_pos
  unset input
}
