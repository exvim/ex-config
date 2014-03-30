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

    " set folder filter to g:exvim_root_folders
    let g:exvim_root_folders = copy(vimentry#get('folder_filter', []))
    if !empty(g:exvim_root_folders)
        " we need search the root directory, and add folders that not excluded
        if vimentry#check('folder_filter_mode', 'exclude')
            let folder_pattern = ex#pattern#last_words(g:exvim_root_folders)
            let filelist = split(globpath(cwd,'*'),'\n')
            let g:exvim_root_folders = []
            for name in filelist
                if isdirectory(name)
                    let name = fnamemodify(name,':t')
                    if match( name, folder_pattern ) == -1
                        silent call add ( g:exvim_root_folders, name )
                    endif
                endif
            endfor
        endif
    else
        let filelist = split(globpath(cwd,'*'),'\n')
        for name in filelist
            if isdirectory(name)
                let name = fnamemodify(name,':t')
                silent call add ( g:exvim_root_folders, name )
            endif
        endfor
    endif

    " set tag file path
    if vimentry#check('enable_tags', 'true')
        let s:old_tagrelative=&tagrelative
        let &tagrelative=0 " set notagrelative

        let s:old_tags=&tags
        let &tags=escape(g:exvim_folder."/tags", " ")

        call exconfig#gen_sh_update_files(g:exvim_folder)
        call exconfig#gen_sh_update_ctags(g:exvim_folder)

        " symbols
        if vimentry#check('enable_symbols', 'true')
            call exconfig#gen_sh_update_symbols(g:exvim_folder)
        endif

        " create .exvim.xxx/hierarchies/
        if vimentry#check('enable_inherits', 'true')
            " TODO:
            " let inherit_directory_path = g:exES_CWD.'/'.g:exES_vimfiles_dirname.'/.hierarchies'
            " if finddir(inherit_directory_path) == ''
            "   silent call mkdir(inherit_directory_path)
            " endif
        endif
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

" exconfig#gen_sh_update_files {{{
function exconfig#gen_sh_update_files(path)
    " generate scripts
    if ex#os#is('windows')
        " check if gawk command executable
        if !executable('gawk')
            call ex#warning("Can't find gawk command in your system. Please install it first!")
        endif

        let folder_pattern = ""
        for name in g:exvim_root_folders
            let folder_pattern .= '"' . name . '" '
        endfor

        let file_pattern = ''
        let file_filters = vimentry#get('file_filter', [])
        if !empty(file_filters)
            for name in file_filters
                let file_pattern .= '*.' . toupper(name) . ' '
            endfor
        else
            let file_pattern=''
        endif

        let file_pattern_gawk = ''
        let file_filters = vimentry#get('file_filter', [])
        if !empty(file_filters)
            for name in file_filters
                let file_pattern_gawk .= '\\.' . name . '$|'
            endfor
            let file_pattern_gawk = strpart( file_pattern_gawk, 0, len(file_pattern_gawk) - 1)
        else
            let file_pattern_gawk=''
        endif

        let fullpath = a:path . '/update-filelist.bat'
        let winpath = ex#path#translate(a:path,'windows')
        let wintoolpath = ex#path#translate(g:ex_tools_path,'windows')
        let wintoolpath = expand(wintoolpath)
        let scripts = [
                    \ '@echo off'                                    ,
                    \ 'set DEST='.winpath                            ,
                    \ 'set TOOLS='.wintoolpath                       ,
                    \ 'set FOLDERS='.folder_pattern                  ,
                    \ 'set FILE_SUFFIXS='.file_pattern               ,
                    \ 'set FILE_FILTER_PATTERN='.file_pattern_gawk   ,
                    \ 'set TMP=%DEST%\_files_gawk'                   ,
                    \ 'set TMP2=%DEST%\_files'                       ,
                    \ 'set TARGET=%DEST%\files'                      ,
                    \ 'call %TOOLS%\shell\batch\update-filelist.bat' ,
                    \ ]
    else
        let folder_pattern = ''
        for name in g:exvim_root_folders
            let folder_pattern .= '"./' . name . '" '
        endfor

        let file_pattern = ''
        let file_filters = vimentry#get('file_filter', [])
        if !empty(file_filters)
            for name in file_filters
                let file_pattern .= substitute(name, "\+", "\\\\+", "g") . '|'
            endfor
            let file_pattern = strpart( file_pattern, 0, len(file_pattern) - 1)
        else
            let file_pattern='.*'
        endif

        let fullpath = a:path . '/update-filelist.sh'
        let scripts = [
                    \ 'export DEST='.a:path                        ,
                    \ 'export TOOLS="'.expand(g:ex_tools_path).'"' ,
                    \ 'export FOLDERS="'.folder_pattern.'"'        ,
                    \ 'export FILE_SUFFIXS="'.file_pattern.'"'     ,
                    \ 'export TMP="${DEST}/_files"'                ,
                    \ 'export TARGET="${DEST}/files"'              ,
                    \ 'sh ${TOOLS}/shell/bash/update-filelist.sh'  ,
                    \ ]
    endif

    " save to file
    call writefile ( scripts, fullpath )
endfunction

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
        call ex#warning("Can't find ctags command in your system. Please install it first!")
    endif

    " get ctags options
    " TODO:
    let ctags_optioins = ''

    " generate scripts
    if ex#os#is('windows')
        let fullpath = a:path . '/update-tags.bat'
        let winpath = ex#path#translate(a:path,'windows')
        let wintoolpath = ex#path#translate(g:ex_tools_path,'windows')
        let wintoolpath = expand(wintoolpath)
        let scripts = [
                    \ '@echo off'                                ,
                    \ 'set DEST='.winpath                        ,
                    \ 'set TOOLS='.wintoolpath                   ,
                    \ 'set CTAGS_CMD='.ctags_cmd                 ,
                    \ 'set OPTIONS='.ctags_optioins              ,
                    \ 'set TMP=.\_exvim_tags'                    ,
                    \ 'set TARGET=%DEST%\tags'                   ,
                    \ 'call %TOOLS%\shell\batch\update-tags.bat' ,
                    \ ]
    else
        let fullpath = a:path . '/update-tags.sh'
        let scripts = [
                    \ 'export DEST="'.a:path.'"'                   ,
                    \ 'export TOOLS="'.expand(g:ex_tools_path).'"' ,
                    \ 'export CTAGS_CMD="'.ctags_cmd.'"'           ,
                    \ 'export OPTIONS="'.ctags_optioins.'"'        ,
                    \ 'export TMP="./_exvim_tags"'                 ,
                    \ 'export TARGET="${DEST}/tags"'               ,
                    \ 'sh ${TOOLS}/shell/bash/update-tags.sh'      ,
                    \ ]
    endif

    " save to file
    call writefile ( scripts, fullpath )
endfunction

" exconfig#gen_sh_update_symbols {{{
function exconfig#gen_sh_update_symbols(path)
    " check if gawk command executable
    if !executable('gawk')
        call ex#warning("Can't find gawk command in your system. Please install it first!")
    endif

    " generate scripts
    if ex#os#is('windows')
        let fullpath = a:path . '/update-symbols.bat'
        let winpath = ex#path#translate(a:path,'windows')
        let wintoolpath = ex#path#translate(g:ex_tools_path,'windows')
        let wintoolpath = expand(wintoolpath)
        let scripts = [
                    \ '@echo off'                                   ,
                    \ 'set DEST='.winpath                           ,
                    \ 'set TOOLS='.wintoolpath                      ,
                    \ 'set TMP=.\_symbols.exsymbol'                 ,
                    \ 'set TARGET=%DEST%\symbols.exsymbol'          ,
                    \ 'call %TOOLS%\shell\batch\update-symbols.bat' ,
                    \ ]
    else
        let fullpath = a:path . '/update-symbols.sh'
        let scripts = [
                    \ 'export DEST="'.a:path.'"'                   ,
                    \ 'export TOOLS="'.expand(g:ex_tools_path).'"' ,
                    \ 'export TMP="./_symbols.exsymbol"'           ,
                    \ 'export TARGET="${DEST}/symbols.exsymbol"'   ,
                    \ 'sh ${TOOLS}/shell/bash/update-symbols.sh'   ,
                    \ ]
    endif

    " save to file
    call writefile ( scripts, fullpath )
endfunction

" exconfig#gen_sh_update_idutils {{{
function exconfig#gen_sh_update_idutils(path)
    " check if mkid command executable
    if !executable('mkid')
        call ex#warning("Can't find mkid command in your system. Please install it first!")
    endif

    " get folder filter options
    " TODO:
    let folder_filter = ''

    " generate scripts
    if ex#os#is('windows')
        let fullpath = a:path . '/update-idutils.bat'
        let winpath = ex#path#translate(a:path,'windows')
        let wintoolpath = ex#path#translate(g:ex_tools_path,'windows')
        let wintoolpath = expand(wintoolpath)
        let scripts = [
                    \ '@echo off'                                   ,
                    \ 'set DEST='.winpath                           ,
                    \ 'set TOOLS='.wintoolpath                      ,
                    \ 'set FOLDER_FILTER='.folder_filter            ,
                    \ 'set TMP=.\_exvim_ID'                         ,
                    \ 'set TARGET=%DEST%\ID'                        ,
                    \ 'call %TOOLS%\shell\batch\update-idutils.bat' ,
                    \ ]
    else
        let fullpath = a:path . '/update-idutils.sh'
        let scripts = [
                    \ 'export DEST="'.a:path.'"'                   ,
                    \ 'export TOOLS="'.expand(g:ex_tools_path).'"' ,
                    \ 'export FOLDER_FILTER="'.folder_filter.'"'   ,
                    \ 'export TMP="./_exvim_ID"'                   ,
                    \ 'export TARGET="${DEST}/ID"'                 ,
                    \ 'sh ${TOOLS}/shell/bash/update-idutils.sh'   ,
                    \ ]
    endif

    " save to file
    call writefile ( scripts, fullpath )
endfunction

" exconfig#update_exvim_files {{{
function exconfig#update_exvim_files()
    if ex#os#is('windows')
        let shell_silent = 'silent'
        let shell_exec = 'call'
        let shell_and = ' & '
        let shell_pause = ' && pause'
        let suffix = '.bat'
        let path = '.\.exvim.'.g:exvim_project_name.'\'
    else
        let shell_silent = ''
        let shell_exec = 'sh'
        let shell_and = ' && '
        let shell_pause = ''
        let suffix = '.sh'
        let path = './.exvim.'.g:exvim_project_name.'/'
    endif

    let cmd = ''
    let and = ''

    " update filelist, tags, symbols
    if vimentry#check('enable_tags','true')
        let cmd = shell_exec . ' ' . path.'update-filelist'.suffix
        let and = shell_and

        let cmd .= and
        let cmd .= shell_exec . ' ' . path.'update-tags'.suffix

        let cmd .= and
        let cmd .= shell_exec . ' ' . path.'update-symbols'.suffix
    endif

    " update IDs
    if vimentry#check('enable_gsearch','true')
        let cmd .= and
        let cmd .= shell_exec . ' ' . path.'update-idutils'.suffix
        let and = shell_and
    endif

    let cmd .= shell_pause
    call ex#hint('exVim Updating...')
    exec shell_silent . ' !' . cmd
    call ex#hint('exVim Update Finish!')
endfunction



