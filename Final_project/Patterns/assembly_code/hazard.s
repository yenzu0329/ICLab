.data
in1:  .word 0
in2:  .word 0

.text
main:
    la      x1,in1 
    la      x2,in2
    li	    x1,-1
    li	    x3,-1
    add	    x1,x1,x3
    add	    x1,x1,x3
    add	    x1,x1,x3
    mul	    x1,x1,x3
    mul	    x1,x1,x3
    li	    x3,-2
    mul	    x1,x3,x1
    mul	    x1,x3,x1
    mul	    x1,x3,x1
    add	    x1,x3,x1
    add	    x1,x3,x1
    sh	    x1,0(x2)
    addi	x2,x2,4
    li	    x1,0
    li	    x3,-1
    sub	    x1,x1,x3
    sub	    x1,x1,x3
    sub	    x1,x1,x3
    sub	    x1,x1,x3
    sub	    x1,x1,x3
    li	    x3,-3
    mul	    x1,x3,x1
    mul	    x1,x3,x1
    mul	    x1,x3,x1
    sub	    x1,x3,x1
    sub	    x1,x3,x1
    sh	    x1,0(x2)
    addi	x2,x2,4
    li	    x1,-1
    li	    x3,1
    slt	    x1,x1,x3
    slt	    x1,x1,x3
    slt	    x1,x1,x3
    slt	    x1,x1,x3
    slt	    x1,x1,x3
    li	    x3,-1
    slt	    x1,x3,x1
    slt	    x1,x3,x1
    slt	    x1,x3,x1
    slt	    x1,x3,x1
    slt	    x1,x3,x1
    sh	    x1,0(x2)
    addi	x2,x2,4
    lh	    x1,0(x1)
    lh	    x1,0(x1)
    lh	    x1,0(x1)
    lh	    x1,0(x1)
    lh	    x1,0(x1)
    addi	x1,x1,20
    lh	    x3,-4(x1)
    lh	    x4,-8(x1)
    lh	    x5,-12(x1)
    lh	    x6,-16(x1)
    lh	    x7,-20(x1)
    add	    x3,x3,x6
    add	    x4,x4,x5
    sub	    x3,x3,x4
    add	    x3,x3,x7
    add	    x1,x1,x3
    addi	x2,x2,16
    sh	    x1,-16(x2)
    lh	    x3,-16(x2)
    lh	    x4,-16(x2)
    lh	    x5,-16(x2)
    lh	    x6,-16(x2)
    sh	    x3,-12(x2)
    sh	    x4,-8(x2)
    sh	    x5,-4(x2)
    sh	    x6,0(x2)
    addi	x2,x2,20
    sh	    x1,-4(x2)
    sh	    x3,-8(x2)
    sh	    x4,-12(x2)
    sh	    x5,-16(x2)
    sh	    x6,-20(x2)
    addi	x2,x2,20
    lh	    x7,-40(x2)
    lh	    x6,-16(x2)
    sh	    x7,-4(x2)
    sh	    x7,-8(x2)
    sh	    x7,-12(x2)
    sh	    x7,-13(x2)
    sh	    x7,-18(x2)
    lh	    x1,-16(x2)
    lh	    x3,-20(x2)
    add	    x4,x3,x1
    addi	x2,x2,4
    sh	    x4,-4(x2) 