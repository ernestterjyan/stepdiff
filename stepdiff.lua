-- stepdiff.lua
-- stepdiff v0.5.0
-- Author: Ernest Terjyan
-- Description: LuaLaTeX package for step-by-step derivations with visual diffing.
-- License: MIT
--
-- Token-level visual diffing for the stepdiff LaTeX package.
-- This module deliberately does not understand mathematics. It tokenizes the
-- input as simple LaTeX/math syntax, compares consecutive lines with an LCS
-- algorithm, and wraps changed tokens from the current line in \SDchanged{...}.

local M = {}
local steps = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function strip_tex_sentinels(s)
  -- tex.sprint inserts literal newlines as ordinary character tokens in math
  -- mode, which can render as visible glyphs. Keep emitted TeX one-line.
  return (s or ""):gsub("Ω", ""):gsub("%$", ""):gsub("[\r\n]", " ")
end

local function is_space(c)
  return c:match("%s") ~= nil
end

local function is_letter(c)
  return c:match("%a") ~= nil
end

local function is_digit(c)
  return c:match("%d") ~= nil
end

-- ---------------------------------------------------------------------------
-- Tokenizer
-- ---------------------------------------------------------------------------

local command_group_counts = {
  ["\\frac"] = 2,
  ["\\dfrac"] = 2,
  ["\\tfrac"] = 2,
  ["\\binom"] = 2,
  ["\\sqrt"] = 1,
  ["\\text"] = 1,
  ["\\mathrm"] = 1,
  ["\\mathbf"] = 1,
  ["\\operatorname"] = 1
}

local function_commands = {
  ["\\sin"] = true,
  ["\\cos"] = true,
  ["\\tan"] = true,
  ["\\cot"] = true,
  ["\\sec"] = true,
  ["\\csc"] = true,
  ["\\log"] = true,
  ["\\ln"] = true,
  ["\\exp"] = true
}

