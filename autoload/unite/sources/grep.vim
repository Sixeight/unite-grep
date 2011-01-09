"=============================================================================
" FILE: grep.vim
" AUTHOR:  Tomohiro Nishimura <tomohiro68@gmail.com>
" Last Modified: 09 Jan 2011.
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
" Description:
"   You can grep with unite interactive.
"   And use grep action on file/buffer kind.
"
" Usage:
"   :Unite grep:target:-options -input=pattern
"   (:Unite grep:~/.vim/autoload/unite/sources:-iR -input=file)
"
" Setting Examples:
"   let g:unite_source_grep_default_opts = '-iRHn'
"
" TODO:
"   * show current target
"   * support ignore pattern
"   * the goal is general unix command source :)
"
" Variables  "{{{
call unite#util#set_default('g:unite_source_grep_command', 'grep')
call unite#util#set_default('g:unite_source_grep_default_opts', '-Hn')
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
  call unite#start([insert(map(copy(a:candidates), 'v:val.action__path'), 'grep')])
endfunction "}}}
if executable(g:unite_source_grep_command)
  call unite#custom_action('file,buffer', 'grep', s:action_grep)
endif
" }}}

function! unite#sources#grep#define() "{{{
  return executable('grep') ? s:grep_source : []
endfunction "}}}

let s:grep_source = {
  \   'name': 'grep',
  \   'is_volatile': 1,
  \   'required_pattern_length': 3,
  \   'max_candidates': g:unite_source_grep_max_candidates,
  \   'hooks' : {},
  \ }

function! s:grep_source.hooks.on_init(args, context) "{{{
  let l:target  = get(a:args, 0)

  if get(a:args, 0, '') =~ '^-'
    let l:target  = s:unite_source_grep_target
  endif

  if l:target == ''
    let l:target = input('Target: ', '', 'file')
  endif

  if l:target == '%' || l:target == '#'
    let l:target = bufname(l:target)
  endif

  let s:unite_source_grep_target = l:target
endfunction"}}}

function! s:grep_source.gather_candidates(args, context) "{{{
  if s:unite_source_grep_target == ''
    return []
  endif

  let l:extra_opts = get(a:args, 0, '') =~ '^-' ?
        \ a:args[0]: get(a:args, 1, '')

  let l:candidates = map(split(
    \ unite#util#system(printf(
    \   '%s %s %s %s %s',
    \   g:unite_source_grep_command,
    \   g:unite_source_grep_default_opts,
    \   a:context.input,
    \   s:unite_source_grep_target,
    \   l:extra_opts)),
    \  "\n"), '[v:val, split(v:val[2:], ":")]')
  return map(l:candidates,
    \ '{
    \   "word": v:val[0],
    \   "source": "grep",
    \   "kind": "jump_list",
    \   "action__path": v:val[0][:1].get(v:val[1], 0),
    \   "action__line": get(v:val[1], 1),
    \   "source__text": join(v:val[1][2:], ":"),
    \ }')
endfunction "}}}

" vim: foldmethod=marker
