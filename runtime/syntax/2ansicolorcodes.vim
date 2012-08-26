" Vim syntax support file
" Maintainer: Olivier Favre <of.olivier.favre@gmail.com>
" Last Change: 2012 Aug 22

" Transform a file into ANSI color codes, using the current syntax highlighting.

" This file uses line continuations
let s:cpo_sav = &cpo
let s:ls  = &ls
set cpo-=C

let s:end=line('$')

let s:settings = toansicolorcodes#GetUserSettings()

if has('gui_running')
  let s:whatterm = 'gui'
else
  if &t_Co > 1
    let s:whatterm = 'cterm'
  else
    let s:whatterm = 'term'
  endif
endif

if &t_AF != ''
  let s:fg_code = &t_AF
else
  let s:fg_code = &t_Sf
endif

if &t_AB != ''
  let s:bg_code = &t_AB
else
  let s:bg_code = &t_Sb
endif

let s:normal_id = synIDtrans(hlID('normal'))
let s:normal_fg = synIDattr(s:normal_id, 'fg#', s:whatterm)
let s:normal_bg = synIDattr(s:normal_id, 'bg#', s:whatterm)
let s:normal_fg_bold = synIDattr(s:normal_id, 'bold', s:whatterm)
" store last highlight attribute
let s:last_fg = -1
let s:last_bg = -1
let s:last_bold = 0
let s:last_inverse = 0
let s:last_standout = 0
let s:last_undercurl = 0
let s:last_italic = 0
let s:last_underline = 0

" Now loop over all lines in the original text to convert to ANSI color codes.
" Use ansicolorcodes_start_line and ansicolorcodes_end_line if they are set.
if exists('g:ansicolorcodes_start_line')
  let s:lnum = ansicolorcodes_start_line
  if s:lnum < 1 || s:lnum > line('$')
    let s:lnum = 1
  endif
else
  let s:lnum = 1
endif
if exists('g:ansicolorcodes_end_line')
  let s:end = ansicolorcodes_end_line
  if s:end < s:lnum || s:end > line('$')
    let s:end = line('$')
  endif
else
  let s:end = line('$')
endif

" set termcap
"     t_Co : number of colors
"     t_AB : ANSI background
"     t_AF : ANSI foreground
"     t_mb : blink
"     t_md : bold
"     t_me : normal (no invert, no blink, no bold, default color, also no underline)
"     t_mr : invert
"     t_op : reset foreground and background
"     t_se : standout end
"     t_so : standout mode (sometimes invert)
"     t_ue : underline end
"     t_us : underline mode
"     t_Ce : undercurl end
"     t_Cs : undercurl mode
"     t_ZH : italic mode
"     t_ZR : italic end
"     t_Sb : background
"     t_Sf : foreground
" If t_Co is non zero:
"   Use t_AB and t_AF if available, t_Sb and t_Sf otherwise.
"   Use t_me to reset

function! s:neq(a, b)
  if a:a
    if a:b
      return 0
    else
      return 1
    endif
  else
    if a:b
      return 1
    else
      return 0
    endif
  endif
endfun
function! s:up(a, b)
  if a:a
    return 0
  elseif a:b
    return 1
  else
    return 0
  endif
endfun
function! s:down(a, b)
  if a:a
    if a:b
      return 0
    else
      return 1
    endif
  else
    return 0
  endif
endfun

" See term.c:void term_color(uchar*,int)
function! s:term_color(code, color)
  let code = a:code
  let color = a:color
  if color >= 8 && &t_Co >= 16
    let i = 0
    if code[0] == '\x9B'
      let i = 2
    elseif code[0] == '\e' && code[1] == '['
      let i = 3
    endif
    if i != 0 && code[i] != '\0'
          \ && (code[i+1] == '%p1%dm' || code[i+1] == '%dm')
          \ && (code[i] == 3 || code[i] == 4)
      if color >= 16
        let code = code[0 : (i)] . '8;5;' . code[(i+1) : ]
      else
        if code[i] == 3 "fg
          let code = code[0 : (i-1)] . '9' . code[(i+1) : ]
        else
          let code = code[0 : (i-1)] . '10' . code[(i+1) : ]
        endif
        let color = color - 8
      endif
    endif
  endif
  return s:tgoto(code, color)
