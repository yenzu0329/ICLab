#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <time.h>
#include <iomanip>
using namespace std;

int start_addr = 0x10000;
int end_addr = 0x10800;
string dram_file_name = "dram.dat";

int main()
{
    srand(time(NULL));
    ofstream out_file(dram_file_name);
    int num;
    for(int i=start_addr; i<end_addr; i+=4)
    {
        out_file << "@" << setiosflags(ios::uppercase) << hex << i << endl;
        for(int j=0; j<4; j++)
        {
            num = rand() % 256;
            out_file << setw(2) << setfill('0') << num << " ";
        }
        out_file << endl;
    }
    out_file.close();
    return 0;
}