exec 'AirlineTheme kolor'

" ex
" =============================

hi clear exTransparent
hi exTransparent gui=none guifg=background term=none cterm=none ctermfg=darkgray

hi clear exCommentLable
hi link exCommentLable ErrorMsg

hi clear exConfirmLine
hi exConfirmLine gui=none guibg=#ffe4b3 term=none cterm=none ctermbg=DarkYellow

hi clear exTargetLine
hi exTargetLine gui=none guibg=#ffe4b3 term=none cterm=none ctermbg=DarkYellow

" showmarks highlight
" =============================

" For marks a-z
hi clear ShowMarksHLl
hi ShowMarksHLl term=bold cterm=none ctermbg=lightblue gui=none guibg=lightblue

" For marks A-Z
hi clear ShowMarksHLu
hi ShowMarksHLu term=bold cterm=bold ctermbg=lightred ctermfg=darkred gui=bold guibg=lightred guifg=darkred

hi clear EX_HL_cursorhl
hi EX_HL_cursorhl gui=none guibg=White term=none cterm=none ctermbg=white 

" easyhl
" =============================

hi clear EX_HL_label1
hi EX_HL_label1 gui=none guibg=lightcyan term=none cterm=none ctermbg=lightcyan

hi clear EX_HL_label2
hi EX_HL_label2 gui=none guibg=lightmagenta term=none cterm=none ctermbg=lightmagenta

hi clear EX_HL_label3
hi EX_HL_label3 gui=none guibg=lightred term=none cterm=none ctermbg=lightred

hi clear EX_HL_label4
hi EX_HL_label4 gui=none guibg=lightgreen term=none cterm=none ctermbg=lightgreen

" exproject
" =============================

hi clear ex_pj_tree_line
hi ex_pj_tree_line gui=none guifg=darkgray term=none cterm=none ctermfg=gray

hi clear ex_pj_folder_label
hi ex_pj_folder_label gui=bold guifg=brown term=bold cterm=bold ctermfg=darkred

" exgsearch
" =============================

hi clear ex_gs_linenr
hi link ex_gs_linenr LineNr

hi clear ex_gs_header
hi ex_gs_header gui=bold guifg=DarkRed guibg=LightGray term=bold cterm=bold ctermfg=DarkRed ctermbg=LightGray

hi clear ex_gs_filename
hi link ex_gs_filename Statement

