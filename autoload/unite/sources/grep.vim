"=============================================================================
" FILE: grep.vim
" AUTHOR:  Tomohiro Nishimura <tomohiro68@gmail.com>
" Last Modified: 08 Dec 2010
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================
"
" Usage:
"   :Unite grep:target:-options -input=pattern
"   (:Unite grep:~/.vim/autoload/unite/sources:-iR -input=file)
"
"   recommended to use -prompt=:)\  for your happy hacking
"
" Setting Examples:
"   let g:unite_source_grep_default_opts = '-iR'
"
" TODO:
"   * show current target
"   * support ignore pattern
"   * the goal is general unix command source :)
"
" Variables  "{{{
call unite#util#set_default('g:unite_source_grep_default_opts', '')
call unite#util#set_default('g:unite_source_grep_max_candidates', 100)
let s:unite_source_grep_target = ''
"}}}

" Actions "{{{
let s:action_grep = {
  \   'description': 'grep this',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep.func(candidates) "{{{
  call unite#start([insert(map(copy(a:candidates), 'v:val.action__path'), 'grep')], unite#get_context())
endfunction "}}}
if executable('grep')
  call unite#custom_action('source/file/file', 'grep', s:action_grep)
endif
" }}}

function! unite#sources#grep#define() "{{{
  return executable('grep') ? s:grep_source : []
endfunction "}}}

let s:grep_source = {
  \   'name': 'grep',
  \   'is_volatile': 1,
  \   'required_pattern_length': 3,
  \   'action_table': {},
  \   'max_candidates': g:unite_source_grep_max_candidates,
  \ }

function! s:grep_source.gather_candidates(args, context) "{{{

  let l:target  = get(a:args, 0, s:unite_source_grep_target)
  let l:extra_opts = get(a:args, 1, '')

  if get(a:args, 0, '') =~ '^-'
    let l:extra_opts = l:target
    let l:target  = s:unite_source_grep_target
  endif

  if empty(l:target) && empty(s:unite_source_grep_target)
    let s:unite_source_grep_target = input('Target: ')
    let l:target = s:unite_source_grep_target
  endif

  let s:unite_source_grep_target = l:target

  let l:candidates = split(
    \ unite#util#system(printf(
    \   'grep -Hn %s %s %s %s',
    \   g:unite_source_grep_default_opts,
    \   a:context.input,
    \   l:target,
    \   l:extra_opts)),
    \  "\n")
  return map(l:candidates,
    \ '{
    \   "word": v:val,
    \   "source": "grep",
    \   "kind": "jump_list",
    \   "action__path": get(split(v:val, ":", ""), 0),
    \   "action__line": get(split(v:val, ":", ""), 1),
    \ }')
endfunction "}}}

" vim: foldmethod=marker
