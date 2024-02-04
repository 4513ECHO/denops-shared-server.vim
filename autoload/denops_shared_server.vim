function! denops_shared_server#install() abort
  if !exists('g:denops_server_addr')
    call denops_shared_server#util#error('No denops shared server address (g:denops_server_addr) is given.')
    return
  endif
  let command = s:detect_command()
  if empty(command)
    return
  endif
  let [hostname, port] = s:parse_server_addr(g:denops_server_addr)
  let options = {
        \ 'deno': exepath(g:denops#deno),
        \ 'script': denops_shared_server#util#script_path('@denops-private/cli.ts'),
        \ 'hostname': hostname,
        \ 'port': port,
        \}
  call denops_shared_server#{command}#install(options)
  call denops_shared_server#util#info('wait second for the shared server startup...')
  call denops#server#wait()
  call denops_shared_server#util#info('connect to the shared server')
  call denops#server#connect()
  call denops_shared_server#util#info('stop the local server')
  call denops#server#stop()
endfunction

function! denops_shared_server#uninstall() abort
  let command = s:detect_command()
  if empty(command)
    return
  endif
  call denops_shared_server#{command}#uninstall()
endfunction

function! denops_shared_server#restart() abort
  let command = s:detect_command()
  if empty(command)
    return
  endif
  call denops_shared_server#{command}#restart()
endfunction

function! denops_shared_server#_render(template, context) abort
  let content = join(a:template, "\n")
  for [key, value] in items(a:context)
    let content = substitute(content, printf('{{%s}}', key), escape(value, '\'), 'g')
  endfor
  return split(content, "\n", v:true)
endfunction

function! s:parse_server_addr(addr) abort
  let parts = split(a:addr, ':', v:true)
  if len(parts) isnot# 2
    throw printf('[denops-shared-server] Server address must follow `{hostname}:{port}` format but `%s` is given', a:addr)
  endif
  return [parts[0], parts[1]]
endfunction

function! s:detect_command() abort
  if exists('s:command')
    return s:command
  elseif has('win32') && executable('powershell.exe')
    let s:command = 'runtray'
  elseif executable('launchctl')
    let s:command = 'launchctl'
  elseif executable('systemctl')
    let s:command = 'systemctl'
  else
    call denops_shared_server#util#error('This platform is not supported. Please configure denops-shared-server manually.')
    return ''
  endif
  return s:command
endfunction
