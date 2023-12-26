#include <iostream>
#include <fstream>
#include <random>
using namespace std;

#define PATNUM 1000
#define SAME 0		// 0: test data of point addition; 1: test data of point doubling 
#define SEED 456
#define INPUTFILE "input.txt"
#define OUTPUTFILE "output.txt"

int getPrime(int);
int getInverse(int, int);

int main()
{
	ofstream input;
	ofstream output;
	input.open(INPUTFILE);
	output.open(OUTPUTFILE);
	input << PATNUM << endl;
	srand(SEED);

	for (int patcount = 0; patcount < PATNUM; patcount++)
	{
		// generate input data
		int prime_idx = rand() % 16;
		int prime = getPrime(prime_idx);
		int xp, yp, xq, yq, a;
		if (SAME)
		{
			xp = rand() % prime;
			yp = 1 + (rand() % (prime - 1));
			xq = xp;
			yq = yp;
		}
		else
		{
			xp = rand() % prime;
			yp = rand() % prime;
			xq = rand() % prime;
			while (xq == xp)
				xq = rand() % prime;
			yq = rand() % prime;
		}
		a = rand() % prime;

		// wrtie input data
		input << xp << " " << yp << " " << xq << " " << yq << " " << prime << " " << a << endl;

		// get golden answer
		int s;
		int num, den;
		int inverse;
		if (SAME)
		{
			num = (3 * xp * xp + a) % prime;
			den = (2 * yp) % prime;
		}
		else
		{
			num = yq - yp;
			if (num < 0)
				num += prime;

			den = xq - xp;

			if (den < 0)
				den += prime;
		}
		inverse = getInverse(den, prime);
		s = (inverse * num) % prime;

		int xr, yr;
		int sum;
		sum = s * s - xp - xq;
		while (sum < 0)
			sum += prime;

		xr = sum % prime;

		sum = s * (xp - xr) - yp;
		while (sum < 0)
			sum += prime;

		yr = sum % prime;

		// write output data
		output << xr << " " << yr << endl;
	}

	input.close();
	output.close();
	return 0;

}

int getPrime(int prime_idx)
{
	switch (prime_idx)
	{
	case 0:	return 5;
	case 1:	return 7;
	case 2:	return 11;
	case 3:	return 13;
	case 4:	return 17;
	case 5:	return 19;
	case 6:	return 23;
	case 7:	return 29;
	case 8:	return 31;
	case 9:	return 37;
	case 10:return 41;
	case 11:return 43;
	case 12:return 47;
	case 13:return 53;
	case 14:return 59;
	case 15:return 61;
	}
}

int getInverse(int den, int prime)
{	
	int inverse = 1;
	while ((inverse * den) % prime != 1)
	{
		inverse++;
	}

	return inverse;
}
