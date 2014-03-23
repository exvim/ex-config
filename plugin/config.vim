" local functions {{{

" s:reset_vimentry_settings {{{2
function! s:reset_vimentry_settings() 
    augroup ex_title_string
        au!
        au BufNewFile,BufEnter * let &titlestring = ""
    augroup END
endfunction

" s:apply_project_type_settings {{{2
function! s:apply_project_type_settings() 
    " TODO:
endfunction

" s:apply_vimentry_settings {{{2
function! s:apply_vimentry_settings() 
    " ===================================
    " general settings
    " ===================================

    " set title
    if exists('g:ex_project_name')
        " change current title 
        let &titlestring = g:ex_project_name . ' : %t (' . expand("%:p:.:h") . '/)'
        " define the rule for other title
        augroup ex_title_string
            au!
            au BufNewFile,BufEnter * let &titlestring = g:ex_project_name . ' : %t (' . expand("%:p:.:h") . '/)'
        augroup END
    endif

    " apply project_type settings
    if exists('g:ex_project_type')
        " TODO:
        " let project_types = split( g:ex_project_type, ',' )
        " silent call exUtility#SetProjectFilter ( "file_filter", exUtility#GetFileFilterByLanguage (project_types) )
    endif

    " set tag file path
    if exists( 'g:ex_enable_tags' ) && g:ex_enable_tags == "true"
        " let &tags = &tags . ',' . g:exES_Tag
        let &tags = escape(g:exvim_files_path."/tags", " ")
    endif

    " create .exvim.xxx/hierarchies/
    if exists( 'g:ex_enable_inherits' ) && g:ex_enable_inherits == "true"
        " TODO:
        " let inherit_directory_path = g:exES_CWD.'/'.g:exES_vimfiles_dirname.'/.hierarchies' 
        " if finddir(inherit_directory_path) == ''
        "   silent call mkdir(inherit_directory_path)
        " endif
    endif

    " set cscope file path
    if exists( 'g:ex_enable_cscope' ) && g:ex_enable_cscope == "true"
        " TODO: silent call g:exCS_ConnectCscopeFile()
    endif

    " macro highlight
    if exists( 'g:ex_enable_macrohl' ) && g:ex_enable_macrohl == "true" 
        " TODO: silent call g:exMH_InitMacroList(g:exES_Macro)
    endif

    " TODO:
    " " set vimentry references
    " if exists ('g:exES_vimentryRefs')
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
    " TODO: call exUtility#CreateIDLangMap ( exUtility#GetProjectFilter("file_filter") )
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
    if exists( 'g:ex_enable_project_browser' ) && g:ex_enable_project_browser == "true"
        if exists( 'g:ex_project_browser' )
            " NOTE: Any windows open or close during VimEnter will not invoke WinEnter,WinLeave event
            " this is why I manually call doautocmd here
            if g:ex_project_browser == "ex"

                " open ex_project window
                doautocmd BufLeave
                doautocmd WinLeave
                let g:ex_project_file = g:exvim_files_path . "/files.exproject"
                silent exec 'EXProject ' . g:ex_project_file

                " back to edit window
                doautocmd BufLeave
                doautocmd WinLeave
                call ex#window#goto_edit_window()

            elseif g:ex_project_browser == "nerdtree"

                " Example: let g:NERDTreeIgnore=['.git$[[dir]]', '.o$[[file]]']
                let g:NERDTreeIgnore = [] " clear ignore list
                if exists( 'g:ex_file_ignore_pattern' )
                    if type(g:ex_file_ignore_pattern) == type([])
                        for pattern in g:ex_file_ignore_pattern
                            silent call add ( g:NERDTreeIgnore, pattern.'[[file]]' )
                        endfor
                    endif
                endif

                if exists( 'g:ex_folder_filter_mode' ) && exists( 'g:ex_folder_filter' )
                    if g:ex_folder_filter_mode == 'exclude'
                        if type(g:ex_folder_filter) == type([])
                            for pattern in g:ex_folder_filter
                                silent call add ( g:NERDTreeIgnore, pattern.'[[dir]]' )
                            endfor
                        endif
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
        end
    endif
endfunction
" }}}

" variables {{{
if !exists('g:ex_todo_keyword')
    let g:ex_todo_keyword = '
                \ NOTE
                \ WARN
                \ WARN
                \ EXAMPLE
                \ TIPS
                \ REF
                \ '
endif

if !exists('g:ex_comment_lable_keyword')
    let g:ex_comment_lable_keyword = '
                \ TEMP
                \ MODIFY
                \ ADD
                \ DELME
                \ DISABLE
                \ DEBUG
                \ TEST
                \ FIXME
                \ KEEPME
                \ BUG
                \ HACK
                \ HARDCODE
                \ REFINE
                \ REFACTORY
                \ '
