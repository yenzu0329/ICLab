import os

#WHAT NEEDS MODIFIYING
#########################################################
module_name = "CPU"
#run from long to short clk period
start = 5
end = 3
#either positive or negative stride will do
#stride = 0 only runs "start"
stride = 0.1
syn02 = True
sim03 = False
#########################################################

stride = abs(stride)
interval = end-start
if stride==0:
	iteration = 1
else:
	iteration = int(abs(interval/stride)+1)

def run(clk):
#	try:
		MET = False
		if syn02:
			os.system("./09_clean_up")
			clk_mod_fail = modify('./syn.tcl',clk)
			if clk_mod_fail:
				print("clock period not found in syn.tcl")
				return
			os.system("./01_run_dc")
			MET = record_area(module_name,clk)
		if sim03:
			modifyPATTERN("../00_TESTBED/PATTERN.v", clk)
			os.system("cd ../03_GATE/ && ./09_clean_up && ./01_run")
		return MET
#	except FileNotFoundError:
#		print("Place 'run_syn.py' under '../02_SYN'")

def modify(path,clk=0):
	clk_mod_fail = True
	content = []
	file = open(path, 'r+')
	content = file.readlines()
	#print(content)
	for idx,line in enumerate(content):
		if line.startswith("set CYCLE"):
			content[idx] = "set CYCLE "+str(clk)+"\n"
			clk_mod_fail = False
			break
	newcontent = ""
	for line in content:
		newcontent += line
	file.seek(0)
	file.write(newcontent)
	file.close()
	return clk_mod_fail

def modifyPATTERN(path, clk=0):
	content = []
	file = open(path, 'r+')
	content = file.readlines()
	#print(content)
	for idx,line in enumerate(content):
		if line.startswith("`define CYCLE_TIME"):
			content[idx] = "`define CYCLE_TIME "+str(clk)+"\n"
	newcontent = ""
	for line in content:
		newcontent += line
	file.seek(0)
	file.write(newcontent)
	file.close()

def record_area(module,clk):
	area = ""

	file_timing = open("./Report/"+module+".timing",'r')
	content = file_timing.readlines()
	#print(content)
	met = False
	for idx,line in enumerate(content):
		line = line.strip(' ')
		if line.startswith("slack"):
			if "MET" in line:
				met = True
			slack = line.split(' ')[-1].strip('\n')
			area += str(slack)+","
			break
	file_timing.close()

	file_area = open("./Report/"+module+".area",'r')
	content = file_area.readlines()
	#print(content)
	for idx,line in enumerate(content):
		if line.startswith("Total cell area"):
			area += str(clk)+","+line.split(' ')[-1]
			break
	file_area.close()

	file_record = open('area.csv','a')
	file_record.write(area)
	file_record.close()
	print("\n\nArea saved in area.csv\n\n")
	return met

if __name__ == '__main__':
	file_path = os.path.abspath(__file__)
	if not file_path.endswith('02_SYN/run_syn.py'):
		print("Place 'run_syn.py' under '../02_SYN'")
		exit()
	for i in range (iteration):
		if start>end or stride==0:
			clk = start-i*stride
		else:
			clk = end-i*stride
		print("************************************************************************************************************")
		print("                           Synthesize "+module_name+".v with CLK_period =",clk)
		print("************************************************************************************************************\n\n")
		MET = run(clk)
		if not MET:
			print("QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ")
			print("                               Fail to meet timing constraint at "+str(clk))
			print("QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ")
			break
		