endfun
" See termlib.c:char* tgoto(char*,int,int)
function! s:tgoto(code, color)
  let code = substitute(a:code, '%%', '%', 'g')
  let code = substitute(code, '%p.%d', '%d', 'g')
  let code = substitute(code, '%d', a:color, '')
  return code
endfun
" See term.c:void term_fg_color(int)
function! s:term_fg_color(color)
  if a:color == '' || a:color < 0
    return ''
  else
    return s:term_color(s:fg_code, a:color)
  endif
endfun
" See term.c:void term_bg_color(int)
function! s:term_bg_color(color)
  if a:color == '' || a:color < 0
    return ''
  else
    return s:term_color(s:bg_code, a:color)
  endif
endfun
" See screen.c:void screen_start_highlight(int)
function! s:screen_start_highlight(id)
  let rtn = ''
  if ( &t_Co > 1 && s:normal_fg_bold && synIDattr(a:id, 'fg#', s:whatterm) >= 0 )
        \ || s:down(s:last_bold, synIDattr(a:id, 'bold', s:whatterm))
        \ || s:down(s:last_inverse, synIDattr(a:id, 'inverse', s:whatterm))
        \ || (exists('&t_se') && &t_se == &t_me && s:down(s:last_standout, synIDattr(a:id, 'standout', s:whatterm)))
        \ || (exists('&t_Ce') && &t_Ce == &t_me && s:down(s:last_undercurl, synIDattr(a:id, 'undercurl', s:whatterm)))
        \ || (exists('&t_ue') && &t_ue == &t_me && s:down(s:last_underline, synIDattr(a:id, 'underline', s:whatterm)))
        \ || (exists('&t_ZR') && &t_ZR == &t_me && s:down(s:last_italic, synIDattr(a:id, 'italic', s:whatterm)))
    let rtn = &t_me . rtn
    let s:last_standout = 0
    let s:last_undercurl = 0
    let s:last_underline = 0
    let s:last_italic = 0
    let s:last_inverse = 0
    let s:last_bold = 0
    let s:last_fg = -1
    let s:last_bg = -1
  endif
  if s:up(s:last_bold, synIDattr(a:id, 'bold', s:whatterm))
    let s:last_bold = synIDattr(a:id, 'bold', s:whatterm)
    let rtn = rtn . &t_md
  endif
  if s:up(s:last_inverse, synIDattr(a:id, 'inverse', s:whatterm))
    let s:last_inverse = synIDattr(a:id, 'inverse', s:whatterm)
    let rtn = rtn . &t_mr
  endif
  if s:neq(s:last_standout, synIDattr(a:id, 'standout', s:whatterm))
    let s:last_standout = synIDattr(a:id, 'standout', s:whatterm)
    if s:last_standout
      let rtn = rtn . &t_so
    else
      let rtn = rtn . &t_se
    endif
  endif
  if s:neq(s:last_undercurl, synIDattr(a:id, 'undercurl', s:whatterm))
    let s:last_undercurl = synIDattr(a:id, 'undercurl', s:whatterm)
    if s:last_undercurl
      let rtn = rtn . &t_Cs
    else
      let rtn = rtn . &t_Ce
    endif
  endif
  if s:neq(s:last_underline, synIDattr(a:id, 'underline', s:whatterm))
    let s:last_underline = synIDattr(a:id, 'underline', s:whatterm)
    if s:last_underline
      let rtn = rtn . &t_us
    else
      let rtn = rtn . &t_ue
    endif
  endif
  if s:neq(s:last_italic, synIDattr(a:id, 'italic', s:whatterm))
    let s:last_italic = synIDattr(a:id, 'italic', s:whatterm)
    if s:last_italic
      let rtn = rtn . &t_ZH
    else
      let rtn = rtn . &t_ZR
    endif
  endif
  if &t_Co > 1
    if s:last_fg != synIDattr(a:id, 'fg#', s:whatterm) || s:last_bg != synIDattr(a:id, 'bg#', s:whatterm)
      if (s:last_fg >= 0 && synIDattr(a:id, 'fg#', s:whatterm) < 0) || (s:last_bg >= 0 && synIDattr(a:id, 'bg#', s:whatterm) < 0)
        let rtn = rtn . &t_op
      endif
      let s:last_fg = synIDattr(a:id, 'fg#', s:whatterm)
      let s:last_bg = synIDattr(a:id, 'bg#', s:whatterm)
      let rtn = rtn . s:term_fg_color(synIDattr(a:id, 'fg#', s:whatterm))
            \ . s:term_bg_color(synIDattr(a:id, 'bg#', s:whatterm))
    endif
  endif
  return rtn
