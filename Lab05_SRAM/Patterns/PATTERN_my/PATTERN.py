import numpy as np

in_file  = open("input.txt", 'w')
out_file = open("output.txt", 'w')
i_pat = 0
mat_size_list = [2, 4, 8, 16]
matrics = []

def add(a, b):
    string = str(a) + '+' + str(b)
    return int(eval(string))

def generate_corner_case():
    global matrics
    for i in range(4):
        string  = '#%d\n' % (i)
        in_file.write(string)
        out_file.write(string)

        string  = 'matrix_size=%d\n' % (i)
        in_file.write(string)

        for j in range(16):
            string  = '%d\n' % (j)
            for y in range(mat_size_list[i]):
                for x in range(mat_size_list[i]):
                    string += '  127 '
                string += '\n'
            in_file.write(string)

        for j in range(16):
            string  = '%d\n' % (16+j)
            for y in range(mat_size_list[i]):
                for x in range(mat_size_list[i]):
                    string += ' -128 '
                string += '\n'
            in_file.write(string)

        in_file.write('\n')

        mat_a = np.full((mat_size_list[i], mat_size_list[i]), 127)
        mat_b = np.full((mat_size_list[i], mat_size_list[i]), 127)
        mat_c = np.full((mat_size_list[i], mat_size_list[i]), 127)
        mat_ab = np.matmul(mat_a, mat_b)
        mat_abc = np.matmul(mat_ab, mat_c)
        trace = 0
        for k in range(mat_size_list[i]):
            trace = add(trace, mat_abc[k][k])

        for j in range(5):
            string  = '%d ' % (j)
            string += 'transpose=%d  ' % (j%4)
            string += 'id=0 1 2\n'
            in_file.write(string)

            string  = '%d ' % (j)
            string += '%d\n' % (trace)
            out_file.write(string)

        mat_a = np.full((mat_size_list[i], mat_size_list[i]), -128)
        mat_b = np.full((mat_size_list[i], mat_size_list[i]), -128)
        mat_c = np.full((mat_size_list[i], mat_size_list[i]), -128)
        mat_ab = np.matmul(mat_a, mat_b)
        mat_abc = np.matmul(mat_ab, mat_c)
        trace = 0
        for k in range(mat_size_list[i]):
            trace = add(trace, mat_abc[k][k])

        for j in range(5):
            string  = '%d ' % (5+j)
            string += 'transpose=%d  ' % (j%4)
            string += 'id=16 17 18\n'
            in_file.write(string)

            string  = '%d ' % (j+5)
            string += '%d\n' % (trace)
            out_file.write(string)

        in_file.write('\n---\n')
        out_file.write('\n---\n')
        matrics = []

def generate_random_case(s = 0):
    global matrics
    string  = '#%d\n' % (i_pat)
    in_file.write(string)
    out_file.write(string)

    string  = 'matrix_size=%d\n' % (s)
    in_file.write(string)

    mat_size = mat_size_list[s]
    for i in range(32):
        matrix = np.random.randint(-128, 128, mat_size*mat_size).reshape(mat_size, mat_size)
        matrics.append(matrix)
        string  = '%d\n' % (i)
        for y in range(mat_size):
            for x in range(mat_size):
                string += ' %4d ' % (matrix[y][x])
            string += '\n'
        in_file.write(string)
    
    in_file.write('\n')

    for i in range(10):
        mode = np.random.randint(0, 4)
        mat_idx = np.random.randint(0, 32, 3)
        mat_a = matrics[mat_idx[0]]
        mat_b = matrics[mat_idx[1]]
        mat_c = matrics[mat_idx[2]]
        if(mode == 1):
            mat_a = mat_a.T
        elif(mode == 2):
            mat_b = mat_b.T
        elif(mode ==3):
            mat_c = mat_c.T
        mat_ab = np.matmul(mat_a, mat_b)
        mat_abc = np.matmul(mat_ab, mat_c)
        trace = 0
        for k in range(mat_size):
            trace = add(trace, mat_abc[k][k])

        string  = '%d ' % (i)
        string += 'transpose=%d  ' % (mode)
        string += 'id=%d %d %d\n' % (mat_idx[0], mat_idx[1], mat_idx[2])
        in_file.write(string)

        string  = '%d ' % (i)
        string += '%d\n' % (trace)
        out_file.write(string)

    in_file.write('\n---\n')
    out_file.write('\n---\n')
    matrics = []

if __name__ == '__main__':
    pattern_num = int(input("pattern number: "))
    corner_case = input("corner case? (Y/N): ")
    if(corner_case == 'Y'):
        string = 'pattern_num=%d\n' % (pattern_num+4)
    else:
        string = 'pattern_num=%d\n' % (pattern_num)
    in_file.write(string)

    if(corner_case == 'Y'):
        generate_corner_case()
    while i_pat < pattern_num*0.25:
        generate_random_case(0)
        i_pat += 1
    while i_pat < pattern_num*0.5:
        generate_random_case(1)
        i_pat += 1
    while i_pat < pattern_num*0.75:
        generate_random_case(2)
        i_pat += 1
    while i_pat < pattern_num:
        generate_random_case(3)
        i_pat += 1

    in_file.close()
    out_file.close()