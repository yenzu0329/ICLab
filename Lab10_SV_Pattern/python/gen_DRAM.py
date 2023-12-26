import csv
import random

# out files
dram_file_name = './dram.dat'
csv_file_name = './user_info_check.csv'
dram_file = open(dram_file_name, "w")
csv_file  = open(csv_file_name, "w")
csv_writer = csv.writer(csv_file)
base_addr = 0x10000

def gen_dram_data(is_empty = 0, row = []):
    if is_empty:
        info = ['', '', '', '', '', '', '', '', '', '']
    else:
        info = row
    large_num = int(info[1]) if(info[1] != '') else random.randint(1, 62)
    mid_num   = int(info[2]) if(info[2] != '') else random.randint(1, 62)
    small_num = int(info[3]) if(info[3] != '') else random.randint(1, 62)
    exp       = int(info[5]) if(info[5] != '') else 0
    level     = info[4]
    if level == 'Copper':
        level = 3
    elif level == 'Silver':
        level = 2
    elif level == 'Gold':
        level = 1
    elif level == 'Platinum':
        level = 0
    else:
        level = random.randint(0, 3)
        if   level == 0:  exp = 0
        elif level == 1:  exp = random.randint(0, 3999)
        elif level == 2:  exp = random.randint(0, 2499)
        elif level == 3:  exp = random.randint(0, 999)
    money     = int(info[6]) if(info[6] != '') else random.randint(0, 65535)
    seller_id = int(info[7]) if(info[7] != '') else random.randint(0, 255)
    item_num  = int(info[9]) if(info[9] != '') else random.randint(0, 63)
    item_type = info[8]
    if item_type == 'Large':
        item_type = 1
    elif item_type == 'Medium':
        item_type = 2
    elif item_type == 'Small':
        item_type = 3
    else:
        item_type = random.randint(1, 3)

    shop_info = large_num * (2**26) \
                + mid_num * (2**20) \
                + small_num * (2**14) \
                + level * (2**12) \
                + exp
    user_info = money * (2**16) \
                + item_type * (2**14) \
                + item_num * (2**8) \
                + seller_id
    addr1 = '@%05X\n' % (base_addr + id_counter*8)
    addr2 = '@%05X\n' % (base_addr + id_counter*8 + 4)
    data1 = '%08X' % (shop_info)
    data2 = '%08X' % (user_info)
    data1 = data1[0:2] + ' ' + data1[2:4] + ' ' + data1[4:6] + ' ' + data1[6:8] + '\n'
    data2 = data2[0:2] + ' ' + data2[2:4] + ' ' + data2[4:6] + ' ' + data2[6:8] + '\n'
    dram_file.write(addr1)
    dram_file.write(data1)
    dram_file.write(addr2)
    dram_file.write(data2)

    if level == 3:
        level = 'Copper'
    elif level == 2:
        level = 'Silver'
    elif level == 1:
        level = 'Gold'
    elif level == 0:
        level = 'Platinum'

    if item_type == 1:
        item_type = 'Large'
    elif item_type == 2:
        item_type = 'Medium'
    elif item_type == 3:
        item_type = 'Small'
    
    new_row = [id_counter, large_num, mid_num, small_num, level, exp, money, seller_id, item_type, item_num]
    csv_writer.writerow(new_row)

id_counter = 0
with open("./user_info.csv", 'r') as in_file:
    rows = list(csv.reader(in_file))
    csv_writer.writerow(rows[0])
    rows.pop(0)
    for row in rows:
        if row[0] == '':
            break
        id = int(row[0])
        while(id >= id_counter):
            if id != id_counter:
                gen_dram_data(is_empty = 1)
            else:
                gen_dram_data(row = row)
            id_counter += 1
while id_counter <= 255:
    gen_dram_data(is_empty = 1)
    id_counter += 1

dram_file.close()
csv_file.close()