endfun
" See screen.c:void screen_stop_highlight()
function! s:screen_stop_highlight()
  let rtn = &t_me
  "let rtn = ''
  "let me = 0
  "if s:last_standout
  "  if &t_se == &t_me | let me = 1
  "  else | let rtn = rtn . &t_se | endif
  "endif
  "if s:last_underline || s:last_undercurl
  "  if &t_ue == &t_me | let me = 1
  "  else | let rtn = rtn . &t_ue | endif
  "endif
  "if s:last_italic
  "  if &t_Zr == &t_me | let me = 1
  "  else | let rtn = rtn . &t_Zr | endif
  "endif
  "if me == 1 || s:last_bold || s:last_inverse
  "  let rtn = rtn . &t_me
  "endif
  if &t_Co > 1
    let rtn = rtn . &t_op
  endif
  return rtn
endfun
" See screen.c:void reset_cterm_colors()
function! s:reset_cterm_colors()
  let rtn = ''
  if &t_Co > 1
    if s:normal_fg >= 0 || s:normal_bg >= 0
      let s:last_fg = -1
      let s:last_bg = -1
      let rtn = rtn . &t_op
    endif
    if s:normal_fg_bold
      let s:last_bold = 0
      let rtn = rtn . &t_me
    endif
  endif
  return rtn
endfun

function! s:Format(text, name)
  let text = strtrans(a:text)
  let s:id = synIDtrans(hlID(a:name))
  return s:screen_start_highlight(s:id) . text
endfun



" Set some options to make it work faster.
" Don't report changes for :substitute, there will be many of them.
" Don't change other windows; turn off scroll bind temporarily
let s:old_title = &title
let s:old_icon = &icon
let s:old_et = &l:et
let s:old_bind = &l:scrollbind
let s:old_report = &report
let s:old_search = @/
let s:old_more = &more
set notitle noicon
setlocal et
set nomore
set report=1000000
setlocal noscrollbind

if exists(':ownsyntax') && exists('w:current_syntax')
  let s:current_syntax = w:current_syntax
elseif exists('b:current_syntax')
  let s:current_syntax = b:current_syntax
else
  let s:current_syntax = 'none'
endif

if s:current_syntax == ''
  let s:current_syntax = 'none'
endif

" Split window to create a buffer with the ANSI color coded file.
let s:orgbufnr = winbufnr(0)
let s:origwin_stl = &l:stl
if expand("%") == ""
  exec 'new Untitled.cat'
else
  exec 'new %.cat'
endif

" Resize the new window to very small in order to make it draw faster
let s:old_winheight = winheight(0)
let s:old_winfixheight = &l:winfixheight
if s:old_winheight > 2
  resize 1 " leave enough room to view one line at a time
  norm! G
  norm! zt
endif
setlocal winfixheight

let s:newwin_stl = &l:stl

" on the new window, set the least time-consuming fold method
let s:old_fdm = &foldmethod
let s:old_fen = &foldenable
setlocal foldmethod=manual
setlocal nofoldenable

let s:newwin = winnr()
let s:orgwin = bufwinnr(s:orgbufnr)

setlocal modifiable
%d
let s:old_paste = &paste
set paste
let s:old_magic = &magic
set magic

" set the fileencoding to match the charset we'll be using
let &l:fileencoding=s:settings.vim_encoding

