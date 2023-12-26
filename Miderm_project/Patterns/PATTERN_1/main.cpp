#include <iostream>
#include <fstream>
#include <random>
#include <iomanip>
#include <string>
using namespace std;

#define PATNUM 2000
#define SEED 11
#define FAILPATNUMBER 0 // Write input matrix and golden GLCM matrix of specific number of pattern in fail.txt
#define INPUTFILE "input.txt"
#define OUTPUTFILE "output.txt"
#define PSEUDO_DRAM "pseudo_DRAM.dat"
#define FAILFILE "fail.txt"

string convertDecimalToHex(int);

int main()
{
	ofstream input;
	ofstream dram;
	ofstream output;
	ofstream fail;

	input.open(INPUTFILE);
	dram.open(PSEUDO_DRAM);
	output.open(OUTPUTFILE);
	fail.open(FAILFILE);

	input << PATNUM << endl;
	srand(SEED);

	// initialize DRAM data
	int data[4096];
	for (int i = 0; i < 4096; i++)
	{
		data[i] = rand() % 32; // 0 ~ 31
	}

	// write data into pseudo_DRAM.dat
	for (int i = 0; i < 4096; i = i + 4)
	{
		string str;

		str = convertDecimalToHex(i);
		str[0] = '1';
		dram << "@" << str << endl;

		str = convertDecimalToHex(data[i]);
		dram << str.substr(2, 3) << " ";

		str = convertDecimalToHex(data[i + 1]);
		dram << str.substr(2, 3) << " ";

		str = convertDecimalToHex(data[i + 2]);
		dram << str.substr(2, 3) << " ";

		str = convertDecimalToHex(data[i + 3]);
		dram << str.substr(2, 3) << endl;
	}
	dram.close();
	
	// start to generate input and output
	for (int patcount = 0; patcount < PATNUM; patcount++)
	{
		// generate input
		int in_addr_M = rand() % (4096 - 255) + 4096; // 0x1000 ~ (0x1fff - 'd255)
		int in_addr_G = rand() % (4096 - 1023) + 8192; // 0x2000 ~ (0x2fff - 'd1023)
		int in_dir = rand() % 3 + 1; // 1 ~ 3
		int in_dis = rand() % 15 + 1; // 1 ~ 15

		// write input data into input.txt
		input << convertDecimalToHex(in_addr_M) << endl;
		input << convertDecimalToHex(in_addr_G) << endl;
		input << in_dir << endl;
		input << in_dis << endl;


		// compute the golden answer

		// write data into input_matrix
		int input_matrix[16][16];
		for (int row = 0; row < 16; row++)
		{
			for (int col = 0; col < 16; col++)
			{
				input_matrix[row][col] = data[in_addr_M - 4096 + 16 * row + col];
			}
		}

		// get row_offset & col_offset
		int row_offset;
		int col_offset;
		if (in_dir == 1)
		{
			row_offset = in_dis * 1;
			col_offset = 0;
		}
		else if (in_dir == 2)
		{
			row_offset = 0;
			col_offset = in_dis * 1;
		}
		else if (in_dir == 3)
		{
			row_offset = in_dis * 1;
			col_offset = in_dis * 1;
		}

		// implement the algorithm of GLCM
		int GLCM_matrix[32][32];
		for (int ref = 0; ref < 32; ref++)
		{
			for (int c = 0; c < 32; c++)
			{
				int value = 0;
				for (int row = 0; row < 16 - row_offset; row++)
				{
					for (int col = 0; col < 16 - col_offset; col++)
					{
						if (input_matrix[row][col] == ref && input_matrix[row + row_offset][col + col_offset] == c)
							value++;
					}
				}
				GLCM_matrix[ref][c] = value;
			}
		}

		// write GLCM_matrix into output.txt
		for (int ref = 0; ref < 32; ref++)
		{
			for (int c = 0; c < 32; c++)
			{
				output << setw(4) << GLCM_matrix[ref][c];
			}
			output << endl;
		}

		// print input matrix and GLCM matrix on console
		if (patcount == FAILPATNUMBER)
		{
			fail << "==========================================" << endl;
			fail << "                  inputs                  " << endl;
			fail << "==========================================" << endl;
			fail << "in_addr_M = " << convertDecimalToHex(in_addr_M) << " (in hex format)" << endl;
			fail << "in_addr_G = " << convertDecimalToHex(in_addr_G) << " (in hex format)" << endl;
			fail << "in_dir = " << in_dir << " (in decimal format)" << endl;
			fail << "in_dis = " << in_dis << " (in decimal format)" << endl << endl;

			fail << "=================================================" << endl;
			fail << "        input matrix (in decimal format)         " << endl;
			fail << "=================================================" << endl;
			for (int row = 0; row < 16; row++)
			{
				for (int col = 0; col < 16; col++)
				{
					fail << setw(3) << input_matrix[row][col];
				}
				fail << endl;
			}
			fail << endl;

			fail << "========================================================================================================================================================================" << endl;
			fail << "                                                                    GLCM matrix (in decimal format)                                                                     " << endl;
			fail << "========================================================================================================================================================================" << endl;
			fail << setw(11);
			for (int c = 0; c < 32; c++)
			{
				fail << " C." << setw(2) << c;
			}
			fail << endl;
			for (int ref = 0; ref < 32; ref++)
			{
				fail << "Ref." << setw(2) << ref;
				for (int c = 0; c < 32; c++)
				{
					fail << setw(5) << GLCM_matrix[ref][c];
				}
				fail << endl;
			}
		}
	}

	input.close();
	output.close();
	fail.close();

	return 0;
}

string convertDecimalToHex(int in)
{
	string s;
	int quotient;
	int remainder;

	quotient = in / 4096;
	remainder = in % 4096;
	switch (quotient)
	{
	case 10:
		s += 'a';
		break;
	case 11:
		s += 'b';
		break;
	case 12:
		s += 'c';
		break;
	case 13:
		s += 'd';
		break;
	case 14:
		s += 'e';
		break;
	case 15:
		s += 'f';
		break;
	default:
		s += to_string(quotient);
		break;
	}

	quotient = remainder / 256;
	remainder = remainder % 256;
	switch (quotient)
	{
	case 10:
		s += 'a';
		break;
	case 11:
		s += 'b';
		break;
	case 12:
		s += 'c';
		break;
	case 13:
		s += 'd';
		break;
	case 14:
		s += 'e';
		break;
	case 15:
		s += 'f';
		break;
	default:
		s += to_string(quotient);
		break;
	}

	quotient = remainder / 16;
	remainder = remainder % 16;
	switch (quotient)
	{
	case 10:
		s += 'a';
		break;
	case 11:
		s += 'b';
		break;
	case 12:
		s += 'c';
		break;
	case 13:
		s += 'd';
		break;
	case 14:
		s += 'e';
		break;
	case 15:
		s += 'f';
		break;
	default:
		s += to_string(quotient);
		break;
	}

	switch (remainder)
	{
	case 10:
		s += 'a';
		break;
	case 11:
		s += 'b';
		break;
	case 12:
		s += 'c';
		break;
	case 13:
		s += 'd';
		break;
	case 14:
		s += 'e';
		break;
	case 15:
		s += 'f';
		break;
	default:
		s += to_string(remainder);
		break;
	}

	return s;
}