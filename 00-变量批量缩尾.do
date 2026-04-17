**# 批量连续变量缩尾
global var_winsor "  "

winsor2 $var_winsor, cuts(1 99) suffix(_w99)

sum *_w99
