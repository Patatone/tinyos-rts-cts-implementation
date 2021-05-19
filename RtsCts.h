#ifndef RTSCTS_H
#define RTSCTS_H

typedef nx_struct my_msg {
	nx_uint8_t msg_type; 
	nx_uint16_t msg_id;
	nx_uint16_t sender_id;
} my_msg_t;

#define REQ 1
#define RTS 2
#define CTS 3

enum{
	AM_MY_MSG = 6,
};

#endif
