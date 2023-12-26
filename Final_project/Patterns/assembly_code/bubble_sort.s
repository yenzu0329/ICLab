.data
array:  .word 9, -4, 7, 2, 1, 8, 5, 3, -6  # 待排序的數組
size:   .word 9                            # 數組的大小
 
.text 
main: 
    la      x1, array                      # 載入數組的位址到x1寄存器
    lw      x2, size                       # 載入數組的大小到x2寄存器
    li      x3, 1                          # 初始化循環計數器x3
    
outer_loop: 
    add     x4, x3, x0                     # 初始化內層循環計數器x4
    add     x5, x1, x0                     # 初始化標記是否有交換的變量x5
                  
inner_loop: 
    slt     x6, x4, x2                     # 比較內層循環計數器和數組大小，結果存入x6
    beq     x6, x0, end_inner_loop         # 若內層循環計數器 >= 數組大小，則跳轉到 end_inner_loop
    lh      x7, 0(x5) 
    lh      x8, 4(x5) 
    slt     x9, x8, x7                     # 比較兩個元素的大小，結果存入x9
    beq     x9, x0, no_swap                # 若x8 >= x7，則跳轉到 no_swap
    sw      x8, 0(x5) 
    sw      x7, 4(x5) 
 
no_swap: 
    addi    x4, x4, 1                      # 內層循環計數器加1
    addi    x5, x5, 4                      # 移動數組的指標到下一個元素
    j       inner_loop                     # 跳轉到 inner_loop

end_inner_loop:
    addi    x3, x3, 1                      # 循環計數器加1
    slt     x10, x3, x2         
    beq     x10, x0, end_outer_loop
    j       outer_loop

end_outer_loop:
    # Program end