.data
input:  .word 1, 9, 3, -4, 5, -10, 7, 8   # 輸入數組
kernel: .word 1, -1, 1                    # 卷積核數組
output: .word

.text
main:
    la      x1, input                  # 載入輸入數組的位址到x1寄存器
    la      x2, kernel                 # 載入卷積核數組的位址到x2寄存器
    li      x3, 8                      # 輸入數組的大小
    li      x4, 3                      # 卷積核的大小
    la      x5, output                 # 載入輸出數組的位址到x5寄存器
    sub     x6, x3, x4                 
    addi    x6, x6, 1                  # 輸出數組的大小
    add     x7, x0, x0                 # 初始化循環計數器x7
            
outer_loop:
    add     x8, x0, x0                 # 初始化內層循環計數器x8
    add     x9, x0, x0                 # 初始化累加器x9
            
inner_loop:            
    slt     x10, x8, x4                # 比較內層循環計數器和卷積核大小，結果存入x10
    beq     x10, x0, end_inner_loop    # 若內層循環計數器 >= 卷積核大小，則跳轉到 end_inner_loop
    lh      x11, 0(x1)                 # 載入輸入數組中的元素到x11寄存器
    lh      x12, 0(x2)                 # 載入卷積核數組中的元素到x12寄存器          
    mul     x13, x11, x12              # 將x11和x12相乘，結果存入x13            
    add     x9, x9, x13                # 將x13的值加到累加器x9
    addi    x8, x8, 1                  # 內層循環計數器加1
    addi    x1, x1, 4                  # 移動輸入數組的指標到下一個元素
    addi    x2, x2, 4                  # 移動卷積核數組的指標到下一個元素
    j       inner_loop                 # 跳轉到 inner_loop

end_inner_loop:
    sh      x9, 0(x5)                  # 將累加器x9的值存入輸出數組
    addi    x7, x7, 1                  # 外層循環計數器加1
    addi    x5, x5, 4                  # 移動輸出數組的指標到下一個元素
    slt     x14, x7, x6                # 比較外層循環計數器和輸出數組大小，結果存入x14
    beq     x14, x0, end_outer_loop    # 若外層循環計數器 >= 輸出數組大小，則跳轉到 end_outer_loop
    addi    x1, x1, -8                 # 移動輸入數組的指標到前一個元素
    addi    x2, x2, -12                # 移動卷積核數組的指標到前二個元素
    j       outer_loop                 # 跳轉到 outer_loop

end_outer_loop:
    # Program end