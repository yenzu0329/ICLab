#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <time.h>
using namespace std;

int start_addr = 0x1000;
int end_addr = 0x2000;
int offset = 4;
string dram_file_name = "DRAM.dat";

int main()
{
    srand(time(NULL));
    ofstream out_file(dram_file_name);
    int num;
    for(int i=start_addr; i<end_addr; i+=offset)
    {
        out_file << "@" << hex << i << endl;
        for(int j=0; j<offset; j++)
        {
            num = rand() % 32;
            out_file << num << " ";
        }
        out_file << endl;
    }
    out_file.close();
    return 0;
}