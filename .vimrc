map <leader>1 :!clear; curl -i http://localhost:4000/
map <leader>2 :!clear; curl -i http://localhost:4000/cats<CR>
map <leader>3 :!clear; curl -i http://localhost:4000/cats/felix<CR>
map <leader>4 :!clear; curl -i -X POST http://localhost:4000/cats<CR>
map <leader>5 :!clear; curl -i -X POST 'http://localhost:4000/cats?name=Garfield'<CR>
