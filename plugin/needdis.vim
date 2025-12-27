if exists('g:loaded_needdis') | finish | endif
let g:loaded_needdis = 1

lua require('needdis').setup()

