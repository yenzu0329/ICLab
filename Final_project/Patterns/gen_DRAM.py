import csv
import random

# TODO: locality of data memory access 

# ======== User modification part ========
SPECIAL_CASE = 1
REGEN_DRAM = 1
DATA_MIN = -100
DATA_MAX = 100
branch_jump_percent = 40
funcs = ['ADD', 'SUB', 'SLT', 'MUL', 'LH', 'LH', 'LH', 'SH', 'SH', 'SH', 'BEQ']
# =================================
IDX_MAX = (0x2000 - 0x1000) // 2

insts = []
mem   = []
special_insts_len = 0

def readDataDRAM():
    global mem
    f = open("checker/DRAM_data.csv", 'r')
    rows = list(csv.reader(f))
    rows.pop(0)
    mem = []
    for row in rows:
        mem.append(int(row[1]))
    f.close()


def readInstDRAM():
    global insts
    f1 = open("checker/DRAM_inst.csv", 'r')
    rows = list(csv.reader(f1))
    rows.pop(0)
    insts = []
    for row in rows:
        if row[1] == 'J':
            jump_addr = (int(row[2], 16) - 0x1000) // 2
            insts.append([row[0], row[1], jump_addr])
        else:
            insts.append([row[0], row[1], int(row[2]), int(row[3]), int(row[4])])
    f1.close()

def run():
    timestamp_file = open("checker/Timestamp.csv", 'w', newline='')
    csv_writer = csv.writer(timestamp_file)
    csv_writer.writerow(['cycle', 'PC', 'func', 'mem', 'x0', 'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8', 'x9', 'x10', 'x11', 'x12', 'x13', 'x14', 'x15'])
    idx = 0
    counter = 0
    reg = [0] * 16
    prev_mem_idx = 0
    inst_len = len(insts)
    while idx < inst_len:
        inst = insts[idx]
        func_name = inst[1]
        curr_idx = idx
        if func_name == 'J':
            idx = inst[2]
        else:
            rs, rt, rd, imm = inst[2], inst[3], inst[4], inst[4]
            if   func_name in ['ADD', 'SUB', 'SLT', 'MUL']:
                if   func_name == 'ADD':   temp_rd = reg[rs] + reg[rt]
                elif func_name == 'SUB':   temp_rd = reg[rs] - reg[rt]
                elif func_name == 'SLT':   temp_rd = reg[rs] < reg[rt]
                elif func_name == 'MUL':   temp_rd = reg[rs] * reg[rt]
                if temp_rd & 0x8000:
                    temp_rd = temp_rd | ~0xFFFF
                else:
                    temp_rd = temp_rd & 0xFFFF
                reg[rd] = temp_rd
            elif func_name in ['LH', 'SH']:
                mem_idx = reg[rs] + imm
                curr_rs = rs
                # modify rs
                '''
                # memory access with locality
                while reg[rs] < prev_mem_idx-47 or reg[rs] > prev_mem_idx+47:
                    rs = (rs + 1) % 16
                    if rs == curr_rs:
                        while reg[rs] < -15 or reg[rs] >= len(mem) + 16:
                            rs = (rs + 1) % 16
                            if rs == curr_rs:
                                print("memory access error")
                                for i, r in enumerate(reg):
                                    print('reg[{}] = {}'.format(i, r))
                                return
                mem_idx = reg[rs] + imm
                # modify imm
                if mem_idx < 0 or mem_idx < prev_mem_idx-32:
                    imm = 15
                elif mem_idx >= len(mem) or mem_idx > prev_mem_idx+31:
                    imm = -16
                mem_idx = reg[rs] + imm
                '''
                while reg[rs] < -15 or reg[rs] >= len(mem) + 16:
                    rs = (rs + 1) % 16
                    if rs == curr_rs:
                        print("memory access error")
                        for i, r in enumerate(reg):
                            print('reg[{}] = {}'.format(i, r))
                        return
                
                mem_idx = reg[rs] + imm
                # modify imm
                if mem_idx < 0:
                    imm = 15
                elif mem_idx >= len(mem):
                    imm = -16
                mem_idx = reg[rs] + imm
                # ---
                insts[idx][2] = rs
                insts[idx][4] = imm
                # load/store
                if func_name == 'LH':
                    reg[rt] = mem[mem_idx]
                elif func_name == 'SH':
                    mem[mem_idx] = reg[rt]
            elif func_name == 'BEQ':
                if reg[rs] == reg[rt]:
                    if idx >= special_insts_len:
                        for i in range(imm):
                            if insts[idx + i + 1][1] == 'J':
                                insts[idx][4] = i
                                break
                    idx += insts[idx][4]
            idx = idx + 1
        mem_write = 'mem[{}] = {}'.format(mem_idx, reg[rt]) if func_name == 'SH' else ''
        csv_writer.writerow(
            [counter, curr_idx, func_name, mem_write, 
             reg[0],  reg[1],  reg[2],  reg[3],
             reg[4],  reg[5],  reg[6],  reg[7],
             reg[8],  reg[9],  reg[10], reg[11],
             reg[12], reg[13], reg[14], reg[15]]
        )
        counter += 1
    timestamp_file.close() 


