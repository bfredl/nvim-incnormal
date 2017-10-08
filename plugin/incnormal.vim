let g:s_state_save = []
let g:active = v:false
let g:s_buf = -1
let g:s_win = -1

func! incnormal#enter()
  " TESTING, later use code below return
  let g:active = v:true
  return 
  let g:lastenter = deepcopy(v:event)
  call add(g:s_state_save, get(g:, "Nvim_color_cmdline", 0))
  if v:event.level == 0 && v:event.kind == ":"
    let g:Nvim_color_cmdline = "inccomand#callback"
    let g:active = v:true
    call incnormal#start()
  else
    if has_key(g:, "Nvim_color_cmdline")
      call remove(g:, "Nvim_color_cmdline")
    endif
  endif
endfunc

func! incnormal#leave()
  if g:Nvim_color_cmdline == "inccomand#callback"
    call incnormal#stop()
  end

  return 0
  let oldstate = remove(g:s_state_save, -1)
  let g:Nvim_color_cmdline = oldstate
  if oldstate == 0
    call remove(g:, "Nvim_color_cmdline")
  elseif oldstate == "incnormal#callback"
    let g:active = v:true
  end
endfunc

func! incnormal#start()
  let oldwin = nvim_get_current_win()
  2new
  let g:s_win = nvim_get_current_win()
  let g:s_buf= nvim_get_current_win()
  call nvim_set_current_win(oldwin)
  redraw!
endfunc

func! incnormal#doit()
  let tick = b:changedtick
  execute g:s_cmdline
  redraw!
  let status = "N"
  if b:changedtick != tick
    undo
    let status = "Y"
  endif
  call nvim_buf_set_lines(g:s_buf,0,-1,v:true,[status])
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

let g:a = '\v^[^a-zA-Z]+norma '

func! incnormal#checkcmd()
  " TODO: handle named marks
  let match = match(g:s_cmdline, '\v^[^a-zA-Z]*norma ')
  return match >= 0
endfunc

func! incnormal#timer(timerid)
  let g:s_scheduled = v:false
  if g:active && incnormal#checkcmd()
      if g:s_win == -1
          call incnormal#start()
      end
      call incnormal#doit()
  end
endfunc

let g:Nvim_color_cmdline = "incnormal#callback"


augroup IncNormal
  au!
  au CmdlineEnter * call incnormal#enter()
  au CmdlineLeave * call incnormal#leave()
augroup END