local function capture_balanced(s, i, open_char, close_char)
  local depth = 0
  local j = i

  while j <= #s do
    local c = s:sub(j, j)

    if c == "\\" then
      -- Skip escaped single characters while looking for the matching delimiter.
      j = math.min(j + 2, #s + 1)
    else
      if c == open_char then
        depth = depth + 1
      elseif c == close_char then
        depth = depth - 1
        if depth == 0 then
          return s:sub(i, j), j + 1
        end
      end
      j = j + 1
    end
  end

  -- Unbalanced input: return the rest rather than failing hard.
  return s:sub(i), #s + 1
end

local function skip_spaces(s, i)
  while i <= #s and is_space(s:sub(i, i)) do
    i = i + 1
  end
  return i
end

local read_command_token
local read_math_suffixes
local read_atom

local function read_number_token(s, i)
  local j = i
  while j <= #s do
    local c = s:sub(j, j)
    if is_digit(c) or c == "." then
      j = j + 1
    else
      break
    end
  end
  return s:sub(i, j - 1), j
end

local function read_script_argument(s, i)
  if i > #s then
    return "", i
  end

  local text, next_i = read_atom(s, i)
  return text, next_i
end

read_math_suffixes = function(s, text, i)
  while i <= #s do
    local c = s:sub(i, i)

    if c == "'" then
      text = text .. c
      i = i + 1
    elseif c == "^" or c == "_" then
      local op = c
      local arg_start = skip_spaces(s, i + 1)
      local arg, after_arg = read_script_argument(s, arg_start)
      text = text .. op .. s:sub(i + 1, arg_start - 1) .. arg
      i = after_arg
    else
      break
    end
  end

  return text, i
end

read_command_token = function(s, i)
  local j = i + 1

  if j <= #s and is_letter(s:sub(j, j)) then
    while j <= #s and is_letter(s:sub(j, j)) do
      j = j + 1
    end
  elseif j <= #s then
    j = j + 1
  end

  local command = s:sub(i, j - 1)
  local text = command
  local group_limit = command_group_counts[command] or 0

  local k = skip_spaces(s, j)
  if k <= #s and s:sub(k, k) == "[" then
    local opt, after_opt = capture_balanced(s, k, "[", "]")
    text = text .. s:sub(j, k - 1) .. opt
    j = after_opt
    k = skip_spaces(s, j)
  end

  local group_count = 0
  while k <= #s and s:sub(k, k) == "{" and group_count < group_limit do
    local group, after_group = capture_balanced(s, k, "{", "}")
    text = text .. s:sub(j, k - 1) .. group
    j = after_group
    k = skip_spaces(s, j)
    group_count = group_count + 1
  end

  return text, j, command
end

local function read_function_argument(s, i)
  local arg_start = skip_spaces(s, i)
  if arg_start > #s then
    return "", i
  end

  local c = s:sub(arg_start, arg_start)
  if c == "=" or c == "+" or c == "-" or c == ")" or c == "]" or c == "," or c == ";" then
    return "", i
  end

  local arg, after_arg = read_atom(s, arg_start)
  return s:sub(i, arg_start - 1) .. arg, after_arg
end

read_atom = function(s, i)
  local c = s:sub(i, i)
  local text
  local next_i

  if c == "\\" then
    local command
    text, next_i, command = read_command_token(s, i)
    text, next_i = read_math_suffixes(s, text, next_i)

    if function_commands[command] then
      local arg, after_arg = read_function_argument(s, next_i)
      if arg ~= "" then
        text = text .. arg
        next_i = after_arg
      end
    end

    return text, next_i
  elseif c == "{" then
    text, next_i = capture_balanced(s, i, "{", "}")
    return read_math_suffixes(s, text, next_i)
  elseif c == "(" then
    text, next_i = capture_balanced(s, i, "(", ")")
    return read_math_suffixes(s, text, next_i)
  elseif c == "[" then
    text, next_i = capture_balanced(s, i, "[", "]")
    return read_math_suffixes(s, text, next_i)
  elseif is_digit(c) then
    text, next_i = read_number_token(s, i)
    return read_math_suffixes(s, text, next_i)
  elseif is_letter(c) then
    -- Variables remain individual atoms, but scripts/primes stay attached.
    return read_math_suffixes(s, c, i + 1)
  else
    return c, i + 1
  end
end

local function tokenize(s)
  local tokens = {}
  local i = 1
  local leading = ""

  while i <= #s do
    local c = s:sub(i, i)

    if is_space(c) then
      leading = leading .. c
      i = i + 1
    else
      local text, next_i = read_atom(s, i)
      tokens[#tokens + 1] = { text = text, leading = leading }
      leading = ""
      i = next_i
    end
  end

  return tokens
end

-- ---------------------------------------------------------------------------
-- LCS diffing
-- ---------------------------------------------------------------------------

local function lcs_matches(prev, curr)
  local n = #prev
  local m = #curr
  local dp = {}

  for i = 0, n do
    dp[i] = {}
    for j = 0, m do
      dp[i][j] = 0
    end
  end

  for i = 1, n do
    for j = 1, m do
      if prev[i].text == curr[j].text then
        dp[i][j] = dp[i - 1][j - 1] + 1
      else
        dp[i][j] = math.max(dp[i - 1][j], dp[i][j - 1])
      end
    end
  end

  local matched_curr = {}
  local i = n
  local j = m

  while i > 0 and j > 0 do
    if prev[i].text == curr[j].text then
      matched_curr[j] = true
      i = i - 1
      j = j - 1
    elseif dp[i - 1][j] >= dp[i][j - 1] then
      i = i - 1
    else
      j = j - 1
    end
  end

  return matched_curr
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

local weak_tokens = {
  ["+"] = true,
  ["-"] = true,
  ["("] = true,
  [")"] = true,
  ["["] = true,
  ["]"] = true,
  [","] = true,
  [";"] = true
}

local bridge_tokens = {
  ["+"] = true,
  ["-"] = true,
  ["("] = true,
  [")"] = true,
  ["["] = true,
  ["]"] = true
}

local relation_tokens = {
  ["="] = true,
  ["\\le"] = true,
  ["\\ge"] = true,
  ["<"] = true,
  [">"] = true,
  ["\\approx"] = true,
  ["\\sim"] = true,
  ["\\equiv"] = true,
  ["\\Rightarrow"] = true,
  ["\\Longrightarrow"] = true
}

local function is_relation_token(text)
  return relation_tokens[text] == true
end

local function normalize_diff_mode(mode)
  mode = strip_tex_sentinels(mode):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if mode == "false" or mode == "none" then
    return "none"
  elseif mode == "all" then
    return "all"
  end
  return "auto"
end

local function find_alignment_relation(tokens)
  for i, token in ipairs(tokens) do
    if is_relation_token(token.text) then
      return i, token.text
    end
  end

  return nil, nil
end

local function should_highlight_token(index, token, matched, alignment_index)
  if matched == nil or matched[index] then
    return false
  end

  -- The first recognized relation is structural: it is used for alignment.
  if alignment_index == index and is_relation_token(token.text) then
    return false
  end

  return true
end

local function append_changed_chunk(out, chunk)
  if #chunk == 0 then
    return
  end

  local only_weak = true
  for _, token in ipairs(chunk) do
    if not weak_tokens[token.text] then
      only_weak = false
      break
    end
  end

  local first = chunk[1]
  local text = first.text
  for i = 2, #chunk do
    text = text .. chunk[i].leading .. chunk[i].text
  end

  if only_weak then
    out[#out + 1] = first.leading .. text
  else
    out[#out + 1] = first.leading .. "\\SDchanged{" .. text .. "}"
  end
end

local function render_plain_range(tokens, first_index, last_index)
  local out = {}
  for i = first_index, last_index do
    local token = tokens[i]
    out[#out + 1] = token.leading .. token.text
  end
  return table.concat(out)
end

local function render_all_range(tokens, first_index, last_index)
  local plain = render_plain_range(tokens, first_index, last_index)
  if plain == "" then
    return plain
  end
  return "\\SDchanged{" .. plain .. "}"
end

local function build_highlight_flags(
  tokens,
  first_index,
  last_index,
  matched,
  alignment_index
)
  local flags = {}

  for i = first_index, last_index do
    flags[i] = should_highlight_token(i, tokens[i], matched, alignment_index)
  end

  -- If weak punctuation/operator tokens sit between changed atoms, include them
  -- in the same visual chunk. This stays textual: it does not infer meaning.
  for i = first_index + 1, last_index - 1 do
    local token = tokens[i]
    if
      not flags[i]
      and bridge_tokens[token.text]
      and flags[i - 1]
      and flags[i + 1]
    then
      flags[i] = true
    end
  end

  return flags
end

local function render_token_range(tokens, first_index, last_index, matched, alignment_index)
  local out = {}
  local chunk = {}
  local flags = build_highlight_flags(tokens, first_index, last_index, matched, alignment_index)

  for i = first_index, last_index do
    local token = tokens[i]

    if flags[i] then
      chunk[#chunk + 1] = token
    else
      append_changed_chunk(out, chunk)
      chunk = {}
      out[#out + 1] = token.leading .. token.text
    end
  end

  append_changed_chunk(out, chunk)
  return table.concat(out)
end

local function render_reason(reason)
  reason = strip_tex_sentinels(reason)
  if reason == "" then
    return "{}"
  end
  return "\\SDmaybereason{" .. reason .. "}"
end

local function make_step(math, reason, diff_mode)
  math = strip_tex_sentinels(math)
  reason = strip_tex_sentinels(reason)
  diff_mode = normalize_diff_mode(diff_mode or "auto")

  return {
    math = math,
    reason = reason,
    diff_mode = diff_mode,
    tokens = tokenize(math)
  }
end

local function select_render_range(diff_mode)
  if diff_mode == "none" then
    return function(tokens, first_index, last_index)
      return render_plain_range(tokens, first_index, last_index)
    end
  elseif diff_mode == "all" then
    return function(tokens, first_index, last_index)
      return render_all_range(tokens, first_index, last_index)
    end
  end

  return render_token_range
end

local function render_step_body(prev_step, step)
  local matched = nil
  if prev_step ~= nil and step.diff_mode == "auto" then
    matched = lcs_matches(prev_step.tokens, step.tokens)
  end

  local alignment_index, relation_text = find_alignment_relation(step.tokens)
  local render_range = select_render_range(step.diff_mode)

  if alignment_index ~= nil then
    local lhs = render_range(
      step.tokens,
      1,
      alignment_index - 1,
      matched,
      alignment_index
    )
    local rhs = render_range(
      step.tokens,
      alignment_index + 1,
      #step.tokens,
      matched,
      alignment_index
    )
    local relation = relation_text
    if step.diff_mode == "all" then
      relation = "\\SDchanged{" .. relation_text .. "}"
    end
    return lhs .. " & " .. relation .. " " .. rhs
  end

  return render_range(step.tokens, 1, #step.tokens, matched, alignment_index)
    .. " & {}"
end

local function render_latex(step_list)
  local rows = {}

  rows[#rows + 1] = "\\begin{aligned}"

  for i, step in ipairs(step_list) do
    local body = render_step_body(step_list[i - 1], step)
    rows[#rows + 1] = body .. " && " .. render_reason(step.reason)

    if i < #step_list then
      rows[#rows + 1] = "\\\\"
    end
  end

  rows[#rows + 1] = "\\end{aligned}"

  return strip_tex_sentinels(table.concat(rows, " "))
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function M.begin()
  steps = {}
end

function M.add(math, reason, diff_mode)
  steps[#steps + 1] = make_step(math, reason, diff_mode)
end

function M.render()
  local latex = render_latex(steps)
  tex.sprint(latex)
  return latex
end

M._test = {
  strip_tex_sentinels = strip_tex_sentinels,
  tokenize = tokenize,
  lcs_matches = lcs_matches,
  normalize_diff_mode = normalize_diff_mode,
  is_relation_token = is_relation_token,
  find_alignment_relation = find_alignment_relation,
  make_step = make_step,
  render_step_body = render_step_body,
  render_latex = render_latex,
  render_pair = function(prev_math, curr_math, diff_mode)
    local prev_step = nil
    if prev_math ~= nil then
      prev_step = make_step(prev_math, "", "auto")
    end

    local step = make_step(curr_math, "", diff_mode or "auto")
    return render_step_body(prev_step, step)
  end
}

return M