def writeDataDRAM():
    checker = open("checker/DRAM_data.csv", 'w', newline='')
    dat = open("DRAM_data.dat", 'w')
    csv_writer = csv.writer(checker)
    csv_writer.writerow(['addr', 'data'])
    addr = 0x1000
    for data in mem:
        addr_str = '{:04X}'.format(addr)
        data_str = '{:04X}'.format(data & 0xFFFF)
        data_str = data_str[2:4] + ' ' + data_str[0:2]
        dat.write('@'+addr_str + '\n')
        dat.write(data_str + '\n')
        csv_writer.writerow(['0x'+addr_str, data])
        addr += 2
    checker.close()
    dat.close()


def writeInstDRAM():
    checker = open("checker/DRAM_inst.csv", 'w', newline='')
    dat = open("DRAM_inst.dat", 'w')
    csv_writer = csv.writer(checker)
    csv_writer.writerow(['addr', 'func', 'rs/addr', 'rt/dest', 'rd/imm'])
    addr = 0x1000
    for inst in insts:
        func_name = inst[1]
        if func_name == 'J':
            bi_str  = '100{:013b}'.format(inst[2]*2 + 0x1000)
        else:
            rs, rt, rd, imm = inst[2], inst[3], inst[4], inst[4]
            if   func_name == 'ADD':  bi_str  = '000{:04b}{:04b}{:04b}1'.format(rs, rt, rd)
            elif func_name == 'SUB':  bi_str  = '000{:04b}{:04b}{:04b}0'.format(rs, rt, rd)
            elif func_name == 'SLT':  bi_str  = '001{:04b}{:04b}{:04b}1'.format(rs, rt, rd)
            elif func_name == 'MUL':  bi_str  = '001{:04b}{:04b}{:04b}0'.format(rs, rt, rd)
            elif func_name == 'LH':   bi_str  = '011{:04b}{:04b}{:05b} '.format(rs, rt, imm & 0x1F)
            elif func_name == 'SH':   bi_str  = '010{:04b}{:04b}{:05b} '.format(rs, rt, imm & 0x1F)
            elif func_name == 'BEQ':  bi_str  = '101{:04b}{:04b}{:05b} '.format(rs, rt, imm & 0x1F)

        hex_str  = '{:04X}'.format(int(bi_str, 2))
        addr_str = '{:04X}'.format(addr)
        inst_str = hex_str[2:4] + ' ' + hex_str[0:2]
        # write dat file
        dat.write('@' + addr_str + '\n')
        dat.write(inst_str + '     // ' + bi_str + '\n')
        # write csv file
        if   func_name == 'ADD':  comment = 'x{} = x{} + x{}'.format(rd, rs, rt)
        elif func_name == 'SUB':  comment = 'x{} = x{} - x{}'.format(rd, rs, rt)
        elif func_name == 'SLT':  comment = 'x{} = x{} < x{}'.format(rd, rs, rt)
        elif func_name == 'MUL':  comment = 'x{} = x{} * x{}'.format(rd, rs, rt)
        elif func_name == 'LH':   comment = 'x{} = mem [x{}{:+}]'.format(rt, rs, imm)
        elif func_name == 'SH':   comment = 'mem [x{}{:+}] = x{}'.format(rs, imm, rt)
        elif func_name == 'BEQ':  comment = 'if (x{} == x{}): PC = PC + {}'.format(rs, rt, imm+1)
        elif func_name == 'J':    comment = ''
        inst.extend(['', comment])
        if inst[1] == 'J':
            inst[2] = '0x{:04X}'.format(inst[2]*2 + 0x1000)
        csv_writer.writerow(inst)
        addr += 2
    checker.close()
    dat.close()


