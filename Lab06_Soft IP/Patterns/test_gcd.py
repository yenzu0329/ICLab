# ax+by = 1
def gcd(a, b):
    prime = a
    neg = 0
    # print(a, b)
    x1, y1 = 1, 0
    x2, y2 = 0, 1
    r = 0
    count = 0
    if b > a/2: 
        b = a-b
        neg = 1
    if b == 1:
        return -1, 1
    while r != 1:
        q = a // b
        r = a % b
        x1, x2 = x2, x1 + x2 * q
        y1, y2 = y2, y1 + y2 * q
        a = b
        b = r
        count += 1
        if(count == 5):
            print(q, end=' ')
    if(count % 2):
        y2 = -y2
    if(neg):
        y2 = -y2
    # print (count, end=" ")
        
    return y2, count

prime = [5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127]
for i in prime:
    print('%3d:' % (i), end=' ')
    max_y2 = 0
    y2 = 0
    for j in range(i):
        if j != 0 and j != 1:
            y2, count = gcd(i, j)
            if(j > i/2): count = count + 1
            print("gcd(%d, %d) = 1 | iter = %d, y = %d" % (i, j, count, y2))
            if y2 > max_y2:
                max_y2 = y2
    #print(max_y2)
    print()