" According to http://www.w3.org/TR/html4/charset.html#doc-char-set, the byte
" order mark is highly recommend on the web when using multibyte encodings. But,
" it is not a good idea to include it on UTF-8 files. Otherwise, let Vim
" determine when it is actually inserted.
if s:settings.vim_encoding == 'utf-8'
  setlocal nobomb
else
  setlocal bomb
endif

exe s:orgwin . "wincmd w"



" Now loop over all lines in the original text to convert to html.
" Use html_start_line and html_end_line if they are set.
if exists("g:html_start_line")
  let s:lnum = html_start_line
  if s:lnum < 1 || s:lnum > line("$")
    let s:lnum = 1
  endif
else
  let s:lnum = 1
endif
if exists("g:html_end_line")
  let s:end = html_end_line
  if s:end < s:lnum || s:end > line("$")
    let s:end = line("$")
  endif
else
  let s:end = line("$")
endif



if s:settings.number_lines
  let s:margin = strlen(s:end) + 1
else
  let s:margin = 0
endif

if !s:settings.expand_tabs
  " If keeping tabs, add them to printable characters so we keep them when
  " formatting text (strtrans() doesn't replace printable chars)
  let s:old_isprint = &isprint
  setlocal isprint+=9
endif



let s:lines = []

while s:lnum <= s:end
  " Start the line with the line number.
  if s:settings.number_lines
    let s:numcol = repeat(' ', s:margin - 1 - strlen(s:lnum)) . s:lnum . ' '
  else
    let s:numcol = ''
  endif

  let s:new = ''

  if has('folding') && !s:settings.ignore_folding && foldclosed(s:lnum) > -1 && !s:settings.dynamic_folds
    "
    " This is the beginning of a folded block (with no dynamic folding)
    "
    let s:new = s:numcol . foldtextresult(s:lnum)
    " HTML line wrapping is off--go ahead and fill to the margin
    let s:new = s:new . repeat(s:foldfillchar, &columns - strlen(s:new))

    let s:new = s:Format(s:new, 'Folded')

    " Skip to the end of the fold
    let s:new_lnum = foldclosedend(s:lnum)

    if !s:settings.no_progress
      call s:pgb.incr(s:new_lnum - s:lnum)
    endif

    let s:lnum = s:new_lnum

  else
    "
    " A line that is not folded, or doing dynamic folding.
    "
    let s:line = getline(s:lnum)
    let s:len = strlen(s:line)

    " Now continue with the unfolded line text
    if s:settings.number_lines
      let s:new = s:new . s:Format(s:numcol, 'LineNr')
    endif

    " initialize conceal info to act like not concealed, just in case
    let s:concealinfo = [0, '']

    " Loop over each character in the line
    let s:col = 1

    while s:col <= s:len
      let s:startcol = s:col " The start column for processing text
      if !s:settings.ignore_conceal && has('conceal')
        let s:concealinfo = synconcealed(s:lnum, s:col)
      endif
      if !s:settings.ignore_conceal && s:concealinfo[0]
        let s:col = s:col + 1
        " Speed loop (it's small - that's the trick)
        " Go along till we find a change in the match sequence number (ending
        " the specific concealed region) or until there are no more concealed
        " characters.
        while s:col <= s:len && s:concealinfo == synconcealed(s:lnum, s:col) | let s:col = s:col + 1 | endwhile
      else
        let s:id = synID(s:lnum, s:col, 1)
        let s:col = s:col + 1
        " Speed loop (it's small - that's the trick)
        " Go along till we find a change in synID
        while s:col <= s:len && s:id == synID(s:lnum, s:col, 1) | let s:col = s:col + 1 | endwhile
      endif

      if s:settings.ignore_conceal || !s:concealinfo[0]
        " Expand tabs if needed
        let s:expandedtab = strpart(s:line, s:startcol - 1, s:col - s:startcol)
        if s:settings.expand_tabs
          let s:offset = 0
          let s:idx = stridx(s:expandedtab, '\t')
          while s:idx >= 0
            if has('multi_byte_encoding')
              if s:startcol + s:idx == 1
                let s:i = &ts
              else
                if s:idx == 0
                  let s:prevc = matchstr(s:line, '.\%' . (s:startcol + s:idx + s:offset) . 'c')
                else
                  let s:prevc = matchstr(s:expandedtab, '.\%' . (s:idx + 1) . 'c')
                endif
                let s:vcol = virtcol([s:lnum, s:startcol + s:idx + s:offset - len(s:prevc)])
                let s:i = &ts - (s:vcol % &ts)
              endif
              let s:offset -= s:i - 1
            else
              let s:i = &ts - ((s:idx + s:startcol - 1) % &ts)
            endif
            let s:expandedtab = substitute(s:expandedtab, '\t', repeat(' ', s:i), '')
            let s:idx = stridx(s:expandedtab, '\t')
          endwhile
        end

        " get the highlight group name to use
        let s:id = synIDtrans(s:id)
        let s:id_name = synIDattr(s:id, 'name', s:whatterm)
      else
        " use Conceal highlighting for concealed text
        let s:id_name = 'Conceal'
        let s:expandedtab = s:concealinfo[1]
      endif

      " Output the text with the same synID, with class set to {s:id_name},
      " unless it has been concealed completely.
      if strlen(s:expandedtab) > 0
        let s:new = s:new . s:Format(s:expandedtab,  s:id_name)
      endif
    endwhile
    let s:new = s:new . s:Format('', 'Normal')
  endif

  call extend(s:lines, split(s:new, '\n', 1))
  let s:lnum = s:lnum + 1
