/*
 * APSRack.h
 *
 *  Created on: Jun 13, 2012
 *      Author: cryan
 */

#ifndef APSRACK_H_
#define APSRACK_H_

#include "headings.h"

class APS;

class APSRack {
public:
	APSRack();
	~APSRack();

	map<string, int> serial2dev;

	int init();
	int connect(const int &);
	int connect(const string &);
	int disconnect(const int &);
	int disconnect(const string &);

	int get_num_devices();
	void enumerate_devices();

	int program_FPGA(const int &, const string &, const int &, const int &);

	int get_sampleRate(const int &, const int &);
	int set_sampleRate(const int &, const int &, const int &, const bool &);

private:
	int _numDevices;
	vector<APS> _APSs;
	vector<string> _deviceSerials;
};

#endif /* APSRACK_H_ */
