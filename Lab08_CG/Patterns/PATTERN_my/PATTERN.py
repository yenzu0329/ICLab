# input  : 6*6 image (8-bit)
# output : 4*1 encoding (8-bit)
# layers : 3*3 conv -> quantization -> 2*2 max-pooling -> fc -> quantization

import numpy as np

CORNER_CASE = 1
PAT_NUM = 10

in_file  = open("input.txt", 'w')
out_file = open("output.txt", 'w')
check_file = open("check.txt", 'w')

def conv(img, ker):
    ker_size = ker.shape[0]
    out_size = img.shape[0] - ker.shape[0] + 1
    output = np.zeros((out_size, out_size))
    for i in range(out_size):
        for j in range(out_size):
            for m in range(ker_size):
                for n in range(ker_size):
                    output[i][j] += img[i+m][j+n] * ker[m][n]
    return output

def quantize(img, base):
    height = img.shape[0]
    width  = img.shape[1]
    output = np.zeros((height, width))
    for i in range(height):
        for j in range(width):
            output[i][j] = int(img[i][j] / base)
    return output

def max_pooling(img): # 4*4 -> 2*2
    img_size = img.shape[0]
    out_size = int(img.shape[0]/2)
    output = np.zeros((out_size, out_size))
    biggest = 0
    for i in range(out_size):
        for j in range(out_size):
            biggest = 0
            for m in range(2):
                for n in range(2):
                    if img[i*2+m][j*2+n] > biggest:
                        biggest = img[i*2+m][j*2+n]
            output[i][j] = biggest
    return output

def fc(img, weight):
    output = img @ weight
    output = output.reshape(4, 1)
    return output


def CNN(img1, img2, ker, weight):
    fm1_1 = conv(img1, ker)
    fm2_1 = quantize(fm1_1, 2295)
    fm3_1 = max_pooling(fm2_1)
    fm4_1 = fc(fm3_1, weight)
    fm5_1 = quantize(fm4_1, 510)

    fm1_2 = conv(img2, ker)
    fm2_2 = quantize(fm1_2, 2295)
    fm3_2 = max_pooling(fm2_2)
    fm4_2 = fc(fm3_2, weight)
    fm5_2 = quantize(fm4_2, 510)

    write_check_file("input image",     [img1, img2])
    write_check_file("convolution",     [fm1_1, fm1_2])
    write_check_file("quantization 1",  [fm2_1, fm2_2])
    write_check_file("max pooling",     [fm3_1, fm3_2])
    write_check_file("fully connected", [fm4_1, fm4_2])
    write_check_file("quantization 2",  [fm5_1, fm5_2])
    return fm5_1, fm5_2

def L1_dist(vec1, vec2):
    vec_size = vec1.shape[0]
    distance = 0
    for i in range(vec_size):
        distance += abs(vec1[i][0] - vec2[i][0])
    print(distance)
    return distance

def write_check_file(name, arr):
    check_file.write("["+name+"]\n")
    arr_h = arr[0].shape[0]
    arr_w = arr[0].shape[1]
    for i in range(2):
        check_file.write(' #'+str(i))
        for j in range(arr_w):
            if name == 'convolution':
                check_file.write('%9d' % (j))
            elif arr_w == 1:
                check_file.write('%7d' % (j))
            else:
                check_file.write('%6d' % (j))
        check_file.write('     ')
    check_file.write('\n')
    for i in range(2):
        check_file.write('---')
        for j in range(arr_w):
            if name == 'convolution':
                check_file.write('---------')
            elif arr_w == 1:
                check_file.write('-------')
            else:
                check_file.write('------')
        check_file.write('     ')
    check_file.write('\n')
    for j in range(arr_h):
        for i in range(2):
            check_file.write(' '+str(j)+'|')
            for k in range(arr_w):
                if name == 'convolution':
                    check_file.write('%9d' % (arr[i][j][k]))
                elif arr_w == 1:
                    check_file.write('%7d' % (arr[i][j][k]))
                else:
                    check_file.write('%6d' % (arr[i][j][k]))
            check_file.write('     ')
        check_file.write('\n')
    check_file.write('\n\n')

def write_in_file(image_1, image_2, kernel, weight):
    image_1.tofile(in_file, sep=' ', format='%s')
    in_file.write('\n')
    image_2.tofile(in_file, sep=' ', format='%s')
    in_file.write('\n')
    kernel.tofile(in_file, sep=' ', format='%s')
    in_file.write('\n')
    weight.tofile(in_file, sep=' ', format='%s')
    in_file.write('\n')

def write_out_file(ans):
    out_file.write(str(int(ans))+'\n')

def generate_random_case():
    image_1 = np.random.randint(0, 256, 6*6).reshape(6, 6)
    image_2 = np.random.randint(0, 256, 6*6).reshape(6, 6)
    kernel  = np.random.randint(0, 256, 3*3).reshape(3, 3)
    weight  = np.random.randint(0, 256, 2*2).reshape(2, 2)
    encode_1, encode_2 = CNN(image_1, image_2, kernel, weight)
    distance = L1_dist(encode_1, encode_2)
    ans = distance if distance >= 16 else 0

    write_in_file(image_1, image_2, kernel, weight)
    write_out_file(ans)

def generate_corner_case():
    image_1 = np.full((6, 6), 255)
    image_2 = np.full((6, 6), 0)
    kernel  = np.full((3, 3), 255)
    weight  = np.full((2, 2), 255)
    encode_1, encode_2 = CNN(image_1, image_2, kernel, weight)
    distance = L1_dist(encode_1, encode_2)

    write_in_file(image_1, image_2, kernel, weight)
    write_out_file(distance)

if __name__ == '__main__':
    in_file.write('pattern_num=%d\n' % (PAT_NUM))
    if CORNER_CASE:
        string =  '=================\n'
        string += '   Corner Case   \n'
        string += '=================\n\n'
        check_file.write(string)
        generate_corner_case()
    start_idx = 1 if CORNER_CASE else 0
    for i in range(start_idx, PAT_NUM):
        string =  '============\n'
        string += '   NO.%03d  \n' % (i)
        string += '============\n\n'
        check_file.write(string)
        generate_random_case()