endwhile

let s:lines[-1] = s:lines[-1] . s:screen_stop_highlight()
let s:lines[0] = s:reset_cterm_colors() . s:lines[0]

exe s:newwin . 'wincmd w'
call setline(1, s:lines)
unlet s:lines

" Restore old settings (new window first)
let &l:foldenable = s:old_fen
let &l:foldmethod = s:old_fdm
let &report = s:old_report
let &title = s:old_title
let &icon = s:old_icon
let &paste = s:old_paste
let &magic = s:old_magic
let @/ = s:old_search
let &more = s:old_more

" switch to original window to restore those settings
exe s:orgwin . "wincmd w"

if !s:settings.expand_tabs
  let &l:isprint = s:old_isprint
endif
let &l:stl = s:origwin_stl
let &l:et = s:old_et
let &l:scrollbind = s:old_bind

" and back to the new window again to end there
exe s:newwin . "wincmd w"

let &l:stl = s:newwin_stl
exec 'resize' s:old_winheight
let &l:winfixheight = s:old_winfixheight

let &ls=s:ls

" Save a little bit of memory (worth doing?)
unlet s:old_et s:old_paste s:old_icon s:old_report s:old_title s:old_search
unlet s:old_magic s:old_more s:old_fdm s:old_fen s:old_winheight
unlet! s:old_isprint
unlet s:whatterm s:lnum s:end s:margin s:old_winfixheight
unlet! s:col s:id s:len s:line s:new s:expandedtab s:concealinfo
unlet! s:orgwin s:newwin s:orgbufnr s:idx s:i s:offset s:ls s:origwin_stl
unlet! s:newwin_stl s:current_syntax
if !v:profiling
  delfunc s:neq
  delfunc s:up
  delfunc s:down
  delfunc s:Format
  delfunc s:screen_start_highlight
  delfunc s:screen_stop_highlight
  delfunc s:term_fg_color
  delfunc s:term_bg_color
  delfunc s:term_color
  delfunc s:tgoto
endif

unlet! s:new_lnum s:numcol s:settings

let &cpo = s:cpo_sav
unlet! s:cpo_sav

unlet! s:bg_code s:cpo_sav s:fg_code s:id_name s:lines s:old_bind s:prevc s:startcol s:vcol
unlet! s:normal_id s:normal_fg s:normal_bg s:normal_fg_bold s:last_fg s:last_bg s:last_bold s:last_inverse s:last_standout s:last_undercurl s:last_italic s:last_underline

" vim: ts=8 sw=2 sts=2 et
