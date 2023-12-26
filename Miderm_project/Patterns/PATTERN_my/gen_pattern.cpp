#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <time.h>
#include <vector>
#include <sstream>
#include <iomanip> 
using namespace std;

// ================================
string dram_file_name = "DRAM.dat";
string in_file_name = "input.txt";
string out_file_name = "output.txt";
string check_file_name = "check.txt";
int pat_num = 10;
// ================================

int col_offset;
int row_offset;
int in_mat[16][16];
int GLCM[32][32];
vector<int> in_mat_val;

void computeGLCM(int in_mat_start_addr, int dir, int des);

int main()
{
    int in_mat_start_addr, out_mat_start_addr;
    int dir, des;
    string line, s;
    ifstream dram_file(dram_file_name);
    ofstream in_file(in_file_name);
    ofstream out_file(out_file_name);
    ofstream check_file(check_file_name);

    while(getline(dram_file, line))
    {
        getline(dram_file, line);
        stringstream ss(line);
        while (getline(ss, s, ' ')) { 
            in_mat_val.push_back(stoul(s, nullptr, 16));
        }
    }

    srand(time(NULL));
    in_file << "pattern_num = " << pat_num << endl << endl;
    for(int i=0; i<pat_num; i++)
    {
        in_mat_start_addr = 0x1000 + rand() % (4096-256);
        out_mat_start_addr = 0x2000 + rand() % (4096-1024);
        dir = rand() % 3 + 1;
        des = rand() % 16;
        computeGLCM(in_mat_start_addr, dir, des);

        in_file << "#" << i << endl;
        in_file << "in_dir = " << dir << endl;
        in_file << "in_des = " << des << endl;
        in_file << "in_addr_M = " << in_mat_start_addr << endl;
        in_file << "in_addr_G = " << out_mat_start_addr << endl;
        in_file << endl;

        out_file << "#" << i << endl;
        for(int i=0; i<32; i++)
        {
            for(int j=0; j<32; j++)
                out_file << GLCM[i][j] << " ";
            out_file << endl;
        }
        out_file << endl;

        check_file << "#" << i;
        check_file << "  offset = ( " << row_offset << " , " << col_offset << " )" << endl << endl;
        check_file << "   |";
        for(int j=0; j<16; j++)
            check_file << setw(4) << j;
        check_file << endl << "--------------------------------------------------------------------" << endl;
        for(int i=0; i<16; i++)
        {
            check_file << setw(2) << i << " |";
            for(int j=0; j<16; j++)
                check_file << setw(4) << in_mat[i][j];
            check_file << endl;
        }
        check_file << endl;
    }

    dram_file.close();
    in_file.close();
    out_file.close();
    check_file.close();
    return 0;
}

void computeGLCM(int in_mat_start_addr, int dir, int des)
{
    int addr = in_mat_start_addr - 0x1000;
    int source, dest;

    for(int i=0; i<16; i++)
        for(int j=0; j<16; j++)
            in_mat[i][j] = in_mat_val[addr+16*i+j];

    for(int i=0; i<32; i++)
        for(int j=0; j<32; j++)
            GLCM[i][j] = 0;

    if(dir == 1) // go down
    {
        row_offset = des;
        col_offset = 0;
    }
    else if(dir == 2) // go right
    {
        row_offset = 0;
        col_offset = des;
    }
    else
    {
        row_offset = des;
        col_offset = des;
    }

    for(int i=0; i<16; i++)
    {
        for(int j=0; j<16; j++)
        {
            source = in_mat[i][j];
            if(i+row_offset < 16 && j+col_offset < 16)
            {
                dest = in_mat[i+row_offset][j+col_offset];
                GLCM[source][dest] += 1;
            }
        }
    }
}