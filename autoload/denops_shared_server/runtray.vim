let s:file = expand('<sfile>:p')
let s:name = 'denops-shared-server'
let s:local_app_data = isdirectory($LOCALAPPDATA) ? '$LOCALAPPDATA' : '~\AppData\Local'
let s:config_file = expand(printf('%s\denops\%s.json', s:local_app_data, s:name))
let s:script_file = expand(printf('%s\denops\%s.ps1', s:local_app_data, s:name))
let s:config_template_file = printf('%s\runtray.template.json', fnamemodify(s:file, ':h'))
let s:ps_cmd = 'powershell -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command'
let s:script_download_url = 'https://raw.githubusercontent.com/Milly/runtray-ps/v1.0.0/runtray.ps1'

function! denops_shared_server#runtray#install(options) abort
  let content = denops_shared_server#_render(readfile(s:config_template_file, 'b'), {
        \ 'deno': escape(a:options.deno, '\'),
        \ 'script': escape(a:options.script, '\'),
        \ 'hostname': a:options.hostname,
        \ 'port': a:options.port,
        \})
  call denops#util#info(printf('create the configuration file `%s`', s:config_file))
  call mkdir(fnamemodify(s:config_file, ':h'), 'p')
  call writefile(content, s:config_file, 'b')

  call denops#util#info(printf('download the script `%s`', s:script_file))
  echo system(printf(
        \ '%s Invoke-WebRequest -URI "%s" -OutFile "%s";Unblock-File "%s"',
        \ s:ps_cmd,
        \ s:script_download_url,
        \ s:script_file,
        \ s:script_file,
        \))

  call denops#util#info('install to the startup')
  echo system(printf('%s "%s" install', s:ps_cmd, s:script_file))

  call denops#util#info('start the service')
  echo system(printf('%s "%s" start', s:ps_cmd, s:script_file))
endfunction

function! denops_shared_server#runtray#uninstall() abort
  call denops#util#info('uninstall from the startup')
  call system(printf('%s "%s" uninstall', s:ps_cmd, s:script_file))

  call denops#util#info(printf('delete the configuration file `%s`', s:config_file))
  call delete(s:config_file)

  call denops#util#info(printf('delete the script `%s`', s:script_file))
  call delete(s:script_file)
endfunction
