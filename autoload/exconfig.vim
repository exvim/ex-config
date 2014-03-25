let s:old_titlestring=&titlestring
let s:old_tagrelative=&tagrelative
let s:old_tags=&tags

" exconfig#apply_project_type {{{
function exconfig#apply_project_type() 
endfunction

" exconfig#reset {{{
function exconfig#reset() 
    let &titlestring=s:old_titlestring
    let &tagrelative=s:old_tagrelative
    let &tags=s:old_tags
endfunction

" exconfig#apply {{{
function exconfig#apply() 

    " ===================================
    " pre-check 
    " ===================================

    let cwd = vimentry#get('cwd')
    let project_name = vimentry#get('project_name')

    if cwd == ''
        call ex#error("Can't find vimentry setting 'cwd'.")
        return
    endif

    if project_name == ''
        call ex#error("Can't find vimentry setting 'project_name'.")
        return
    endif

    let g:exvim_project_name = project_name
    let g:exvim_project_root = cwd
    let g:exvim_folder = cwd.'/.exvim.'.project_name

    " set parent working directory
    silent exec 'cd ' . escape(cwd, " ")
    let g:exvim_project_name = project_name

    let s:old_titlestring=&titlestring
    set titlestring=%{g:exvim_project_name}:\ %t\ (%{expand(\"%:p:.:h\")}/)

    " create folder .exvim.xxx/ if not exists
    let path = g:exvim_folder
    if finddir(path) == ''
        silent call mkdir(path)
    endif

    " create folder .exvim.xxx/tmp/ if not exists
    let path = g:exvim_folder.'/tmp' 
    if finddir(path) == ''
        silent call mkdir(path)
    endif

    " ===================================
    " general settings
    " ===================================

    " apply project_type settings
    if !vimentry#check('project_type', '')
        " TODO:
        " let project_types = split( vimentry#get('project_type'), ',' )
    endif

    " set tag file path
    if vimentry#check('enable_tags', 'true')
        let s:old_tagrelative=&tagrelative
        let &tagrelative=0 " set notagrelative

        let s:old_tags=&tags
        let &tags=escape(g:exvim_folder."/tags", " ")

        call exconfig#gen_sh_update_ctags(g:exvim_folder)
    endif

    " create .exvim.xxx/hierarchies/
    if vimentry#check('enable_inherits', 'true')
        " TODO:
        " let inherit_directory_path = g:exES_CWD.'/'.g:exES_vimfiles_dirname.'/.hierarchies' 
        " if finddir(inherit_directory_path) == ''
        "   silent call mkdir(inherit_directory_path)
        " endif
    endif

    " set gsearch 
    if vimentry#check('enable_gsearch', 'true')
        let gsearch_engine = vimentry#get('gsearch_engine')
        if gsearch_engine == 'idutils'
            " TODO: call exUtility#CreateIDLangMap ( exUtility#GetProjectFilter("file_filter") )
            call exconfig#gen_sh_update_idutils(g:exvim_folder)
        endif
    endif

    " set cscope file path
    if vimentry#check('enable_cscope', 'true')
        " TODO: silent call g:exCS_ConnectCscopeFile()
    endif

    " macro highlight
    if vimentry#check('enable_macrohl', 'true')
        " TODO: silent call g:exMH_InitMacroList(g:exES_Macro)
    endif

    " TODO:
    " " set vimentry references
    " if !vimentry#check('sub_vimentry', '')
    "   for vimentry in g:exES_vimentryRefs
    "     let ref_entry_dir = fnamemodify( vimentry, ':p:h')
    "     let ref_vimfiles_dirname = '.vimfiles.' . fnamemodify( vimentry, ":t:r" )
    "     let fullpath_tagfile = exUtility#GetVimFile ( ref_entry_dir, ref_vimfiles_dirname, 'tag')
    "     if has ('win32')
    "       let fullpath_tagfile = exUtility#Pathfmt( fullpath_tagfile, 'windows' )
    "     elseif has ('unix')
    "       let fullpath_tagfile = exUtility#Pathfmt( fullpath_tagfile, 'unix' )
    "     endif
    "     if findfile ( fullpath_tagfile ) != ''
    "       let &tags .= ',' . fullpath_tagfile
    "     endif
    "   endfor
    " endif

    " finally we need to generate shell scripts for :Update command
    " TODO: call exUtility#CreateQuickGenProject ()

    " ===================================
    " run customized scripts
    " ===================================

    if exists('*g:exvim_post_init')
        call g:exvim_post_init()
    endif

    " ===================================
    " layout windows
    " ===================================

    " open project window
    if vimentry#check('enable_project_browser', 'true')
        let project_browser = vimentry#get( 'project_browser' )

        " NOTE: Any windows open or close during VimEnter will not invoke WinEnter,WinLeave event
        " this is why I manually call doautocmd here
        if project_browser == 'ex'
            " open ex_project window
            doautocmd BufLeave
            doautocmd WinLeave

            silent call exproject#set_file_filters( vimentry#get('file_filter',[]) )
            silent call exproject#set_file_ignore_patterns( vimentry#get('file_ignore_pattern',[]) )
            silent call exproject#set_folder_filters( vimentry#get('folder_filter',[]) )
            silent call exproject#set_folder_filter_mode( vimentry#get('folder_filter_mode','include') )

            let g:ex_project_file = g:exvim_folder . "/files.exproject"
            silent exec 'EXProject ' . g:ex_project_file

            " TODO: add dirty message in ex-project window and hint user to press \R for refresh

            " back to edit window
            doautocmd BufLeave
            doautocmd WinLeave
            call ex#window#goto_edit_window()

        elseif project_browser == 'nerdtree'

            " Example: let g:NERDTreeIgnore=['.git$[[dir]]', '.o$[[file]]']
            let g:NERDTreeIgnore = [] " clear ignore list
            let file_ignore_pattern = vimentry#get('file_ignore_pattern')  
            if type(file_ignore_pattern) == type([])
                for pattern in file_ignore_pattern
                    silent call add ( g:NERDTreeIgnore, pattern.'[[file]]' )
                endfor
            endif

            if vimentry#check( 'folder_filter_mode',  'exclude' )
                let folder_filter = vimentry#get('folder_filter')  
                if folder_filter == type([])
                    for pattern in folder_filter
                        silent call add ( g:NERDTreeIgnore, pattern.'[[dir]]' )
                    endfor
                endif
            endif

            " open nerdtree window
            doautocmd BufLeave
            doautocmd WinLeave
            silent exec 'NERDTree'

            " back to edit window
            doautocmd BufLeave
            doautocmd WinLeave
            call ex#window#goto_edit_window()
        endif
    endif
endfunction
" }}}

" exconfig#gen_sh_update_ctags {{{
function exconfig#gen_sh_update_ctags(path) 
    " get ctags cmd
    let ctags_cmd = 'ctags'
    if executable('ctags')
        let ctags_cmd = 'ctags'
    elseif executable('exuberant-ctags')
        " On Debian Linux, exuberant ctags is installed as exuberant-ctags
        let ctags_cmd = 'exuberant-ctags'
    elseif executable('exctags')
        " On Free-BSD, exuberant ctags is installed as exctags
        let ctags_cmd = 'exctags'
    elseif executable('ctags.exe')
        let ctags_cmd = 'ctags.exe'
    elseif executable('tags')
        let ctags_cmd = 'tags'
    else
        ex#warning("Can't find ctags command in your system. Please install it first!")
    endif

    " get ctags options
    " TODO:
    let ctags_optioins = ''

    " generate scripts
    if ex#is_windows()
        let fullpath = a:path . '/update_tags.bat'
        let scripts = [] 
    else
        let fullpath = a:path . '/update_tags.sh'
        let scripts = [
                    \ '# initliaze'                                                  ,
                    \ 'path='.a:path                                                 ,
                    \ 'ctags_cmd='.ctags_cmd                                         ,
                    \ 'ctags_options='.ctags_optioins                                ,
                    \ 'tmp="./_exvim_tags"'                                          ,
                    \ 'target="${path}/tags"'                                        ,
                    \ ''                                                             ,
                    \ '# create tags'                                                ,
                    \ 'echo "Creating Tags..."'                                      ,
                    \ ''                                                             ,
                    \ '# choose ctags path first'                                    ,
                    \ 'if [ -f "${path}/files" ]; then'                              ,
                    \ '    ctags_parse_files="-L ${path}/files"'                     ,
                    \ 'else'                                                         ,
                    \ '    ctags_parse_files="-R ."'                                 ,
                    \ 'fi'                                                           ,
                    \ ''                                                             ,
                    \ '# process tags by langugage'                                  ,
                    \ 'echo "  |- generate ${tmp}"'                                  ,
                    \ '${ctags_cmd} -o ${tmp} ${ctags_options} ${ctags_parse_files}' ,
                    \ ''                                                             ,
                    \ '# replace old file'                                           ,
                    \ 'if [ -f "${tmp}" ]; then'                                     ,
                    \ '    echo "  |- move ${tmp} to ${target}"'                     ,
                    \ '    mv -f ${tmp} ${target}'                                   ,
                    \ 'fi'                                                           ,
                    \ 'echo "  |- done!"'                                            ,
                    \ ]
    endif

    " save to file
    call writefile ( scripts, fullpath )
endfunction

" exconfig#gen_sh_update_idutils {{{
function exconfig#gen_sh_update_idutils(path) 
    " check if mkid command executable 
    if !executable('mkid')
        ex#warning("Can't find mkid command in your system. Please install it first!")
    endif

    " get folder filter options
    " TODO: 
    let folder_filter = ''

    " generate scripts
    if ex#is_windows()
        let fullpath = a:path . '/update_idutils.bat'
        " TODO 
        let scripts = [
                    \ ]
    else
        let fullpath = a:path . '/update_idutils.sh'
        let scripts = [
                    \ '# initliaze'                                                                     ,
                    \ 'path='.a:path                                                                    ,
                    \ 'tools_path='.g:ex_tools_path                                                     ,
                    \ 'folder_filter='.folder_filter                                                    ,
                    \ 'tmp="./_exvim_ID"'                                                               ,
                    \ 'target="${path}/ID"'                                                             ,
                    \ ''                                                                                ,
                    \ 'echo "Creating ID..."'                                                           ,
                    \ '# try to use auto-gen id language map'                                           ,
                    \ 'if [ -f "${path}/id-lang-autogen.map" ]; then'                                   ,
                    \ '    echo "  |- generate ID by auto-gen language map"'                            ,
                    \ '    langmap_file="${path}/id-lang-autogen.map"'                                  ,
                    \ ''                                                                                ,
                    \ '# if auto-gen map not exists we use default one in tools directory'              ,
                    \ 'else'                                                                            ,
                    \ '    echo "  |- generate ID by default language map"'                             ,
                    \ '    langmap_file="${tools_path}/idutils/id-lang.map"'                            ,
                    \ 'fi'                                                                              ,
                    \ 'mkid --file=${tmp} --include="text" --lang-map=${langmap_file} ${folder_filter}' ,
                    \ ''                                                                                ,
                    \ '# replace old file'                                                              ,
                    \ 'if [ -f "${tmp}" ]; then'                                                        ,
                    \ '    echo "  |- move ${tmp} to ${target}"'                                        ,
                    \ '    mv -f ${tmp} ${target}'                                                      ,
                    \ 'fi'                                                                              ,
                    \ 'echo "  |- done!"'                                                               ,
                    \ ]
    endif

    " save to file
    call writefile ( scripts, fullpath )
endfunction

" exconfig#update_exvim_files {{{
function exconfig#update_exvim_files()
    let shell = ''
    let shell_end = ''
    let cmd = ''
    let and = ''
    let path = './.exvim.'.g:exvim_project_name.'/'

    if ex#is_windows()
        let shell = 'cmd /c'
        let shell_end = ' & pause'
    else
        let shell = 'sh'
        let shell_end = ''
    endif

    " update tags
    if vimentry#check('enable_tags','true')
        let cmd = shell . ' ' . path.'update_tags.sh' . shell_end
        let and = ' && '
    endif

    " update IDs
    if vimentry#check('enable_gsearch','true')
        let cmd .= and 
        let cmd .= shell . ' ' . path.'update_idutils.sh' . shell_end
        let and = ' && '
    endif

    exec '!' . cmd
endfunction


" vim:ts=4:sw=4:sts=4 et fdm=marker:
