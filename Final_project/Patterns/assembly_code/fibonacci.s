.data
N:      .word 10                  # 求第10項費波那契數
result: .word 0                   # 存儲計算結果

.text
main:
    la      x1, result
    lh      x2, N                 # 載入要求的費波那契數項數到x2寄存器
    add     x3, x0, x0            # 初始化迴圈計數器x3
    add     x4, x0, x0            # 初始化第一項費波那契數
    li      x5, 1                 # 初始化第二項費波那契數
    beq     x2, x0, end_loop    
    addi    x3, x3, 2             # 要求的費波那契數項數減2，因已經初始化了前兩項
    
loop:    
    add     x6, x4, x5            # 計算下一項費波那契數，結果存入x6
    addi    x3, x3, 1             # 迴圈計數器加1
    beq     x3, x2, end_loop      # 若迴圈計數器 == 要求的費波那契數項數，則跳轉到end_loop
    add     x4, x5, x0            # 更新前兩項費波那契數
    add     x5, x6, x0    
    j       loop                  # 跳轉到loop
    
end_loop:    
    sh      x6, 0(x1)             # 將最後一項費波那契數存入result
    # Program end  