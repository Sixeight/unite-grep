"=============================================================================
" FILE: grep.vim
" Modified AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" Original AUTHOR:  Tomohiro Nishimura <tomohiro68 at gmail.com>
" Last Modified: 13 Jun 2011.
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

" Variables  "{{{
call unite#util#set_default('g:unite_source_grep_command', 'grep')
call unite#util#set_default('g:unite_source_grep_default_opts', '-Hn')
call unite#util#set_default('g:unite_source_grep_max_candidates', 100)
"}}}

" Actions "{{{
let s:action_grep_file = {
  \   'description': 'grep this files',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_file.func(candidates) "{{{
  call unite#start([insert(map(copy(a:candidates), 'v:val.action__path'), 'grep')])
endfunction "}}}

let s:action_grep_directory = {
  \   'description': 'grep this directories',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_directory.func(candidates) "{{{
  call unite#start([insert(map(copy(a:candidates), 'v:val.action__directory'), 'grep')])
endfunction "}}}
if executable(g:unite_source_grep_command) && unite#util#has_vimproc()
  call unite#custom_action('file,buffer', 'grep', s:action_grep_file)
  call unite#custom_action('file,buffer', 'grep_directory', s:action_grep_directory)
endif
" }}}

function! unite#sources#grep#define() "{{{
  if !exists('*unite#version') || unite#version() <= 100
    echoerr 'Your unite.vim is too old.'
    echoerr 'Please install unite.vim Ver.1.1 or above.'
    return []
  endif

  return executable(g:unite_source_grep_command) && unite#util#has_vimproc() ? s:grep_source : []
endfunction "}}}

let s:grep_source = {
  \   'name': 'grep',
  \   'max_candidates': g:unite_source_grep_max_candidates,
  \   'hooks' : {},
  \ }

function! s:grep_source.hooks.on_init(args, context) "{{{
  let l:target  = get(a:args, 0, '')
  if type(l:target) != type([])
    if l:target == ''
      let l:target = input('Target: ', '**', 'file')
    endif

    if l:target == '%' || l:target == '#'
      let l:target = unite#util#escape_file_searching(bufname(l:target))
    elseif l:target ==# '$buffers'
      let l:target = join(map(filter(range(1, bufnr('$')), 'buflisted(v:val)'),
            \ 'unite#util#escape_file_searching(bufname(v:val))'))
    elseif l:target == '**' && g:unite_source_grep_command ==# 'grep'
      " Optimized.
      let l:target = '* -R'
    endif

    let a:context.source__target = [l:target]
  else
    let a:context.source__target = l:target
  endif

  let a:context.source__extra_opts = get(a:args, 1, '')

  let a:context.source__input = get(a:args, 2, '')
  if a:context.source__input == ''
    let a:context.source__input = input('Pattern: ')
  endif

  call unite#print_message('[grep] Target: ' . join(a:context.source__target))
  call unite#print_message('[grep] Pattern: ' . a:context.source__input)
endfunction"}}}

function! s:grep_source.gather_candidates(args, context) "{{{
  if empty(a:context.source__target)
        \ || a:context.source__input == ''
    let a:context.is_async = 0
    call unite#print_message('[grep] Completed.')
    return []
  endif

  let l:cmdline = printf('%s %s %s %s %s',
    \   g:unite_source_grep_command,
    \   g:unite_source_grep_default_opts,
    \   a:context.source__input,
    \   join(a:context.source__target),
    \   a:context.source__extra_opts)
  call unite#print_message('[grep] Command-line: ' . l:cmdline)
  let a:context.source__proc = vimproc#pgroup_open(l:cmdline)
  " let a:context.source__proc = vimproc#popen3(l:cmdline)

  " Close handles.
  call a:context.source__proc.stdin.close()
  call a:context.source__proc.stderr.close()

  return []
endfunction "}}}

function! s:grep_source.async_gather_candidates(args, context) "{{{
  let l:stdout = a:context.source__proc.stdout
  if l:stdout.eof
    " Disable async.
    call unite#print_message('[grep] Completed.')
    let a:context.is_async = 0
  endif

  let l:result = []
  if has('reltime') && has('float')
    let l:time = reltime()
    while str2float(reltimestr(reltime(l:time))) < 0.2
          \       && !l:stdout.eof
      let l:output = l:stdout.read_line()
      if l:output != ''
        call add(l:result, l:output)
      endif
    endwhile
  else
    let i = 100
    while 0 < i && !l:stdout.eof
      let l:output = l:stdout.read_line()
      if l:output != ''
        call add(l:result, l:output)
      endif

      let i -= 1
    endwhile
  endif

  let l:candidates = map(filter(l:result,
    \  'v:val =~ "^.\\+:.\\+:.\\+$"'),
    \ '[v:val, split(v:val[2:], ":")]')

  return map(l:candidates,
    \ '{
    \   "word": v:val[0],
    \   "source": "grep",
    \   "kind": "jump_list",
    \   "action__path": v:val[0][:1].v:val[1][0],
    \   "action__line": v:val[1][1],
    \   "action__text": join(v:val[1][2:], ":"),
    \ }')
endfunction "}}}

function! s:grep_source.on_close(args, context) "{{{
  call a:context.source__proc.close()
endfunction "}}}

" vim: foldmethod=marker