def genRandomData():
    global mem
    mem = []
    for _ in range(IDX_MAX):
        data = random.randint(DATA_MIN, DATA_MAX)
        mem.append(data)


def genRandomInst():
    global insts
    jump_from_idx = [150, 181, 187, 699, 724, 725, 750, 850, 1000, 1015, 1032, 1500, 1517, 1531, 1550, 1750]
    jump_to_idx   = [182, 188, 156, 731, 751, 700, 725, 851, 1016, 1034, 1001, 1532, 1551, 1501, 1520, 1767]
    addr = 0x1000
    insts = []
    for idx in range(16):
        rt = idx
        rs = random.randint(0, 15)
        imm = random.randint(0, 15)
        addr_str = '0x{:04X}'.format(addr)
        insts.append([addr_str, 'LH', rs, rt, imm])
        addr += 2

    for idx in range(16, IDX_MAX):
        addr_str = '0x{:04X}'.format(addr)
        if len(jump_from_idx) and idx == jump_from_idx[0]:
            insts.append([addr_str, 'J', jump_to_idx[0]])
            jump_from_idx.pop(0)
            jump_to_idx.pop(0)
            continue
        func_name = random.choice(funcs)
        rs = random.randint(0, 15)
        rt = random.randint(0, 15)
        if func_name in ['ADD', 'SUB', 'SLT', 'MUL']:
            rd = random.randint(0, 15)
            insts.append([addr_str, func_name, rs, rt, rd])
        elif func_name in ['LH', 'SH']:
            imm = random.randint(-16, 15)
            insts.append([addr_str, func_name, rs, rt, imm])
        elif func_name == 'BEQ':
            if idx > IDX_MAX-20:
                func_name = 'SH'
                imm = random.randint(-16, 15)
                insts.append([addr_str, func_name, rs, rt, imm])
            else:
                imm = random.randint(0, 15)
                rand_num = random.randint(1, 100)
                if(rand_num <= branch_jump_percent):
                    insts.append([addr_str, func_name, rs, rs, imm])
                else:
                    insts.append([addr_str, func_name, rs, rt, imm])
        addr += 2


def addSpecialCase():
    global special_insts_len
    # modify insts
    f2 = open("checker/Special_case.csv", 'r')
    rows = list(csv.reader(f2))
    rows.pop(0)
    special_insts_len = len(rows)
    for i, row in enumerate(rows):
        if row[1] == 'J':
            jump_addr = (int(row[2], 16) - 0x1000) // 2
            insts[i] = [row[0], row[1], jump_addr]
        else:
            insts[i] = [row[0], row[1], int(row[2]), int(row[3]), int(row[4])]
    f2.close()
    # modify mem
    mem[0:6] = [1, 2, 8, 3, 6, 32]
    mem[23]  = 10
    mem[62]  = 2
    mem[63]  = 9


if __name__ == '__main__':
    if REGEN_DRAM:
        genRandomData()
        genRandomInst()
    else:
        readDataDRAM()
        readInstDRAM()
    #
    if SPECIAL_CASE:
        addSpecialCase()
    #
    writeDataDRAM()
    run()
    writeInstDRAM()