endif

if !exists('g:ex_lang_filter')
    let g:ex_lang_filter = {
                \ 'asm': [ 'asm', 's', 'a51' ],
                \ 'asp': [ 'asp', 'asa' ],
                \ 'awk': [ 'awk', 'gawk', 'mawk' ],
                \ 'basic': [ 'bas', 'bi', 'bb', 'pb' ],
                \ 'batch': [ 'bat' ],
                \ 'beta': [ 'bet' ],
                \ 'c': [ 'c', 'h' ],
                \ 'cobol': [ 'cbl', 'cob' ],
                \ 'cpp': [ 'c++', 'cc', 'cp', 'cpp', 'cxx', 'h', 'h++', 'hh', 'hp', 'hpp', 'hxx' ],
                \ 'csharp': [ 'cs' ],
                \ 'css': [ 'css', 'less', 'sass' ],
                \ 'doxygen': [ 'dox', 'doxygen' ],
                \ 'eiffel': [ 'e' ],
                \ 'erlang': [ 'erl', 'hrl' ],
                \ 'fortran': [ 'fo', 'ft', 'f7', 'f9', 'f95' ],
                \ 'go': [ 'go' ],
                \ 'html': [ 'htm', 'html' ],
                \ 'java': [ 'java' ],
                \ 'javascript': [ 'js' ],
                \ 'json': [ 'json' ],
                \ 'lisp': [ 'cl', 'clisp', 'el', 'l', 'lisp', 'lsp', 'ml' ],
                \ 'lua': [ 'lua' ],
                \ 'make': [ 'mak', 'mk', 'makefile' ],
                \ 'markdown': [ 'md', 'mdown', 'mkd', 'mkdn', 'markdown', 'mdwn' ],
                \ 'matlab': [ 'm' ],
                \ 'pascal': [ 'p', 'pas' ],
                \ 'perl': [ 'pl', 'pm', 'plx', 'perl' ],
                \ 'php': [ 'php', 'php3', 'phtml' ],
                \ 'python': [ 'py', 'pyx', 'pxd', 'scons' ],
                \ 'rexx': [ 'cmd', 'rexx', 'rx' ],
                \ 'ruby': [ 'rb', 'ruby' ],
                \ 'scheme': [ 'scm', 'sm', 'sch', 'scheme' ],
                \ 'sed': [ 'sed' ],
                \ 'sh': [ 'sh', 'bsh', 'bash', 'ksh', 'zsh' ],
                \ 'shader': [ 'hlsl', 'vsh', 'psh', 'fx', 'fxh', 'cg', 'shd', 'glsl' ],
                \ 'slang': [ 'sl' ],
                \ 'sml': ['sml', 'sig' ],
                \ 'sql': ['sql' ],
                \ 'swig': [ 'swg' ],
                \ 'tcl': ['tcl', 'tk', 'wish', 'itcl' ],
                \ 'vera': ['vr', 'vri', 'vrh' ],
                \ 'verilog': [ 'v' ],
                \ 'vim': [ 'vim' ],
                \ 'wiki': [ 'wiki' ],
                \ 'xml': [ 'xml' ],
                \ 'yacc': [ 'y' ],
                \ }
endif

if !exists('g:ex_project_types')
    let g:ex_project_types = {
                \ 'build': [ 'make' ],
                \ 'clang': [ 'c', 'cpp', 'csharp', 'java' ],
                \ 'data': [ 'json', 'xml' ],
                \ 'doc': [ 'doxygen', 'markdown', 'wiki' ],
                \ 'game': [ 'c', 'cpp', 'shader', 'lua' ],
                \ 'server': [ 'python', 'javascript', 'lua', 'ruby', 'c', 'cpp', 'csharp', 'go', 'java', 'sql' ],
                \ 'shell': [ 'awk', 'batch', 'sed', 'sh' ],
                \ 'web': [ 'css', 'html', 'javascript', 'json', 'xml' ],
                \ }
endif
" }}}

" highlight group {{{
hi default exTransparent gui=none guifg=background term=none cterm=none ctermfg=darkgray
hi default exCommentLable term=standout ctermfg=darkyellow ctermbg=Red gui=none guifg=lightgray guibg=red
" }}}

" vimentry#on event registry {{{
call vimentry#on( 'reset', function('s:reset_vimentry_settings') )
call vimentry#on( 'changed', function('s:apply_vimentry_settings') )
call vimentry#on( 'project_type_changed', function('s:apply_project_type_settings') )
" }}}

" vim:ts=4:sw=4:sts=4 et fdm=marker:
