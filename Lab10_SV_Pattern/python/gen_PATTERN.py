import csv

var_name = 'pat'

# open files
in_file_name = './pattern.csv'
out_file_name = './code.txt'
in_file = open(in_file_name, 'r')
out_file = open(out_file_name, 'w')
rows = list(csv.reader(in_file))

rows.pop(0)
for row in rows:
    if(row[4] == 'L'):  row[4]  = 'Large '
    elif(row[4] == 'M'): row[4] = 'Medium'
    elif(row[4] == 'S'): row[4] = 'Small '

    if(row[0] == ''):
        break
    pat_num = '%-3d' % int(row[0])
    act_str    = '%s.act = %-7s; '     % (var_name, row[1]) if (row[1] != '') else ''
    seller_str = '%s.seller_id = %s; ' % (var_name, row[2]) if (row[2] != '') else ''
    buyer_str  = '%s.buyer_id  = %s; ' % (var_name, row[3]) if (row[3] != '') else ''
    type_str   = '%s.item_type = %s; ' % (var_name, row[4]) if (row[4] != '') else ''
    num_str    = '%s.item_num = %s; '  % (var_name, row[5]) if (row[5] != '') else ''
    amt_str    = '%s.money     = %s; '     % (var_name, row[6]) if (row[6] != '') else ''
    out_file.write(pat_num + ': begin  ' + act_str + buyer_str + seller_str + type_str + num_str + amt_str + ' end\n')

out_file.close()
