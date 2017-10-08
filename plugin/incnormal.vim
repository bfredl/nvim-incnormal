let g:s_state_save = []
let g:s_active = v:false
let g:s_buf = -1
let g:s_win = -1
let g:s_suspended = 0
let g:s_cursors = []

" fake exectue in an expr mapping, emulates #4419
func! Fakexecute(cmd,unsandbox)
  if a:unsandbox
    " 'Note how execute() is used to execute an Ex command.  That's ugly though.'
    call timer_start(0,{x -> execute(a:cmd)})
  else
    exec a:cmd
  endif
  return ''
endfunc

function! s:saveCur()
    " from matchit
    let restore_cursor = virtcol(".") . "|"
    normal! g0
    let restore_cursor = line(".") . "G" .  virtcol(".") . "|zs" . restore_cursor
    normal! H
    let restore_cursor = "normal!" . line(".") . "Gzt" . restore_cursor
    execute restore_cursor
    return restore_cursor
endfunction


cnoremap <expr> <Plug>(incnormal-suspend) Fakexecute("let g:s_suspended = !g:s_suspended", 0)
cmap <F4> <Plug>(incnormal-suspend)

map <expr> <Plug>(incnormal-cursor) incnormal#cursor()
map! <expr> <Plug>(incnormal-cursor) incnormal#cursor()

func! incnormal#cursor()
  call add(g:s_cursors, getpos('.'))
  return ''
endfunc

" handy debug helper
cnoremap <expr> <f5> Fakexecute("let g:copy = deepcopy(g:)", 1)

func! incnormal#enter()
  "let g:lastenter = deepcopy(v:event)
  call add(g:s_state_save, get(g:, "Nvim_color_cmdline", 0))
  if v:event.level == 1 && v:event.kind == ":"
    let g:Nvim_color_cmdline = "incnormal#callback"
    let g:s_active = v:true
  else
    if has_key(g:, "Nvim_color_cmdline")
      call remove(g:, "Nvim_color_cmdline")
    endif
  endif
endfunc

func! incnormal#leave()
  if get(g:,"Nvim_color_cmdline",0) == "incnormal#callback"
    call Fakexecute("call incnormal#stop()", 1)
  end

  let oldstate = remove(g:s_state_save, -1)
  let g:Nvim_color_cmdline = oldstate
  if oldstate == 0
    call remove(g:, "Nvim_color_cmdline")
  elseif oldstate == "incnormal#callback"
    let g:s_active = v:true
  end
endfunc

func! incnormal#start()
  let oldwin = nvim_get_current_win()
  2new
  " TODO: reuse buffer
  set buftype=nofile
  set nobuflisted
  file [incnormal]
  let g:s_win = nvim_get_current_win()
  let g:s_buf = nvim_get_current_buf()
  call nvim_set_current_win(oldwin)
  redraw!
endfunc

func! incnormal#stop()
  let g:s_active = v:false
  " TODO: save and restore window layout
  if g:s_win != -1
    let oldwin = nvim_get_current_win()
    call nvim_set_current_win(g:s_win)
    quit!
    call nvim_set_current_win(oldwin)
    redraw!
    let g:s_win = -1
  endif

endfunc

let g:s_src_id = nvim_buf_add_highlight(0, 0, "", 0,0,0)

func! incnormal#doit()
  let g:s_cursors = []
  let tick = b:changedtick
  let cur = ""
  if g:s_suspended
    let status = "SUSPENDED"
  else
    let cur = s:saveCur()
    execute g:s_cmdline."\<Plug>(incnormal-cursor)"
    let status = "N"
    if b:changedtick != tick
      let status = "Y"
    endif
  endif
  call nvim_buf_set_lines(g:s_buf,0,-1,v:true,[status])

  if len(g:s_cursors)
    for c in g:s_cursors
      call nvim_buf_add_highlight(0, g:s_src_id, "Error", c[1]-1, c[2]-1, c[2])
    endfor
  endif
  redraw!
  if b:changedtick != tick
    undo
  endif
  if len(g:s_cursors)
    call nvim_buf_clear_highlight(0, g:s_src_id, 0, -1)
  end
  execute cur
endfunc

let g:s_scheduled = v:false
let g:s_changed = v:false

func! incnormal#callback(cmdline)
    let g:s_changed = v:true
    let g:s_cmdline = a:cmdline
    if !g:s_scheduled
      let g:s_timer = timer_start(0, "incnormal#timer")
      let g:s_scheduled = v:true
    end
    if len(a:cmdline) >= 6
        return [[3, 6, "Comment"]]
    end
    return []
endfunc

func! incnormal#checkcmd()
  " TODO: handle named marks
  " TODO: g/blargh/normal
  " TODO: also incsearch for g/blarg
  let match = match(g:s_cmdline, '\v^[^a-zA-Z]*norma!? .')
  return match >= 0
endfunc

func! incnormal#timer(timerid)
  let g:s_scheduled = v:false
  if g:s_active && incnormal#checkcmd()
    if g:s_win == -1
      call incnormal#start()
    end
    call incnormal#doit()
  end
endfunc



augroup IncNormal
  au!
  au CmdlineEnter * call incnormal#enter()
  au CmdlineLeave * call incnormal#leave()
augroup END

